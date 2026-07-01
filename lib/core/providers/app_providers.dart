import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/import/data/import_repository.dart';
import '../../features/import/domain/import_models.dart';
import '../../features/schedule/data/schedule_repository.dart';
import '../../features/schedule/domain/schedule_models.dart';
import '../database/seeku_database.dart';
import '../settings/settings_repository.dart';

final databaseProvider = Provider<SeekuDatabase>((ref) {
  final database = SeekuDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(databaseProvider));
});

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository(ref.watch(databaseProvider));
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(preferences);
});

final bootstrapProvider = FutureProvider<void>((ref) {
  return ref.watch(scheduleRepositoryProvider).bootstrap();
});

final semestersProvider = FutureProvider<List<Semester>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getSemesters();
});

final currentSemesterProvider = FutureProvider<Semester?>((ref) {
  return ref.watch(scheduleRepositoryProvider).getCurrentSemester();
});

final timeSlotsProvider = FutureProvider<List<TimeSlot>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getTimeSlots();
});

final currentSemesterEntriesProvider = FutureProvider<List<CourseEntry>>((
  ref,
) async {
  final semester = await ref.watch(currentSemesterProvider.future);
  if (semester == null) {
    return const [];
  }
  return ref
      .watch(scheduleRepositoryProvider)
      .getEntriesForSemester(semester.id);
});

final importBatchesProvider = FutureProvider<List<ImportBatch>>((ref) {
  return ref.watch(importRepositoryProvider).getImportBatches();
});

final importSnapshotEnabledProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider.future);
  return settings.saveImportSnapshots;
});

enum ScheduleViewMode { week, day }

class ScheduleViewModeController extends Notifier<ScheduleViewMode> {
  @override
  ScheduleViewMode build() => ScheduleViewMode.week;

  void setMode(ScheduleViewMode mode) {
    state = mode;
  }
}

final scheduleViewModeProvider =
    NotifierProvider<ScheduleViewModeController, ScheduleViewMode>(
      ScheduleViewModeController.new,
    );

class SelectedWeekController extends Notifier<int> {
  @override
  int build() => 1;

  void setWeek(int week) {
    state = week < 1 ? 1 : week;
  }

  void previous() {
    setWeek(state - 1);
  }

  void next() {
    setWeek(state + 1);
  }
}

final selectedWeekProvider = NotifierProvider<SelectedWeekController, int>(
  SelectedWeekController.new,
);
