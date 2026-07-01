import 'package:flutter_test/flutter_test.dart';

import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/features/import/domain/import_models.dart';
import 'package:seeku/features/schedule/data/schedule_repository.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  test(
    'database stores semesters, courses, time slots, and import batches',
    () async {
      final database = SeekuDatabase.memory();
      addTearDown(database.close);
      final repository = ScheduleRepository(database);

      await repository.bootstrap();
      final semester = await repository.getCurrentSemester();
      expect(semester, isNotNull);

      final courseId = await repository.addCourse(
        CourseDraft(
          semesterId: semester!.id,
          name: '数据结构',
          teacher: '张老师',
          classroom: '虎溪 D123',
          weekday: 2,
          startSection: 3,
          endSection: 4,
          weekExpression: '[1-16周]',
          parsedWeeks: List<int>.generate(16, (index) => index + 1),
          source: 'manual',
        ),
      );

      final entries = await repository.getEntriesForSemester(semester.id);
      expect(entries, hasLength(1));
      expect(entries.single.course.id, courseId);
      expect(entries.single.occurrence.classroom, '虎溪 D123');

      const updatedSlot = TimeSlot(
        id: 1,
        section: 1,
        startTime: '08:10',
        endTime: '08:55',
        profileName: 'CQU 测试',
      );
      await repository.updateTimeSlot(updatedSlot);
      final slots = await repository.getTimeSlots();
      expect(slots.first.startTime, '08:10');

      final batchId = await database.insertImportBatch(
        sourceType: 'excel',
        importedAt: DateTime(2026, 7, 1),
        rawSnapshotPath: 'sample.xlsx',
        status: 'waitingForSample',
      );
      final batches = await database.getImportBatches();
      expect(batches.single.id, batchId);
      expect(batches.single.rawSnapshotPath, 'sample.xlsx');
    },
  );
}
