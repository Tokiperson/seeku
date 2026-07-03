import 'schedule_models.dart';

const scheduleWeekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

class ScheduleGrid {
  const ScheduleGrid({
    required this.days,
    required this.timeSlots,
    required this.selectedWeek,
  });

  final List<ScheduleGridDay> days;
  final List<TimeSlot> timeSlots;
  final int selectedWeek;

  ScheduleGridDay dayForWeekday(int weekday) {
    return days.firstWhere((day) => day.weekday == weekday);
  }
}

class ScheduleGridDay {
  const ScheduleGridDay({
    required this.weekday,
    required this.date,
    required this.slots,
    required this.blocks,
    required this.isToday,
    required this.currentTimeFraction,
  });

  final int weekday;
  final DateTime date;
  final List<ScheduleGridSlot> slots;
  final List<ScheduleGridCourseBlock> blocks;
  final bool isToday;
  final double? currentTimeFraction;

  String get weekdayName => scheduleWeekdayNames[weekday - 1];
  String get shortDate => '${date.month}/${date.day}';
}

class ScheduleGridSlot {
  const ScheduleGridSlot({required this.section, required this.timeSlot});

  final int section;
  final TimeSlot? timeSlot;
}

class ScheduleGridCourseBlock {
  const ScheduleGridCourseBlock({
    required this.entry,
    required this.startSlotIndex,
    required this.slotSpan,
    required this.isCurrent,
  });

  final CourseEntry entry;
  final int startSlotIndex;
  final int slotSpan;
  final bool isCurrent;
}

class ScheduleGridBuilder {
  const ScheduleGridBuilder._();

  static ScheduleGrid build({
    required List<CourseEntry> entries,
    required List<TimeSlot> timeSlots,
    required Semester semester,
    required int selectedWeek,
    required DateTime openedAt,
  }) {
    final sortedSlots = timeSlots.toList()
      ..sort((a, b) => a.section.compareTo(b.section));
    final slotBySection = {for (final slot in sortedSlots) slot.section: slot};
    final weekStart = _weekStart(semester.startsOn, selectedWeek);
    final days = <ScheduleGridDay>[];

    for (var weekday = 1; weekday <= 7; weekday++) {
      final date = weekStart.add(Duration(days: weekday - 1));
      final dayEntries =
          entries
              .where(
                (entry) =>
                    entry.occurrence.weekday == weekday &&
                    entry.occursInWeek(selectedWeek),
              )
              .toList()
            ..sort(
              (a, b) => a.occurrence.startSection.compareTo(
                b.occurrence.startSection,
              ),
            );
      final slots = [
        for (var section = 1; section <= 13; section++)
          ScheduleGridSlot(section: section, timeSlot: slotBySection[section]),
      ];
      final currentFraction = _currentTimeFraction(
        date: date,
        openedAt: openedAt,
        slots: slots,
      );
      final blocks = dayEntries
          .map(
            (entry) => ScheduleGridCourseBlock(
              entry: entry,
              startSlotIndex: (entry.occurrence.startSection - 1)
                  .clamp(0, 12)
                  .toInt(),
              slotSpan:
                  (entry.occurrence.endSection -
                          entry.occurrence.startSection +
                          1)
                      .clamp(1, 13)
                      .toInt(),
              isCurrent:
                  currentFraction != null &&
                  _entryContainsTime(entry, openedAt, slotBySection),
            ),
          )
          .toList(growable: false);
      days.add(
        ScheduleGridDay(
          weekday: weekday,
          date: date,
          slots: slots,
          blocks: blocks,
          isToday: _sameDate(date, openedAt),
          currentTimeFraction: currentFraction,
        ),
      );
    }

    return ScheduleGrid(
      days: days,
      timeSlots: sortedSlots,
      selectedWeek: selectedWeek,
    );
  }

  static DateTime _weekStart(DateTime semesterStart, int selectedWeek) {
    final normalizedStart = DateTime(
      semesterStart.year,
      semesterStart.month,
      semesterStart.day,
    );
    return normalizedStart.add(Duration(days: (selectedWeek - 1) * 7));
  }

  static double? _currentTimeFraction({
    required DateTime date,
    required DateTime openedAt,
    required List<ScheduleGridSlot> slots,
  }) {
    if (!_sameDate(date, openedAt)) {
      return null;
    }
    final nowMinutes = openedAt.hour * 60 + openedAt.minute;
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index].timeSlot;
      if (slot == null) {
        continue;
      }
      final start = _parseClock(slot.startTime);
      final end = _parseClock(slot.endTime);
      if (nowMinutes < start || nowMinutes > end) {
        continue;
      }
      final slotProgress = (nowMinutes - start) / (end - start);
      final fraction = (index + slotProgress) / slots.length;
      if (fraction <= 0.02 || fraction >= 0.98) {
        return null;
      }
      return fraction;
    }
    return null;
  }

  static bool _entryContainsTime(
    CourseEntry entry,
    DateTime openedAt,
    Map<int, TimeSlot> slotBySection,
  ) {
    final start = slotBySection[entry.occurrence.startSection];
    final end = slotBySection[entry.occurrence.endSection];
    if (start == null || end == null) {
      return false;
    }
    final minutes = openedAt.hour * 60 + openedAt.minute;
    return minutes >= _parseClock(start.startTime) &&
        minutes <= _parseClock(end.endTime);
  }

  static bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int _parseClock(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return 0;
    }
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
