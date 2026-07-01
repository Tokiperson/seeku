import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../schedule/domain/schedule_models.dart';

const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

class ScheduleHomePage extends ConsumerWidget {
  const ScheduleHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    return bootstrap.when(
      data: (_) => const _ScheduleHomeContent(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('初始化失败：$error'))),
    );
  }
}

class _ScheduleHomeContent extends ConsumerWidget {
  const _ScheduleHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(scheduleViewModeProvider);
    final entriesAsync = ref.watch(currentSemesterEntriesProvider);
    final semesterAsync = ref.watch(currentSemesterProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: IconButton.filled(
                tooltip: '新增课程',
                onPressed: () => context.go('/courses/new'),
                icon: const Icon(Icons.add),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('课表'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                label: Text('导入'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('设置'),
              ),
            ],
            onDestinationSelected: (index) {
              if (index == 1) {
                context.go('/import');
              } else if (index == 2) {
                context.go('/settings');
              }
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScheduleToolbar(
                      mode: mode,
                      selectedWeek: selectedWeek,
                      semesterAsync: semesterAsync,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: entriesAsync.when(
                        data: (entries) => timeSlotsAsync.when(
                          data: (timeSlots) {
                            if (mode == ScheduleViewMode.day) {
                              return _DayView(
                                entries: entries,
                                selectedWeek: selectedWeek,
                                timeSlots: timeSlots,
                              );
                            }
                            return _WeekView(
                              entries: entries,
                              selectedWeek: selectedWeek,
                              timeSlots: timeSlots,
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) =>
                              Center(child: Text('节次加载失败：$error')),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) =>
                            Center(child: Text('课表加载失败：$error')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleToolbar extends ConsumerWidget {
  const _ScheduleToolbar({
    required this.mode,
    required this.selectedWeek,
    required this.semesterAsync,
  });

  final ScheduleViewMode mode;
  final int selectedWeek;
  final AsyncValue<Semester?> semesterAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SeekU 课表',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: SeekUColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  semesterAsync.when(
                    data: (semester) => Text(
                      semester == null
                          ? '尚未创建学期'
                          : '${semester.name} · 第 $selectedWeek 周',
                      style: const TextStyle(color: SeekUColors.muted),
                    ),
                    loading: () => const Text(
                      '正在加载学期...',
                      style: TextStyle(color: SeekUColors.muted),
                    ),
                    error: (error, stackTrace) => Text('学期加载失败：$error'),
                  ),
                ],
              ),
            ),
            semestersAsync.when(
              data: (semesters) => semesterAsync.when(
                data: (current) => DropdownButton<int>(
                  value: current?.id,
                  hint: const Text('选择学期'),
                  items: semesters
                      .map(
                        (semester) => DropdownMenuItem<int>(
                          value: semester.id,
                          child: Text(semester.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    await ref
                        .read(scheduleRepositoryProvider)
                        .setCurrentSemester(value);
                    ref.invalidate(currentSemesterProvider);
                    ref.invalidate(currentSemesterEntriesProvider);
                    ref.invalidate(semestersProvider);
                  },
                ),
                loading: () => const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              loading: () =>
                  const SizedBox(width: 120, child: LinearProgressIndicator()),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SegmentedButton<ScheduleViewMode>(
                segments: const [
                  ButtonSegment(
                    value: ScheduleViewMode.week,
                    icon: Icon(Icons.view_week_outlined),
                    label: Text('周视图'),
                  ),
                  ButtonSegment(
                    value: ScheduleViewMode.day,
                    icon: Icon(Icons.today_outlined),
                    label: Text('日视图'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) => ref
                    .read(scheduleViewModeProvider.notifier)
                    .setMode(selection.first),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                tooltip: '上一周',
                onPressed: selectedWeek > 1
                    ? () => ref.read(selectedWeekProvider.notifier).previous()
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '第 $selectedWeek 周',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                tooltip: '下一周',
                onPressed: () => ref.read(selectedWeekProvider.notifier).next(),
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  final semester = await ref.read(
                    currentSemesterProvider.future,
                  );
                  if (semester == null) {
                    return;
                  }
                  final currentWeek = ref
                      .read(scheduleRepositoryProvider)
                      .currentWeekForSemester(semester);
                  ref.read(selectedWeekProvider.notifier).setWeek(currentWeek);
                  ref
                      .read(scheduleViewModeProvider.notifier)
                      .setMode(ScheduleViewMode.day);
                },
                icon: const Icon(Icons.my_location_outlined),
                label: const Text('今日'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.entries,
    required this.selectedWeek,
    required this.timeSlots,
  });

  final List<CourseEntry> entries;
  final int selectedWeek;
  final List<TimeSlot> timeSlots;

  @override
  Widget build(BuildContext context) {
    final entriesByDay = <int, List<CourseEntry>>{
      for (var day = 1; day <= 7; day++)
        day: entries
            .where(
              (entry) =>
                  entry.occurrence.weekday == day &&
                  entry.occursInWeek(selectedWeek),
            )
            .toList(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 920 ? 920 : constraints.maxWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final dayEntries = entriesByDay[weekday]!
                  ..sort(
                    (a, b) => a.occurrence.startSection.compareTo(
                      b.occurrence.startSection,
                    ),
                  );
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 6 ? 0 : 10),
                    child: _DayColumn(
                      weekday: weekday,
                      entries: dayEntries,
                      selectedWeek: selectedWeek,
                      timeSlots: timeSlots,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.entries,
    required this.selectedWeek,
    required this.timeSlots,
  });

  final List<CourseEntry> entries;
  final int selectedWeek;
  final List<TimeSlot> timeSlots;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final dayEntries =
        entries
            .where(
              (entry) =>
                  entry.occurrence.weekday == today &&
                  entry.occursInWeek(selectedWeek),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.occurrence.startSection.compareTo(b.occurrence.startSection),
          );

    return _DayColumn(
      weekday: today,
      entries: dayEntries,
      selectedWeek: selectedWeek,
      timeSlots: timeSlots,
      fullWidth: true,
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.weekday,
    required this.entries,
    required this.selectedWeek,
    required this.timeSlots,
    this.fullWidth = false,
  });

  final int weekday;
  final List<CourseEntry> entries;
  final int selectedWeek;
  final List<TimeSlot> timeSlots;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isToday = weekday == DateTime.now().weekday;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _weekdayNames[weekday - 1],
                    style: TextStyle(
                      fontSize: fullWidth ? 22 : 16,
                      fontWeight: FontWeight.w800,
                      color: isToday ? SeekUColors.cquBlue : SeekUColors.text,
                    ),
                  ),
                ),
                if (isToday)
                  const Icon(
                    Icons.circle,
                    size: 10,
                    color: SeekUColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        '本日暂无课程',
                        style: TextStyle(color: SeekUColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CourseCard(
                        entry: entries[index],
                        isCurrent: _isCurrentEntry(
                          entries[index],
                          selectedWeek,
                          timeSlots,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.entry, required this.isCurrent});

  final CourseEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go('/courses/${entry.course.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? SeekUColors.sky : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? SeekUColors.cquBlue : SeekUColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.course.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: SeekUColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.occurrence.startSection}-${entry.occurrence.endSection} 节 · ${entry.occurrence.weekExpression}',
              style: const TextStyle(color: SeekUColors.muted, fontSize: 12),
            ),
            if ((entry.course.teacher ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.course.teacher!,
                style: const TextStyle(color: SeekUColors.muted, fontSize: 12),
              ),
            ],
            if ((entry.occurrence.classroom ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.occurrence.classroom!,
                style: const TextStyle(color: SeekUColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isCurrentEntry(
  CourseEntry entry,
  int selectedWeek,
  List<TimeSlot> timeSlots,
) {
  final now = DateTime.now();
  if (entry.occurrence.weekday != now.weekday ||
      !entry.occursInWeek(selectedWeek)) {
    return false;
  }
  final currentSection = _currentSection(timeSlots, now);
  if (currentSection == null) {
    return false;
  }
  return currentSection >= entry.occurrence.startSection &&
      currentSection <= entry.occurrence.endSection;
}

int? _currentSection(List<TimeSlot> timeSlots, DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  for (final slot in timeSlots) {
    final start = _parseClock(slot.startTime);
    final end = _parseClock(slot.endTime);
    if (minutes >= start && minutes <= end) {
      return slot.section;
    }
  }
  return null;
}

int _parseClock(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return 0;
  }
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
