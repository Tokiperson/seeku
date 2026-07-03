import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/schedule_grid_models.dart';
import 'schedule_grid_view.dart';

class AndroidScheduleHomePage extends ConsumerStatefulWidget {
  const AndroidScheduleHomePage({super.key});

  @override
  ConsumerState<AndroidScheduleHomePage> createState() =>
      _AndroidScheduleHomePageState();
}

class _AndroidScheduleHomePageState
    extends ConsumerState<AndroidScheduleHomePage> {
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
      data: (_) => _AndroidScheduleContent(openedAt: _openedAt),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('初始化失败：$error'))),
    );
  }
}

class _AndroidScheduleContent extends ConsumerWidget {
  const _AndroidScheduleContent({required this.openedAt});

  final DateTime openedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(scheduleViewModeProvider);
    final selectedWeekday = ref.watch(selectedWeekdayProvider);
    final entriesAsync = ref.watch(currentSemesterEntriesProvider);
    final semesterAsync = ref.watch(currentSemesterProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _TopPill(
                      title: '当前课程',
                      subtitle: mode == ScheduleViewMode.week
                          ? '第 $selectedWeek 周'
                          : '${scheduleWeekdayNames[selectedWeekday - 1]} 日视图',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TopPill(
                      title: _greeting(),
                      subtitle: _todayText(openedAt),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: SeekUColors.cquBlueDark,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: entriesAsync.when(
                  data: (entries) => semesterAsync.when(
                    data: (semester) => timeSlotsAsync.when(
                      data: (timeSlots) {
                        if (semester == null) {
                          return const Center(
                            child: Text(
                              '尚未创建学期',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        final grid = ScheduleGridBuilder.build(
                          entries: entries,
                          timeSlots: timeSlots,
                          semester: semester,
                          selectedWeek: selectedWeek,
                          openedAt: openedAt,
                        );
                        final visible = mode == ScheduleViewMode.day
                            ? [selectedWeekday]
                            : const [1, 2, 3, 4, 5, 6, 7];
                        return SingleChildScrollView(
                          child: ScheduleGridView(
                            grid: grid,
                            visibleWeekdays: visible,
                            timeAxisSide: TimeAxisSide.left,
                            slotHeight: 72,
                            blueSurface: true,
                            onDaySelected: (weekday) {
                              ref
                                  .read(selectedWeekdayProvider.notifier)
                                  .setWeekday(weekday);
                              ref
                                  .read(scheduleViewModeProvider.notifier)
                                  .setMode(ScheduleViewMode.day);
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          '节次加载失败：$error',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        '学期加载失败：$error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      '课表加载失败：$error',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.go('/courses/new');
          } else if (index == 2) {
            context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '课表',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '添加',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = openedAt.hour;
    if (hour < 12) {
      return '早上好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  String _todayText(DateTime date) {
    final weekday = scheduleWeekdayNames[date.weekday - 1];
    return '$weekday，${date.year}/${date.month}/${date.day}';
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({
    required this.title,
    required this.subtitle,
    this.alignEnd = false,
  });

  final String title;
  final String subtitle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: SeekUColors.cquBlueDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
