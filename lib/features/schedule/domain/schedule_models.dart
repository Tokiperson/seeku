class Semester {
  const Semester({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.termIndex,
    required this.startsOn,
    required this.isCurrent,
  });

  final int id;
  final String name;
  final String academicYear;
  final int termIndex;
  final DateTime startsOn;
  final bool isCurrent;

  Semester copyWith({
    int? id,
    String? name,
    String? academicYear,
    int? termIndex,
    DateTime? startsOn,
    bool? isCurrent,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      termIndex: termIndex ?? this.termIndex,
      startsOn: startsOn ?? this.startsOn,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

class Course {
  const Course({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    this.category,
    this.teacher,
    this.note,
    required this.source,
  });

  final int id;
  final int semesterId;
  final String name;
  final String? code;
  final String? category;
  final String? teacher;
  final String? note;
  final String source;

  Course copyWith({
    int? id,
    int? semesterId,
    String? name,
    String? code,
    String? category,
    String? teacher,
    String? note,
    String? source,
  }) {
    return Course(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      teacher: teacher ?? this.teacher,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }
}

class CourseOccurrence {
  const CourseOccurrence({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    this.classroom,
    this.campus,
    required this.weekExpression,
    required this.parsedWeeks,
  });

  final int id;
  final int courseId;
  final int weekday;
  final int startSection;
  final int endSection;
  final String? classroom;
  final String? campus;
  final String weekExpression;
  final List<int> parsedWeeks;

  CourseOccurrence copyWith({
    int? id,
    int? courseId,
    int? weekday,
    int? startSection,
    int? endSection,
    String? classroom,
    String? campus,
    String? weekExpression,
    List<int>? parsedWeeks,
  }) {
    return CourseOccurrence(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      classroom: classroom ?? this.classroom,
      campus: campus ?? this.campus,
      weekExpression: weekExpression ?? this.weekExpression,
      parsedWeeks: parsedWeeks ?? this.parsedWeeks,
    );
  }
}

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.section,
    required this.startTime,
    required this.endTime,
    required this.profileName,
  });

  final int id;
  final int section;
  final String startTime;
  final String endTime;
  final String profileName;

  TimeSlot copyWith({
    int? id,
    int? section,
    String? startTime,
    String? endTime,
    String? profileName,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      profileName: profileName ?? this.profileName,
    );
  }
}

class CourseEntry {
  const CourseEntry({required this.course, required this.occurrence});

  final Course course;
  final CourseOccurrence occurrence;

  bool occursInWeek(int week) => occurrence.parsedWeeks.contains(week);
}
