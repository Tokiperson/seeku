import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../domain/ai_models.dart';
import 'ai_credential_resolver.dart';
import 'schedule_ai_prompt.dart';

class MoonshotApiClient {
  static const _connectionTimeout = Duration(seconds: 15);
  static const _responseTimeout = Duration(seconds: 120);

  MoonshotApiClient({
    this.config = const AiProviderConfig(
      providerName: 'Moonshot Kimi',
      baseUrl: 'https://api.moonshot.cn/v1',
      model: 'kimi-k2.6',
    ),
    Future<String> Function()? apiKeyProvider,
  }) : _apiKeyProvider = apiKeyProvider;

  final AiProviderConfig config;
  final Future<String> Function()? _apiKeyProvider;

  Future<String> parseSchedulePdf(String path) async {
    final extractedText = await extractFileText(path);
    if (extractedText.trim().isEmpty) {
      throw const FormatException('PDF 未抽取到文本内容');
    }
    return chatJson(
      messages: [
        {'role': 'system', 'content': ScheduleAiPrompt.system},
        {
          'role': 'user',
          'content': '${ScheduleAiPrompt.textUser}\n\n$extractedText',
        },
      ],
    );
  }

  Future<String> parseScheduleImage(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final dataUrl = 'data:${_mimeType(path)};base64,${base64Encode(bytes)}';
    return chatJson(
      messages: [
        {'role': 'system', 'content': ScheduleAiPrompt.system},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
            {'type': 'text', 'text': ScheduleAiPrompt.imageUser},
          ],
        },
      ],
    );
  }

  Future<void> testConnection() async {
    await _send(method: 'GET', path: '/models', contentType: null);
  }

  Future<String> extractFileText(String path) async {
    final fileId = await uploadFile(path: path, purpose: 'file-extract');
    final response = await _send(
      method: 'GET',
      path: '/files/$fileId/content',
      contentType: null,
    );
    return response.body;
  }

  Future<String> uploadFile({
    required String path,
    required String purpose,
  }) async {
    final file = File(path);
    final fileName = p.basename(path);
    final boundary =
        'seeku-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final bytes = await file.readAsBytes();
    final prefix = utf8.encode(
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="purpose"\r\n\r\n'
      '$purpose\r\n'
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'
      'Content-Type: ${_mimeType(path)}\r\n\r\n',
    );
    final suffix = utf8.encode('\r\n--$boundary--\r\n');
    final response = await _send(
      method: 'POST',
      path: '/files',
      contentType: 'multipart/form-data; boundary=$boundary',
      bodyParts: [prefix, bytes, suffix],
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['id'] is! String) {
      throw const FormatException('文件上传响应缺少 file id');
    }
    return decoded['id'] as String;
  }

  Future<String> chatJson({
    required List<Map<String, Object?>> messages,
  }) async {
    final response = await _send(
      method: 'POST',
      path: '/chat/completions',
      contentType: 'application/json',
      bodyText: jsonEncode({
        'model': config.model,
        'messages': messages,
        'response_format': {'type': 'json_object'},
        'max_completion_tokens': 8192,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('AI 响应不是 JSON Object');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('AI 响应缺少 choices');
    }
    final first = choices.first;
    if (first is! Map) {
      throw const FormatException('AI 响应 choice 格式不合法');
    }
    final message = first['message'];
    if (message is! Map || message['content'] is! String) {
      throw const FormatException('AI 响应缺少 message.content');
    }
    return message['content'] as String;
  }

  Future<_MoonshotHttpResponse> _send({
    required String method,
    required String path,
    required String? contentType,
    String? bodyText,
    List<List<int>>? bodyParts,
  }) async {
    final apiKey =
        await (_apiKeyProvider ?? const AiCredentialResolver().resolveApiKey)();
    final client = HttpClient()..connectionTimeout = _connectionTimeout;
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('${_baseUrl()}$path'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      if (contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      if (bodyText != null) {
        request.add(utf8.encode(bodyText));
      }
      if (bodyParts != null) {
        for (final part in bodyParts) {
          request.add(part);
        }
      }
      final response = await request.close().timeout(_responseTimeout);
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_responseTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Moonshot API 请求失败：HTTP ${response.statusCode} $body',
          uri: Uri.parse('${_baseUrl()}$path'),
        );
      }
      return _MoonshotHttpResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  String _baseUrl() => config.baseUrl.endsWith('/')
      ? config.baseUrl.substring(0, config.baseUrl.length - 1)
      : config.baseUrl;

  String _mimeType(String path) {
    return switch (p.extension(path).toLowerCase()) {
      '.pdf' => 'application/pdf',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }
}

class _MoonshotHttpResponse {
  const _MoonshotHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
