import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/import/domain/import_models.dart';
import '../../features/schedule/domain/schedule_models.dart';

class SeekuDatabase extends GeneratedDatabase {
  SeekuDatabase(super.executor);

  factory SeekuDatabase.open() {
    return SeekuDatabase(
      LazyDatabase(() async {
        final directory = await getApplicationSupportDirectory();
        final dbFile = File(p.join(directory.path, 'seeku_v0_1_alpha.sqlite'));
        return NativeDatabase.createInBackground(dbFile);
      }),
    );
  }

  factory SeekuDatabase.memory() => SeekuDatabase(NativeDatabase.memory());

  Future<void>? _initialization;

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  Future<void> ensureInitialized() {
    return _initialization ??= _createSchema();
  }

  Future<void> _createSchema() async {
    await customStatement('PRAGMA foreign_keys = ON');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS semesters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        term_index INTEGER NOT NULL,
        starts_on TEXT NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_id INTEGER NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        code TEXT,
        category TEXT,
        teacher TEXT,
        note TEXT,
        source TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS course_occurrences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        weekday INTEGER NOT NULL,
        start_section INTEGER NOT NULL,
        end_section INTEGER NOT NULL,
        classroom TEXT,
        campus TEXT,
        week_expression TEXT NOT NULL,
        parsed_weeks TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS time_slots (
        id INTEGER PRIMARY KEY,
        section INTEGER NOT NULL UNIQUE,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        profile_name TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS import_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_type TEXT NOT NULL,
        imported_at TEXT NOT NULL,
        raw_snapshot_path TEXT,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<void> seedDefaults() async {
    await ensureInitialized();
    if (await _count('semesters') == 0) {
      await insertSemester(
        Semester(
          id: 0,
          name: '2025-2026 第二学期',
          academicYear: '2025-2026',
          termIndex: 2,
          startsOn: DateTime(2026, 2, 23),
          isCurrent: true,
        ),
      );
    }
    if (await _count('time_slots') == 0) {
      for (final slot in defaultCquTimeSlots) {
        await upsertTimeSlot(slot);
      }
    }
  }

  Future<int> _count(String tableName) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM $tableName',
    ).getSingle();
    return row.read<int>('count');
  }

  Future<List<Semester>> getSemesters() async {
    await ensureInitialized();
    final rows = await customSelect(
      'SELECT * FROM semesters ORDER BY starts_on DESC, id DESC',
    ).get();
    return rows.map(_semesterFromRow).toList();
  }

  Future<Semester?> getCurrentSemester() async {
    await ensureInitialized();
    final rows = await customSelect(
      'SELECT * FROM semesters ORDER BY is_current DESC, starts_on DESC, id DESC LIMIT 1',
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _semesterFromRow(rows.first);
  }

  Future<int> insertSemester(Semester semester) async {
    await ensureInitialized();
    if (semester.isCurrent) {
      await customStatement('UPDATE semesters SET is_current = 0');
    }
    await customStatement(
      'INSERT INTO semesters (name, academic_year, term_index, starts_on, is_current) VALUES (?, ?, ?, ?, ?)',
      [
        semester.name,
        semester.academicYear,
        semester.termIndex,
        semester.startsOn.toIso8601String(),
        semester.isCurrent ? 1 : 0,
      ],
    );
    return _lastInsertId();
  }

  Future<void> updateSemester(Semester semester) async {
    await ensureInitialized();
    if (semester.isCurrent) {
      await customStatement('UPDATE semesters SET is_current = 0');
    }
    await customStatement(
      '''
      UPDATE semesters
      SET name = ?, academic_year = ?, term_index = ?, starts_on = ?, is_current = ?
      WHERE id = ?
      ''',
      [
        semester.name,
        semester.academicYear,
        semester.termIndex,
        semester.startsOn.toIso8601String(),
        semester.isCurrent ? 1 : 0,
        semester.id,
      ],
    );
  }

  Future<void> setCurrentSemester(int semesterId) async {
    await ensureInitialized();
    await customStatement('UPDATE semesters SET is_current = 0');
    await customStatement('UPDATE semesters SET is_current = 1 WHERE id = ?', [
      semesterId,
    ]);
  }

  Future<List<TimeSlot>> getTimeSlots() async {
    await ensureInitialized();
    final rows = await customSelect(
      'SELECT * FROM time_slots ORDER BY section ASC',
    ).get();
    return rows.map(_timeSlotFromRow).toList();
  }

  Future<void> upsertTimeSlot(TimeSlot slot) async {
    await ensureInitialized();
    await customStatement(
      '''
      INSERT INTO time_slots (id, section, start_time, end_time, profile_name)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        section = excluded.section,
        start_time = excluded.start_time,
        end_time = excluded.end_time,
        profile_name = excluded.profile_name
      ''',
      [slot.id, slot.section, slot.startTime, slot.endTime, slot.profileName],
    );
  }

  Future<List<CourseEntry>> getEntriesForSemester(int semesterId) async {
    await ensureInitialized();
    final rows = await customSelect(
      '''
      SELECT
        c.id AS course_id,
        c.semester_id,
        c.name,
        c.code,
        c.category,
        c.teacher,
        c.note,
        c.source,
        o.id AS occurrence_id,
        o.weekday,
        o.start_section,
        o.end_section,
        o.classroom,
        o.campus,
        o.week_expression,
        o.parsed_weeks
      FROM courses c
      INNER JOIN course_occurrences o ON o.course_id = c.id
      WHERE c.semester_id = ?
      ORDER BY o.weekday ASC, o.start_section ASC, c.name ASC
      ''',
      variables: [Variable<int>(semesterId)],
    ).get();
    return rows.map(_entryFromRow).toList();
  }

  Future<CourseEntry?> getEntryByCourseId(int courseId) async {
    await ensureInitialized();
    final rows = await customSelect(
      '''
      SELECT
        c.id AS course_id,
        c.semester_id,
        c.name,
        c.code,
        c.category,
        c.teacher,
        c.note,
        c.source,
        o.id AS occurrence_id,
        o.weekday,
        o.start_section,
        o.end_section,
        o.classroom,
        o.campus,
        o.week_expression,
        o.parsed_weeks
      FROM courses c
      INNER JOIN course_occurrences o ON o.course_id = c.id
      WHERE c.id = ?
      LIMIT 1
      ''',
      variables: [Variable<int>(courseId)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _entryFromRow(rows.first);
  }

  Future<int> insertCourseWithOccurrence(CourseDraft draft) async {
    await ensureInitialized();
    return transaction(() async {
      await customStatement(
        '''
        INSERT INTO courses (semester_id, name, code, category, teacher, note, source)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          draft.semesterId,
          draft.name,
          draft.code,
          draft.category,
          draft.teacher,
          draft.note,
          draft.source,
        ],
      );
      final courseId = await _lastInsertId();
      await customStatement(
        '''
        INSERT INTO course_occurrences (
          course_id, weekday, start_section, end_section, classroom, campus, week_expression, parsed_weeks
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          courseId,
          draft.weekday,
          draft.startSection,
          draft.endSection,
          draft.classroom,
          draft.campus,
          draft.weekExpression,
          _encodeWeeks(draft.parsedWeeks),
        ],
      );
      return courseId;
    });
  }

  Future<void> updateCourseWithOccurrence(
    int courseId,
    CourseDraft draft,
  ) async {
    await ensureInitialized();
    await transaction(() async {
      await customStatement(
        '''
        UPDATE courses
        SET semester_id = ?, name = ?, code = ?, category = ?, teacher = ?, note = ?, source = ?
        WHERE id = ?
        ''',
        [
          draft.semesterId,
          draft.name,
          draft.code,
          draft.category,
          draft.teacher,
          draft.note,
          draft.source,
          courseId,
        ],
      );
      await customStatement(
        '''
        UPDATE course_occurrences
        SET weekday = ?, start_section = ?, end_section = ?, classroom = ?, campus = ?, week_expression = ?, parsed_weeks = ?
        WHERE course_id = ?
        ''',
        [
          draft.weekday,
          draft.startSection,
          draft.endSection,
          draft.classroom,
          draft.campus,
          draft.weekExpression,
          _encodeWeeks(draft.parsedWeeks),
          courseId,
        ],
      );
    });
  }

  Future<void> deleteCourse(int courseId) async {
    await ensureInitialized();
    await customStatement('DELETE FROM courses WHERE id = ?', [courseId]);
  }

  Future<int> insertImportBatch({
    required String sourceType,
    required DateTime importedAt,
    String? rawSnapshotPath,
    required String status,
  }) async {
    await ensureInitialized();
    await customStatement(
      'INSERT INTO import_batches (source_type, imported_at, raw_snapshot_path, status) VALUES (?, ?, ?, ?)',
      [sourceType, importedAt.toIso8601String(), rawSnapshotPath, status],
    );
    return _lastInsertId();
  }

  Future<void> updateImportBatchStatus(int batchId, String status) async {
    await ensureInitialized();
    await customStatement('UPDATE import_batches SET status = ? WHERE id = ?', [
      status,
      batchId,
    ]);
  }

  Future<List<ImportBatch>> getImportBatches() async {
    await ensureInitialized();
    final rows = await customSelect(
      'SELECT * FROM import_batches ORDER BY imported_at DESC, id DESC',
    ).get();
    return rows.map(_importBatchFromRow).toList();
  }

  Future<int> _lastInsertId() async {
    final row = await customSelect(
      'SELECT last_insert_rowid() AS id',
    ).getSingle();
    return row.read<int>('id');
  }

  Semester _semesterFromRow(QueryRow row) {
    return Semester(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      academicYear: row.read<String>('academic_year'),
      termIndex: row.read<int>('term_index'),
      startsOn: DateTime.parse(row.read<String>('starts_on')),
      isCurrent: row.read<int>('is_current') == 1,
    );
  }

  TimeSlot _timeSlotFromRow(QueryRow row) {
    return TimeSlot(
      id: row.read<int>('id'),
      section: row.read<int>('section'),
      startTime: row.read<String>('start_time'),
      endTime: row.read<String>('end_time'),
      profileName: row.read<String>('profile_name'),
    );
  }

  CourseEntry _entryFromRow(QueryRow row) {
    final course = Course(
      id: row.read<int>('course_id'),
      semesterId: row.read<int>('semester_id'),
      name: row.read<String>('name'),
      code: row.readNullable<String>('code'),
      category: row.readNullable<String>('category'),
      teacher: row.readNullable<String>('teacher'),
      note: row.readNullable<String>('note'),
      source: row.read<String>('source'),
    );
    final occurrence = CourseOccurrence(
      id: row.read<int>('occurrence_id'),
      courseId: row.read<int>('course_id'),
      weekday: row.read<int>('weekday'),
      startSection: row.read<int>('start_section'),
      endSection: row.read<int>('end_section'),
      classroom: row.readNullable<String>('classroom'),
      campus: row.readNullable<String>('campus'),
      weekExpression: row.read<String>('week_expression'),
      parsedWeeks: _decodeWeeks(row.read<String>('parsed_weeks')),
    );
    return CourseEntry(course: course, occurrence: occurrence);
  }

  ImportBatch _importBatchFromRow(QueryRow row) {
    return ImportBatch(
      id: row.read<int>('id'),
      sourceType: row.read<String>('source_type'),
      importedAt: DateTime.parse(row.read<String>('imported_at')),
      rawSnapshotPath: row.readNullable<String>('raw_snapshot_path'),
      status: row.read<String>('status'),
    );
  }

  String _encodeWeeks(List<int> weeks) => (weeks.toList()..sort()).join(',');

  List<int> _decodeWeeks(String value) {
    if (value.trim().isEmpty) {
      return const [];
    }
    return value.split(',').map(int.parse).toList()..sort();
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

