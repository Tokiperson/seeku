import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';

class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(importBatchesProvider);
    final snapshotAsync = ref.watch(importSnapshotEnabledProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
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
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.upload_file_outlined,
                        size: 36,
                        color: SeekUColors.cquBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Excel 导入',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'v0.1alpha 先创建导入批次和预览占位。真实字段解析会在拿到脱敏样例后实现。',
                        style: TextStyle(color: SeekUColors.muted),
                      ),
                      const SizedBox(height: 20),
                      snapshotAsync.when(
                        data: (enabled) => Row(
                          children: [
                            Icon(
                              enabled
                                  ? Icons.archive_outlined
                                  : Icons.archive_outlined,
                              color: enabled
                                  ? SeekUColors.success
                                  : SeekUColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                enabled ? '将保存导入原始文件副本' : '不保存导入原始文件副本',
                              ),
                            ),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => Text('读取设置失败：$error'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _pickExcel(context, ref),
                          icon: const Icon(Icons.folder_open_outlined),
                          label: const Text('选择 Excel / CSV'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '导入预览',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('当前阶段用于确认导入批次与快照路径。课程草稿预览等待样例格式适配。'),
                      const SizedBox(height: 16),
                      Expanded(
                        child: batchesAsync.when(
                          data: (batches) {
                            if (batches.isEmpty) {
                              return const Center(child: Text('尚未创建导入批次'));
                            }
                            return ListView.separated(
                              itemCount: batches.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final batch = batches[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.description_outlined,
                                    color: SeekUColors.cquBlue,
                                  ),
                                  title: Text(
                                    '批次 #${batch.id} · ${batch.sourceType}',
                                  ),
                                  subtitle: Text(
                                    '状态：等待样例格式适配\n快照：${batch.rawSnapshotPath ?? '未保存'}',
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) =>
                              Center(child: Text('导入批次加载失败：$error')),
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

  Future<void> _pickExcel(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    final saveSnapshot = await ref.read(importSnapshotEnabledProvider.future);
    await ref
        .read(importRepositoryProvider)
        .createExcelBatch(file: File(path), saveSnapshot: saveSnapshot);
    ref.invalidate(importBatchesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已创建导入批次，等待样例格式适配')));
    }
  }
}
