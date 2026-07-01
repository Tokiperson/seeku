import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/schedule_models.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CourseEntry?>(
      future: ref
          .watch(scheduleRepositoryProvider)
          .getEntryByCourseId(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final entry = snapshot.data;
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('课程详情')),
            body: const Center(child: Text('未找到课程')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('课程详情'),
            leading: IconButton(
              tooltip: '返回课表',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                tooltip: '编辑课程',
                onPressed: () => context.go('/courses/$courseId/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '删除课程',
                onPressed: () => _deleteCourse(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.course.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: SeekUColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.course.source == 'manual'
                            ? '来源：手动创建'
                            : '来源：${entry.course.source}',
                      ),
                      const Divider(height: 32),
                      _DetailRow(label: '教师', value: entry.course.teacher),
                      _DetailRow(label: '课程代码', value: entry.course.code),
                      _DetailRow(label: '分类', value: entry.course.category),
                      _DetailRow(
                        label: '时间',
                        value:
                            '周${entry.occurrence.weekday} · ${entry.occurrence.startSection}-${entry.occurrence.endSection} 节',
                      ),
                      _DetailRow(
                        label: '周次',
                        value: entry.occurrence.weekExpression,
                      ),
                      _DetailRow(
                        label: '教室',
                        value: entry.occurrence.classroom,
                      ),
                      _DetailRow(label: '校区', value: entry.occurrence.campus),
                      _DetailRow(label: '备注', value: entry.course.note),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCourse(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: const Text('确认删除这门课程吗？此操作会从本地课表移除该课程。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(scheduleRepositoryProvider).deleteCourse(courseId);
    ref.invalidate(currentSemesterEntriesProvider);
    if (context.mounted) {
      context.go('/');
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: SeekUColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text((value == null || value!.isEmpty) ? '未填写' : value!),
          ),
        ],
      ),
    );
  }
}
