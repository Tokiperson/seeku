import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/import_models.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  ImportPreviewSession? _session;
  List<ImportPreviewItem> _items = const [];
  List<String> _warnings = const [];
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(importBatchesProvider);
    final snapshotAsync = ref.watch(importSnapshotEnabledProvider);
    final semesterAsync = ref.watch(currentSemesterProvider);
    final selectedCount = _items.where((item) => item.selected).length;
    final importableCount = _items.where((item) => item.canImport).length;
    final conflictCount = _items.where((item) => item.hasConflicts).length;

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
              width: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImportSourcePanel(
                    busy: _busy,
                    snapshotAsync: snapshotAsync,
                    semesterAsync: semesterAsync,
                    onPick: () => _pickExcel(context),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _BatchHistoryPanel(batchesAsync: batchesAsync),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '导入预览',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (_items.isNotEmpty) ...[
                            Text(
                              '$selectedCount / $importableCount 已选择',
                              style: const TextStyle(color: SeekUColors.muted),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _selectCleanItems,
                              icon: const Icon(Icons.done_all_outlined),
                              label: const Text('仅无冲突'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _busy || selectedCount == 0
                                  ? null
                                  : _confirmImport,
                              icon: const Icon(Icons.download_done_outlined),
                              label: const Text('确认导入'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _session == null
                            ? '选择 Excel / CSV 后会在这里显示课程草稿、校验结果和冲突提示。'
                            : '批次 #${_session!.batch.id} · ${_items.length} 条草稿 · $conflictCount 条冲突',
                        style: const TextStyle(color: SeekUColors.muted),
                      ),
                      if (_warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _WarningsView(warnings: _warnings),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: _busy
                            ? const Center(child: CircularProgressIndicator())
                            : _PreviewList(
                                items: _items,
                                onChanged: _updateItemSelection,
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

  Future<void> _pickExcel(BuildContext context) async {
    if (kIsWeb) {
      _showMessage('当前 Web 预览版仅支持 Windows/Android 导入');
      return;
    }
    final semester = await ref.read(currentSemesterProvider.future);
    if (semester == null) {
      _showMessage('请先创建学期');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final saveSnapshot = await ref.read(importSnapshotEnabledProvider.future);
      final existingEntries = await ref.read(
        currentSemesterEntriesProvider.future,
      );
      final session = await ref
          .read(importRepositoryProvider)
          .createExcelPreview(
            path: path,
            saveSnapshot: saveSnapshot,
            semester: semester,
            existingEntries: existingEntries,
          );
      setState(() {
        _session = session;
        _items = session.result.items;
        _warnings = session.result.warnings;
      });
      ref.invalidate(importBatchesProvider);
      _showMessage('已生成导入预览');
    } on Object catch (error) {
      setState(() {
        _session = null;
        _items = const [];
        _warnings = ['解析失败：$error'];
      });
      ref.invalidate(importBatchesProvider);
      _showMessage('解析失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmImport() async {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final count = await ref
          .read(importRepositoryProvider)
          .confirmImport(batchId: session.batch.id, items: _items);
      ref.invalidate(currentSemesterEntriesProvider);
      ref.invalidate(importBatchesProvider);
      setState(() {
        _session = null;
        _items = const [];
        _warnings = const [];
      });
      _showMessage('已导入 $count 门课程');
    } on Object catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _selectCleanItems() {
    setState(() {
      _items = _items
          .map(
            (item) =>
                item.copyWith(selected: item.canImport && !item.hasConflicts),
          )
          .toList(growable: false);
    });
  }

  void _updateItemSelection(int index, bool selected) {
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          i == index ? _items[i].copyWith(selected: selected) : _items[i],
      ];
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImportSourcePanel extends StatelessWidget {
  const _ImportSourcePanel({
    required this.busy,
    required this.snapshotAsync,
    required this.semesterAsync,
    required this.onPick,
  });

  final bool busy;
  final AsyncValue<bool> snapshotAsync;
  final AsyncValue<Object?> semesterAsync;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.upload_file_outlined,
              size: 34,
              color: SeekUColors.cquBlue,
            ),
            const SizedBox(height: 14),
            const Text(
              'Excel / CSV 导入',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持 CQU 课表矩阵样例，按课程草稿预览后再写入本地课表。',
              style: TextStyle(color: SeekUColors.muted),
            ),
            const SizedBox(height: 16),
            snapshotAsync.when(
              data: (enabled) => _InfoLine(
                icon: Icons.archive_outlined,
                text: enabled ? '将保存导入原始文件副本' : '不保存导入原始文件副本',
                color: enabled ? SeekUColors.success : SeekUColors.muted,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('读取设置失败：$error'),
            ),
            const SizedBox(height: 8),
            semesterAsync.when(
              data: (semester) => _InfoLine(
                icon: Icons.school_outlined,
                text: semester == null ? '尚未创建学期' : '导入到当前学期',
                color: semester == null
                    ? SeekUColors.warning
                    : SeekUColors.cquBlue,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('学期加载失败：$error'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onPick,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('选择文件'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _BatchHistoryPanel extends StatelessWidget {
  const _BatchHistoryPanel({required this.batchesAsync});

  final AsyncValue<List<ImportBatch>> batchesAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '导入批次',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: batchesAsync.when(
                data: (batches) {
                  if (batches.isEmpty) {
                    return const Center(child: Text('尚未创建导入批次'));
                  }
                  return ListView.separated(
                    itemCount: batches.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.description_outlined,
                          color: SeekUColors.cquBlue,
                        ),
                        title: Text('批次 #${batch.id}'),
                        subtitle: Text(
                          '${batch.sourceType} · ${_statusText(batch.status)}',
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('加载失败：$error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(String status) {
    return switch (status) {
      'previewReady' => '等待确认',
      'imported' => '已导入',
      'failed' => '解析失败',
      _ => '等待解析',
    };
  }
}

class _WarningsView extends StatelessWidget {
  const _WarningsView({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SeekUColors.warningSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SeekUColors.warningBorder),
      ),
      child: Text(
        warnings.take(4).join('\n') +
            (warnings.length > 4 ? '\n还有 ${warnings.length - 4} 条提示' : ''),
        style: const TextStyle(color: SeekUColors.text, fontSize: 13),
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.items, required this.onChanged});

  final List<ImportPreviewItem> items;
  final void Function(int index, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无预览内容'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final draft = item.draft;
        final hasErrors = !item.validation.isValid;
        final borderColor = hasErrors
            ? SeekUColors.danger
            : item.hasConflicts
            ? SeekUColors.warning
            : SeekUColors.border;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: CheckboxListTile(
            value: item.selected,
            onChanged: item.canImport
                ? (value) => onChanged(index, value ?? false)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              draft.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '周${draft.weekday} · ${draft.startSection}-${draft.endSection} 节 · ${draft.weekExpression} · ${draft.classroom ?? '未填教室'}',
                  ),
                  if (hasErrors) ...[
                    const SizedBox(height: 4),
                    Text(
                      '校验失败：${item.validation.errors.join('；')}',
                      style: const TextStyle(color: SeekUColors.danger),
                    ),
                  ],
                  if (item.hasConflicts) ...[
                    const SizedBox(height: 4),
                    Text(
                      '冲突：${item.conflicts.map((c) => c.existingEntry.course.name).join('、')}',
                      style: const TextStyle(color: SeekUColors.warningText),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
