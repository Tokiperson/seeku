import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/database/seeku_database.dart';
import '../domain/openlib_models.dart';

class CquOpenlibResourceProvider extends OpenlibResourceProvider {
  const CquOpenlibResourceProvider({
    required SeekuDatabase database,
    this.cacheMaxAge = const Duration(days: 7),
    Future<String> Function(Uri uri)? fetchText,
    DateTime Function()? now,
  }) : _database = database,
       _fetchText = fetchText,
       _now = now;

  static final Uri _baseUri = Uri.parse('https://cqu-openlib.cn/');
  static final Uri _searchIndexUri = _baseUri.resolve(
    'search/search_index.json',
  );
  static const _requestTimeout = Duration(seconds: 30);

  final SeekuDatabase _database;
  final Duration cacheMaxAge;
  final Future<String> Function(Uri uri)? _fetchText;
  final DateTime Function()? _now;

  @override
  Future<List<LearningResource>> search(ResourceSearchQuery query) async {
    final queryKey = _queryKey(query);
    if (queryKey.isEmpty) {
      return const [];
    }

    final now = _now?.call() ?? DateTime.now();
    final cached = await _database.getOpenlibResourceCache(queryKey);
    if (cached != null && now.difference(cached.cachedAt) <= cacheMaxAge) {
      return _decodeResources(cached.payload);
    }

    final List<LearningResource> resources;
    try {
      final indexText = await (_fetchText ?? _defaultFetchText)(
        _searchIndexUri,
      );
      resources = _parseSearchIndex(indexText, query);
    } catch (_) {
      if (cached != null) {
        return _decodeResources(cached.payload);
      }
      return const [];
    }

    await _database.upsertOpenlibResourceCache(
      queryKey: queryKey,
      cachedAt: now,
      payload: _encodeResources(resources),
    );
    return resources;
  }

  List<LearningResource> _parseSearchIndex(
    String indexText,
    ResourceSearchQuery query,
  ) {
    final decoded = jsonDecode(indexText);
    if (decoded is! Map || decoded['docs'] is! List) {
      throw const FormatException('Openlib 搜索索引格式不合法');
    }

    final queryNorm = _normalizeCourseName(query.courseName);
    final relaxedQueryNorm = _normalizeCourseName(
      _stripCourseSuffix(query.courseName),
    );
    final courseCode = query.courseCode?.trim().toLowerCase();
    final keywords = query.keywords
        .map(_normalizeCourseName)
        .where((item) => item.isNotEmpty)
        .toSet();
    final byId = <String, LearningResource>{};

    for (final item in decoded['docs'] as List) {
      if (item is! Map) {
        continue;
      }
      final title = (item['title'] as String?)?.trim() ?? '';
      final location = (item['location'] as String?)?.trim() ?? '';
      final text = (item['text'] as String?)?.trim() ?? '';
      if (title.isEmpty || location.isEmpty || !_isCourseLocation(location)) {
        continue;
      }

      final decodedLocation = _safeDecode(location);
      final titleNorm = _normalizeCourseName(title);
      final locationNorm = _normalizeCourseName(decodedLocation);
      final textNorm = _normalizeCourseName(text);
      var score = _score(
        queryNorm: queryNorm,
        relaxedQueryNorm: relaxedQueryNorm,
        titleNorm: titleNorm,
        locationNorm: locationNorm,
        textNorm: textNorm,
        courseCode: courseCode,
        keywords: keywords,
      );
      final rawQuery = query.courseName.trim().toLowerCase();
      final rawTitle = title.trim().toLowerCase();
      if (score < 0.45 &&
          rawQuery.isNotEmpty &&
          (rawTitle == rawQuery ||
              rawTitle.contains(rawQuery) ||
              rawQuery.contains(rawTitle))) {
        score = 0.9;
      }
      if (score < 0.45) {
        continue;
      }

      final url = _resourceUri(location);
      final resource = LearningResource(
        id: url.toString(),
        title: title,
        url: url,
        summary: _summary(text),
        matchScore: score,
      );
      final previous = byId[resource.id];
      if (previous == null || previous.matchScore < resource.matchScore) {
        byId[resource.id] = resource;
      }
    }

    final resources = byId.values.toList()
      ..sort((a, b) {
        final score = b.matchScore.compareTo(a.matchScore);
        if (score != 0) {
          return score;
        }
        return a.title.length.compareTo(b.title.length);
      });
    return resources.take(8).toList(growable: false);
  }

  double _score({
    required String queryNorm,
    required String relaxedQueryNorm,
    required String titleNorm,
    required String locationNorm,
    required String textNorm,
    required String? courseCode,
    required Set<String> keywords,
  }) {
    var score = 0.0;
    if (titleNorm == queryNorm) {
      score = 1.0;
    } else if (titleNorm == relaxedQueryNorm && relaxedQueryNorm.isNotEmpty) {
      score = 0.94;
    } else if (titleNorm.contains(queryNorm) || queryNorm.contains(titleNorm)) {
      score = 0.82;
    } else if (locationNorm.contains(queryNorm)) {
      score = 0.78;
    } else if (textNorm.contains(queryNorm)) {
      score = 0.55;
    }

    if (relaxedQueryNorm.isNotEmpty && relaxedQueryNorm != queryNorm) {
      if (titleNorm.contains(relaxedQueryNorm) ||
          locationNorm.contains(relaxedQueryNorm)) {
        score = score < 0.72 ? 0.72 : score;
      }
    }

    if (courseCode != null && courseCode.isNotEmpty) {
      final codeHit =
          titleNorm.contains(courseCode) ||
          locationNorm.contains(courseCode) ||
          textNorm.contains(courseCode);
      if (codeHit) {
        score += 0.08;
      }
    }

    for (final keyword in keywords) {
      if (keyword == queryNorm || keyword.isEmpty) {
        continue;
      }
      if (titleNorm.contains(keyword) || locationNorm.contains(keyword)) {
        score += 0.04;
      }
    }

    return score.clamp(0, 1).toDouble();
  }

  bool _isCourseLocation(String location) {
    final decoded = _safeDecode(location);
    return decoded.startsWith('course/') ||
        decoded.startsWith('/course/') ||
        decoded.contains('/course/');
  }

  Uri _resourceUri(String location) {
    if (location.startsWith('http://') || location.startsWith('https://')) {
      return Uri.parse(Uri.encodeFull(location));
    }
    final relative = location.startsWith('/')
        ? location.substring(1)
        : location;
    return _baseUri.resolve(Uri.encodeFull(relative));
  }

  String _safeDecode(String value) {
    try {
      return Uri.decodeFull(value);
    } catch (_) {
      return value;
    }
  }

  String _summary(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return 'Openlib 课程资源页面';
    }
    if (compact.length <= 120) {
      return compact;
    }
    return '${compact.substring(0, 120)}...';
  }

  String _queryKey(ResourceSearchQuery query) {
    final parts = [
      _normalizeCourseName(query.courseName),
      if (query.courseCode != null) query.courseCode!.trim().toLowerCase(),
      if (query.teacher != null) query.teacher!.trim().toLowerCase(),
    ].where((item) => item.isNotEmpty).toList();
    return parts.join('|');
  }

  String _normalizeCourseName(String value) {
    return _stripCourseSuffix(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_（）()【】\[\]《》<>:：,，.。/\\]'), '')
        .trim();
  }

  String _stripCourseSuffix(String value) {
    return value
        .replaceAll(RegExp(r'（[^）]*）'), '')
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'(课程设计|实验|实践)$'), '')
        .trim();
  }

  String _encodeResources(List<LearningResource> resources) {
    return jsonEncode([
      for (final resource in resources)
        {
          'id': resource.id,
          'title': resource.title,
          'url': resource.url.toString(),
          'summary': resource.summary,
          'matchScore': resource.matchScore,
          'source': resource.source,
        },
    ]);
  }

  List<LearningResource> _decodeResources(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) {
          return LearningResource(
            id: item['id'] as String? ?? '',
            title: item['title'] as String? ?? 'Openlib 资源',
            url: Uri.tryParse(item['url'] as String? ?? '') ?? _baseUri,
            summary: item['summary'] as String? ?? 'Openlib 课程资源页面',
            matchScore: (item['matchScore'] as num?)?.toDouble() ?? 0,
            source: item['source'] as String? ?? 'CQU-Openlib',
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<String> _defaultFetchText(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      final response = await request.close().timeout(_requestTimeout);
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Openlib 请求失败：HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }
}
