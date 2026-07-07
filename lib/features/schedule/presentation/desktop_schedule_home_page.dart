import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/window_controls.dart';
import '../../../core/providers/app_providers.dart';
import '../../ai/presentation/ai_core_status_button.dart';
import '../domain/schedule_grid_models.dart';
import '../domain/schedule_models.dart';
import 'schedule_grid_view.dart';

class DesktopScheduleHomePage extends ConsumerStatefulWidget {
  const DesktopScheduleHomePage({super.key});

  @override
  ConsumerState<DesktopScheduleHomePage> createState() =>
      _DesktopScheduleHomePageState();
}

class _DesktopScheduleHomePageState
    extends ConsumerState<DesktopScheduleHomePage> {
  late DateTime _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    return bootstrap.when(
      data: (_) => _DesktopScheduleContent(openedAt: _openedAt),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('初始化失败：$error'))),
    );
  }
}

class _DesktopScheduleContent extends ConsumerWidget {
  const _DesktopScheduleContent({required this.openedAt});

  final DateTime openedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(scheduleViewModeProvider);
    final selectedWeekday = ref.watch(selectedWeekdayProvider);
    final entriesAsync = ref.watch(currentSemesterEntriesProvider);
    final semesterAsync = ref.watch(currentSemesterProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final settings = switch (settingsAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final sectionCount = settings?.visibleSectionCount ?? 13;
    final showOffWeekCourses = settings?.showOffWeekCourses ?? false;
    final courseColorOverrides = settings?.courseColorOverrides ?? const {};

    return Scaffold(
      floatingActionButton: const AiCoreStatusButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          const DesktopWindowTitleBar(title: 'SeekU'),
          Expanded(
            child: Row(
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
                            data: (entries) => semesterAsync.when(
                              data: (semester) => timeSlotsAsync.when(
                                data: (timeSlots) {
                                  if (semester == null) {
                                    return const Center(child: Text('尚未创建学期'));
                                  }
                                  final grid = ScheduleGridBuilder.build(
                                    entries: entries,
                                    timeSlots: timeSlots,
                                    semester: semester,
                                    selectedWeek: selectedWeek,
                                    openedAt: openedAt,
                                    sectionCount: sectionCount,
                                    includeOffWeekEntries: showOffWeekCourses,
                                  );
                                  final visible = mode == ScheduleViewMode.day
                                      ? [selectedWeekday]
                                      : const [1, 2, 3, 4, 5, 6, 7];
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: SeekUColors.scheduleSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: SingleChildScrollView(
                                      child: ScheduleGridView(
                                        grid: grid,
                                        visibleWeekdays: visible,
                                        timeAxisSide: TimeAxisSide.right,
                                        slotHeight: 68,
                                        blueSurface: true,
                                        courseColorOverrides:
                                            courseColorOverrides,
                                        onDaySelected: (weekday) {
                                          ref
                                              .read(
                                                selectedWeekdayProvider
                                                    .notifier,
                                              )
                                              .setWeekday(weekday);
                                          ref
                                              .read(
                                                scheduleViewModeProvider
                                                    .notifier,
                                              )
                                              .setMode(ScheduleViewMode.day);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stackTrace) =>
                                    Center(child: Text('节次加载失败：$error')),
                              ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stackTrace) =>
                                  Center(child: Text('学期加载失败：$error')),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stackTrace) =>
                                Center(child: Text('课表加载失败：$error')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                      .read(selectedWeekdayProvider.notifier)
                      .setWeekday(DateTime.now().weekday);
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
