import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../schedule/domain/schedule_models.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(importSnapshotEnabledProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final semesterAsync = ref.watch(currentSemesterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          tooltip: '返回课表',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '基础设置',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          semesterAsync.when(
                            data: (semester) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.school_outlined,
                                color: SeekUColors.cquBlue,
                              ),
                              title: const Text('默认学期'),
                              subtitle: Text(semester?.name ?? '尚未创建学期'),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stackTrace) => Text('学期加载失败：$error'),
                          ),
                          snapshotAsync.when(
                            data: (enabled) => SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(
                                Icons.archive_outlined,
                                color: SeekUColors.cquBlue,
                              ),
                              title: const Text('保存导入原始文件'),
                              subtitle: const Text('用于重跑解析与排查导入问题'),
                              value: enabled,
                              onChanged: (value) async {
                                final settings = await ref.read(
                                  settingsRepositoryProvider.future,
                                );
                                await settings.setSaveImportSnapshots(value);
                                ref.invalidate(importSnapshotEnabledProvider);
                              },
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stackTrace) => Text('设置加载失败：$error'),
                          ),
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.palette_outlined,
                              color: SeekUColors.cquBlue,
                            ),
                            title: Text('外观'),
                            subtitle: Text('CQU 蓝白 · 跟随系统'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '重庆大学默认节次表',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('alpha 内置默认时间，可按实际校历手动修正。'),
                      const SizedBox(height: 16),
                      Expanded(
                        child: timeSlotsAsync.when(
                          data: (slots) => ListView.separated(
                            itemCount: slots.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final slot = slots[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: SeekUColors.sky,
                                  foregroundColor: SeekUColors.cquBlue,
                                  child: Text('${slot.section}'),
                                ),
                                title: Text('第 ${slot.section} 节'),
                                subtitle: Text(
                                  '${slot.startTime} - ${slot.endTime} · ${slot.profileName}',
                                ),
                                trailing: IconButton(
                                  tooltip: '编辑节次',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _editSlot(context, ref, slot),
                                ),
                              );
                            },
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) =>
                              Center(child: Text('节次加载失败：$error')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSlot(
    BuildContext context,
    WidgetRef ref,
    TimeSlot slot,
  ) async {
    final startController = TextEditingController(text: slot.startTime);
    final endController = TextEditingController(text: slot.endTime);
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑第 ${slot.section} 节'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: '开始时间 HH:mm'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: '结束时间 HH:mm'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              slot.copyWith(
                startTime: startController.text.trim(),
                endTime: endController.text.trim(),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    startController.dispose();
    endController.dispose();
    if (result == null) {
      return;
    }
    await ref.read(scheduleRepositoryProvider).updateTimeSlot(result);
    ref.invalidate(timeSlotsProvider);
  }
}
