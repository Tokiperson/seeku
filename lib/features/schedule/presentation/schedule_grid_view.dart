import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../domain/schedule_grid_models.dart';
import 'schedule_course_colors.dart';

enum TimeAxisSide { left, right }

class ScheduleGridView extends StatelessWidget {
  const ScheduleGridView({
    super.key,
    required this.grid,
    required this.visibleWeekdays,
    required this.timeAxisSide,
    required this.slotHeight,
    required this.onDaySelected,
    this.blueSurface = false,
    this.courseColorOverrides = const {},
  });

  final ScheduleGrid grid;
  final List<int> visibleWeekdays;
  final TimeAxisSide timeAxisSide;
  final double slotHeight;
  final ValueChanged<int> onDaySelected;
  final bool blueSurface;
  final Map<String, int> courseColorOverrides;

  @override
  Widget build(BuildContext context) {
    final days = visibleWeekdays
        .map(grid.dayForWeekday)
        .toList(growable: false);
    final headerHeight = 46.0;
    final axisWidth = timeAxisSide == TimeAxisSide.left ? 58.0 : 76.0;
    final minDayWidth = visibleWeekdays.length == 1 ? 260.0 : 112.0;
    final bodyHeight = slotHeight * grid.sectionCount;
    final lineFractions = days
        .map((day) => day.currentTimeFraction)
        .whereType<double>()
        .toList(growable: false);
    final lineFraction = lineFractions.isEmpty ? null : lineFractions.first;

    Widget axisHeader = SizedBox(width: axisWidth, height: headerHeight);
    Widget header = SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          for (final day in days)
            SizedBox(
              width: minDayWidth,
              child: _DayHeader(
                day: day,
                blueSurface: blueSurface,
                onTap: () => onDaySelected(day.weekday),
              ),
            ),
        ],
      ),
    );
    Widget axis = SizedBox(
      width: axisWidth,
      height: bodyHeight,
      child: _TimeAxis(
        slots: days.first.slots,
        slotHeight: slotHeight,
        side: timeAxisSide,
        blueSurface: blueSurface,
      ),
    );
    Widget body = SizedBox(
      height: bodyHeight,
      width: minDayWidth * days.length,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final day in days)
                SizedBox(
                  width: minDayWidth,
                  child: _DayGridColumn(
                    day: day,
                    slotHeight: slotHeight,
                    blueSurface: blueSurface,
                    courseColorOverrides: courseColorOverrides,
                    onTap: () => onDaySelected(day.weekday),
                  ),
                ),
            ],
          ),
          if (lineFraction != null)
            Positioned(
              left: 0,
              right: 0,
              top: lineFraction * bodyHeight,
              child: const _CurrentTimeLine(),
            ),
        ],
      ),
    );

    final rowHeader = timeAxisSide == TimeAxisSide.left
        ? [axisHeader, header]
        : [header, axisHeader];
    final rowBody = timeAxisSide == TimeAxisSide.left
        ? [axis, body]
        : [body, axis];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: blueSurface ? SeekUColors.scheduleSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: rowHeader),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.blueSurface,
    required this.onTap,
  });

  final ScheduleGridDay day;
  final bool blueSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: day.isToday
              ? SeekUColors.sky
              : blueSurface
              ? SeekUColors.scheduleSurface
              : Colors.white,
          border: Border.all(
            color: blueSurface ? Colors.white : SeekUColors.border,
          ),
        ),
        child: Text(
          '${day.weekdayName} ${day.shortDate}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: day.isToday ? SeekUColors.cquBlue : SeekUColors.text,
          ),
        ),
      ),
    );
  }
}

class _TimeAxis extends StatelessWidget {
  const _TimeAxis({
    required this.slots,
    required this.slotHeight,
    required this.side,
    required this.blueSurface,
  });

  final List<ScheduleGridSlot> slots;
  final double slotHeight;
  final TimeAxisSide side;
  final bool blueSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final slot in slots)
          Container(
            height: slotHeight,
            alignment: side == TimeAxisSide.left
                ? Alignment.centerRight
                : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: blueSurface ? SeekUColors.scheduleSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: blueSurface ? Colors.white : SeekUColors.border,
                ),
              ),
            ),
            child: Text(
              slot.timeSlot == null
                  ? '${slot.section}'
                  : '${slot.section}\n${slot.timeSlot!.startTime}-${slot.timeSlot!.endTime}',
              textAlign: side == TimeAxisSide.left
                  ? TextAlign.right
                  : TextAlign.left,
              style: const TextStyle(fontSize: 10, color: SeekUColors.muted),
            ),
          ),
      ],
    );
  }
}

class _DayGridColumn extends StatelessWidget {
  const _DayGridColumn({
    required this.day,
    required this.slotHeight,
    required this.blueSurface,
    required this.courseColorOverrides,
    required this.onTap,
  });

  final ScheduleGridDay day;
  final double slotHeight;
  final bool blueSurface;
  final Map<String, int> courseColorOverrides;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Column(
            children: [
              for (final _ in day.slots)
                SizedBox(
                  height: slotHeight,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: blueSurface ? 5 : 0,
                      vertical: blueSurface ? 2 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: blueSurface
                          ? Colors.white.withAlpha(138)
                          : Colors.white,
                      borderRadius: blueSurface
                          ? BorderRadius.circular(6)
                          : null,
                      border: Border.all(
                        color: blueSurface ? Colors.white : SeekUColors.border,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final block in day.blocks)
            Positioned(
              top: block.startSlotIndex * slotHeight + 4,
              left: blueSurface ? 9 : 6,
              right: blueSurface ? 9 : 6,
              height: block.slotSpan * slotHeight - 8,
              child: _GridCourseCard(
                block: block,
                color: CourseColorPalette.colorForCourse(
                  block.entry.course.name,
                  courseColorOverrides,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridCourseCard extends StatelessWidget {
  const _GridCourseCard({required this.block, required this.color});

  final ScheduleGridCourseBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final entry = block.entry;
    final background = block.isInSelectedWeek ? color : color.withAlpha(106);
    final foreground = block.isInSelectedWeek
        ? Colors.white
        : Colors.white.withAlpha(226);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go('/courses/${entry.course.id}'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: block.isCurrent
                ? SeekUColors.nowLine
                : block.isInSelectedWeek
                ? Colors.white.withAlpha(170)
                : Colors.white.withAlpha(220),
            width: block.isCurrent ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180F2A4A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.course.name,
                    maxLines: block.slotSpan > 1 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                ),
                if (!block.isInSelectedWeek) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(58),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '非本周',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.occurrence.startSection}-${entry.occurrence.endSection}节',
              style: TextStyle(fontSize: 10, color: foreground.withAlpha(226)),
            ),
            if ((entry.occurrence.classroom ?? '').isNotEmpty)
              Text(
                entry.occurrence.classroom!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: foreground.withAlpha(226),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrentTimeLine extends StatelessWidget {
  const _CurrentTimeLine();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: SeekUColors.nowLine,
              shape: BoxShape.circle,
              border: Border.all(color: SeekUColors.cquBlueDark),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: SeekUColors.nowLine,
                border: Border.all(color: SeekUColors.cquBlueDark, width: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
