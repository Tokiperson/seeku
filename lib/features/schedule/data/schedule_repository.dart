import '../../../core/database/seeku_database.dart';
import '../../../core/rules/schedule_rules.dart';
import '../../import/domain/import_models.dart';
import '../domain/schedule_models.dart';

class ScheduleRepository {
  const ScheduleRepository(this._database);

  final SeekuDatabase _database;

  Future<void> bootstrap() async {
    await _database.ensureInitialized();
    await _database.seedDefaults();
  }

  Future<List<Semester>> getSemesters() async {
    await bootstrap();
    return _database.getSemesters();
  }

  Future<Semester?> getCurrentSemester() async {
    await bootstrap();
    return _database.getCurrentSemester();
  }

  Future<int> createSemester(Semester semester) async {
    await bootstrap();
    return _database.insertSemester(semester);
  }

  Future<void> updateSemester(Semester semester) async {
    await bootstrap();
    return _database.updateSemester(semester);
  }

  Future<void> setCurrentSemester(int semesterId) =>
      _database.setCurrentSemester(semesterId);

  Future<void> deleteSemester(int semesterId) =>
      _database.deleteSemester(semesterId);

  Future<List<TimeSlot>> getTimeSlots() async {
    await bootstrap();
    return _database.getTimeSlots();
  }

  Future<void> updateTimeSlot(TimeSlot slot) => _database.upsertTimeSlot(slot);

  Future<List<CourseEntry>> getEntriesForSemester(int semesterId) =>
      _database.getEntriesForSemester(semesterId);

  Future<CourseEntry?> getEntryByCourseId(int courseId) =>
      _database.getEntryByCourseId(courseId);

  Future<int> addCourse(CourseDraft draft) =>
      _database.insertCourseWithOccurrence(draft);

  Future<void> updateCourse(int courseId, CourseDraft draft) =>
      _database.updateCourseWithOccurrence(courseId, draft);

  Future<void> deleteCourse(int courseId) => _database.deleteCourse(courseId);

  int currentWeekForSemester(Semester semester, {DateTime? now}) {
    return TeachingWeekCalculator.currentWeek(
      semester.startsOn,
      now ?? DateTime.now(),
    );
  }
}
