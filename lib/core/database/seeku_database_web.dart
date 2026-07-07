import '../../features/import/domain/import_models.dart';
import '../../features/schedule/domain/schedule_models.dart';

class SeekuDatabase {
  SeekuDatabase._();

  factory SeekuDatabase.open() => SeekuDatabase._();

  factory SeekuDatabase.memory() => SeekuDatabase._();

  bool _initialized = false;
  int _semesterId = 0;
  int _courseId = 0;
  int _occurrenceId = 0;
  int _batchId = 0;
  final List<Semester> _semesters = [];
  final List<TimeSlot> _timeSlots = [];
  final List<CourseEntry> _entries = [];
  final List<ImportBatch> _batches = [];

  Future<void> close() async {}

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  Future<void> seedDefaults() async {
    await ensureInitialized();
    if (_semesters.isEmpty) {
      await insertSemester(
        Semester(
          id: 0,
          name: '2025-2026 第二学期',
          academicYear: '2025-2026',
          termIndex: 2,
          startsOn: DateTime(2026, 2, 23),
          endsOn: DateTime(2026, 7, 12),
          isCurrent: true,
        ),
      );
    }
    if (_timeSlots.isEmpty) {
      _timeSlots.addAll(defaultCquTimeSlots);
    }
    if (_entries.isEmpty) {
      await _seedPreviewCourses(_semesters.first.id);
    }
  }

  Future<List<Semester>> getSemesters() async {
    await seedDefaults();
    return List.unmodifiable(_semesters);
  }

  Future<Semester?> getCurrentSemester() async {
    await seedDefaults();
    if (_semesters.isEmpty) {
      return null;
    }
    return _semesters.firstWhere(
      (semester) => semester.isCurrent,
      orElse: () => _semesters.first,
    );
  }

  Future<int> insertSemester(Semester semester) async {
    await ensureInitialized();
    if (semester.isCurrent) {
      for (var index = 0; index < _semesters.length; index++) {
        _semesters[index] = _semesters[index].copyWith(isCurrent: false);
      }
    }
    final stored = semester.copyWith(id: ++_semesterId);
    _semesters.add(stored);
    _semesters.sort((a, b) => b.startsOn.compareTo(a.startsOn));
    return stored.id;
  }

  Future<void> updateSemester(Semester semester) async {
    await ensureInitialized();
    if (semester.isCurrent) {
      for (var index = 0; index < _semesters.length; index++) {
        _semesters[index] = _semesters[index].copyWith(isCurrent: false);
      }
    }
    final index = _semesters.indexWhere((item) => item.id == semester.id);
    if (index >= 0) {
      _semesters[index] = semester;
    }
  }

  Future<void> setCurrentSemester(int semesterId) async {
    await ensureInitialized();
    for (var index = 0; index < _semesters.length; index++) {
      final semester = _semesters[index];
      _semesters[index] = semester.copyWith(
        isCurrent: semester.id == semesterId,
      );
    }
  }

  Future<void> deleteSemester(int semesterId) async {
    await ensureInitialized();
    final index = _semesters.indexWhere((item) => item.id == semesterId);
    if (index < 0) {
      return;
    }
    final semester = _semesters[index];
    _semesters.removeWhere((item) => item.id == semesterId);
    _entries.removeWhere((entry) => entry.course.semesterId == semesterId);
    if (semester.isCurrent && _semesters.isNotEmpty) {
      _semesters.sort((a, b) => b.startsOn.compareTo(a.startsOn));
      _semesters[0] = _semesters[0].copyWith(isCurrent: true);
    }
  }

  Future<List<TimeSlot>> getTimeSlots() async {
    await seedDefaults();
    return List.unmodifiable(_timeSlots);
  }

  Future<void> upsertTimeSlot(TimeSlot slot) async {
    await ensureInitialized();
    final index = _timeSlots.indexWhere((item) => item.id == slot.id);
    if (index >= 0) {
      _timeSlots[index] = slot;
    } else {
      _timeSlots.add(slot);
      _timeSlots.sort((a, b) => a.section.compareTo(b.section));
    }
  }

  Future<List<CourseEntry>> getEntriesForSemester(int semesterId) async {
    await seedDefaults();
    return _entries
        .where((entry) => entry.course.semesterId == semesterId)
        .toList(growable: false);
  }

  Future<CourseEntry?> getEntryByCourseId(int courseId) async {
    await seedDefaults();
    for (final entry in _entries) {
      if (entry.course.id == courseId) {
        return entry;
      }
    }
    return null;
  }

  Future<int> insertCourseWithOccurrence(CourseDraft draft) async {
    await ensureInitialized();
    final courseId = ++_courseId;
    final course = Course(
      id: courseId,
      semesterId: draft.semesterId,
      name: draft.name,
      code: draft.code,
      category: draft.category,
      teacher: draft.teacher,
      note: draft.note,
      source: draft.source,
    );
    final occurrence = CourseOccurrence(
      id: ++_occurrenceId,
      courseId: courseId,
      weekday: draft.weekday,
      startSection: draft.startSection,
      endSection: draft.endSection,
      classroom: draft.classroom,
      campus: draft.campus,
      weekExpression: draft.weekExpression,
      parsedWeeks: draft.parsedWeeks,
    );
    _entries.add(CourseEntry(course: course, occurrence: occurrence));
    _entries.sort(_compareEntry);
    return courseId;
  }

  Future<void> updateCourseWithOccurrence(
    int courseId,
    CourseDraft draft,
  ) async {
    final index = _entries.indexWhere((entry) => entry.course.id == courseId);
    if (index < 0) {
      return;
    }
    final current = _entries[index];
    _entries[index] = CourseEntry(
      course: current.course.copyWith(
        semesterId: draft.semesterId,
        name: draft.name,
        code: draft.code,
        category: draft.category,
        teacher: draft.teacher,
        note: draft.note,
        source: draft.source,
      ),
      occurrence: current.occurrence.copyWith(
        weekday: draft.weekday,
        startSection: draft.startSection,
        endSection: draft.endSection,
        classroom: draft.classroom,
        campus: draft.campus,
        weekExpression: draft.weekExpression,
        parsedWeeks: draft.parsedWeeks,
      ),
    );
    _entries.sort(_compareEntry);
  }

  Future<void> deleteCourse(int courseId) async {
    _entries.removeWhere((entry) => entry.course.id == courseId);
  }

  Future<int> insertImportBatch({
    required String sourceType,
    required DateTime importedAt,
    String? rawSnapshotPath,
    required String status,
  }) async {
    final batch = ImportBatch(
      id: ++_batchId,
      sourceType: sourceType,
      importedAt: importedAt,
      rawSnapshotPath: rawSnapshotPath,
      status: status,
    );
    _batches.insert(0, batch);
    return batch.id;
  }

  Future<void> updateImportBatchStatus(int batchId, String status) async {
    final index = _batches.indexWhere((batch) => batch.id == batchId);
    if (index >= 0) {
      _batches[index] = _batches[index].copyWith(status: status);
    }
  }

  Future<List<ImportBatch>> getImportBatches() async {
    return List.unmodifiable(_batches);
  }

  Future<void> _seedPreviewCourses(int semesterId) async {
    final samples = <CourseDraft>[
      CourseDraft(
        semesterId: semesterId,
        name: '计算机组成与结构',
        teacher: '示例教师',
        classroom: 'D1344',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weekExpression: '[1-16周]',
        parsedWeeks: List<int>.generate(16, (index) => index + 1),
        source: 'webPreview',
      ),
      CourseDraft(
        semesterId: semesterId,
        name: '数据库系统',
        classroom: 'A5201',
        weekday: 3,
        startSection: 5,
        endSection: 6,
        weekExpression: '[1-16周]',
        parsedWeeks: List<int>.generate(16, (index) => index + 1),
        source: 'webPreview',
      ),
      CourseDraft(
        semesterId: semesterId,
        name: '计算机网络',
        classroom: 'D1137',
        weekday: 5,
        startSection: 10,
        endSection: 13,
        weekExpression: '[1-12周]',
        parsedWeeks: List<int>.generate(12, (index) => index + 1),
        source: 'webPreview',
      ),
    ];
    for (final draft in samples) {
      await insertCourseWithOccurrence(draft);
    }
  }

  int _compareEntry(CourseEntry a, CourseEntry b) {
    final weekday = a.occurrence.weekday.compareTo(b.occurrence.weekday);
    if (weekday != 0) {
      return weekday;
    }
    return a.occurrence.startSection.compareTo(b.occurrence.startSection);
  }
}

const defaultCquTimeSlots = <TimeSlot>[
  TimeSlot(
    id: 1,
    section: 1,
    startTime: '08:00',
    endTime: '08:45',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 2,
    section: 2,
    startTime: '08:55',
    endTime: '09:40',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 3,
    section: 3,
    startTime: '10:10',
    endTime: '10:55',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 4,
    section: 4,
    startTime: '11:05',
    endTime: '11:50',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 5,
    section: 5,
    startTime: '14:00',
    endTime: '14:45',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 6,
    section: 6,
    startTime: '14:55',
    endTime: '15:40',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 7,
    section: 7,
    startTime: '16:10',
    endTime: '16:55',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 8,
    section: 8,
    startTime: '17:05',
    endTime: '17:50',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 9,
    section: 9,
    startTime: '19:00',
    endTime: '19:45',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 10,
    section: 10,
    startTime: '19:55',
    endTime: '20:40',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 11,
    section: 11,
    startTime: '20:50',
    endTime: '21:35',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 12,
    section: 12,
    startTime: '21:45',
    endTime: '22:30',
    profileName: 'CQU 默认',
  ),
  TimeSlot(
    id: 13,
    section: 13,
    startTime: '22:40',
    endTime: '23:25',
    profileName: 'CQU 默认',
  ),
];
