import 'package:flutter_test/flutter_test.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/features/schedule/domain/schedule_grid_models.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  test('ScheduleGridBuilder keeps empty slots and spans course blocks', () {
    final semester = Semester(
      id: 1,
      name: '测试学期',
      academicYear: '2025-2026',
      termIndex: 2,
      startsOn: DateTime(2026, 7, 6),
      isCurrent: true,
    );
    const entry = CourseEntry(
      course: Course(id: 1, semesterId: 1, name: '数据结构', source: 'manual'),
      occurrence: CourseOccurrence(
        id: 1,
        courseId: 1,
        weekday: 1,
        startSection: 3,
        endSection: 4,
        classroom: 'D123',
        weekExpression: '[1-16周]',
        parsedWeeks: [1, 2],
      ),
    );

    final grid = ScheduleGridBuilder.build(
      entries: const [entry],
      timeSlots: defaultCquTimeSlots,
      semester: semester,
      selectedWeek: 1,
      openedAt: DateTime(2026, 7, 6, 10, 20),
    );

    final monday = grid.dayForWeekday(1);
    expect(monday.slots, hasLength(13));
    expect(monday.shortDate, '7/6');
    expect(monday.blocks.single.startSlotIndex, 2);
    expect(monday.blocks.single.slotSpan, 2);
    expect(monday.currentTimeFraction, isNotNull);
    expect(monday.blocks.single.isCurrent, isTrue);

    final tuesday = grid.dayForWeekday(2);
    expect(tuesday.blocks, isEmpty);
    expect(tuesday.currentTimeFraction, isNull);
  });
}
