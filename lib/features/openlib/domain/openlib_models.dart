import '../../schedule/domain/schedule_models.dart';

class ResourceSearchQuery {
  const ResourceSearchQuery({
    required this.courseName,
    this.courseCode,
    this.teacher,
    this.keywords = const [],
  });

  final String courseName;
  final String? courseCode;
  final String? teacher;
  final List<String> keywords;

  factory ResourceSearchQuery.fromCourse(Course course) {
    return ResourceSearchQuery(
      courseName: course.name,
      courseCode: course.code,
      teacher: course.teacher,
      keywords: [course.name, if (course.category != null) course.category!],
    );
  }
}

class LearningResource {
  const LearningResource({
    required this.id,
    required this.title,
    required this.url,
    required this.summary,
    required this.matchScore,
    this.source = 'CQU-Openlib',
  });

  final String id;
  final String title;
  final Uri url;
  final String summary;
  final double matchScore;
  final String source;
}

class OpenlibResourceCache {
  const OpenlibResourceCache({
    required this.queryKey,
    required this.cachedAt,
    required this.payload,
  });

  final String queryKey;
  final DateTime cachedAt;
  final String payload;
}

abstract class OpenlibResourceProvider {
  const OpenlibResourceProvider();

  Future<List<LearningResource>> search(ResourceSearchQuery query);
}
