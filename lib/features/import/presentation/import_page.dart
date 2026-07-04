import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../ai/domain/ai_models.dart';
import '../../schedule/domain/schedule_models.dart';
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
  String? _busyMessage;
  int? _selectedSemesterId;
  String? _previewSemesterName;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(importSnapshotEnabledProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final currentSemesterAsync = ref.watch(currentSemesterProvider);
    final selectedCount = _items.where((item) => item.selected).length;
    final importableCount = _items.where((item) => item.canImport).length;
    final conflictCount = _items.where((item) => item.hasConflicts).length;
    final selectedSemester = _selectedSemester(
      _asyncData(semestersAsync),
      _asyncData<Semester?>(currentSemesterAsync),
    );

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
              child: _ImportSourcePanel(
                busy: _busy,
                snapshotAsync: snapshotAsync,
                semestersAsync: semestersAsync,
                currentSemesterAsync: currentSemesterAsync,
                selectedSemester: selectedSemester,
                onSemesterChanged: (semesterId) =>
                    setState(() => _selectedSemesterId = semesterId),
                onPickExcel: () => _pickExcel(selectedSemester),
                onPickAiPdf: () =>
                    _pickAi(AiScheduleSourceType.pdf, selectedSemester),
                onPickAiImage: () =>
                    _pickAi(AiScheduleSourceType.image, selectedSemester),
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
                        _previewSummary(conflictCount),
                        style: const TextStyle(color: SeekUColors.muted),
                      ),
                      if (_warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _WarningsView(warnings: _warnings),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: _busy
                            ? _BusyView(message: _busyMessage)
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

  T? _asyncData<T>(AsyncValue<T> value) {
    return switch (value) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  Semester? _selectedSemester(List<Semester>? semesters, Semester? current) {
    if (semesters == null || semesters.isEmpty) {
      return current;
    }
    final preferredId = _selectedSemesterId ?? current?.id;
    if (preferredId != null) {
      for (final semester in semesters) {
        if (semester.id == preferredId) {
          return semester;
        }
      }
    }
    return semesters.first;
  }

  String _previewSummary(int conflictCount) {
    final session = _session;
    if (session == null) {
      return '选择 Excel / CSV、PDF 或图片后会在这里显示课程草稿、校验结果和冲突提示。';
    }
    return '${_sourceLabel(session.batch.sourceType)} · ${_previewSemesterName ?? '目标学期'} · ${_items.length} 条草稿 · $conflictCount 条冲突';
  }

  Future<void> _pickExcel(Semester? semester) async {
    await _pickAndPreview(
      semester: semester,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      aiAction: false,
      loadPreview:
          ({
            required path,
            required saveSnapshot,
            required semester,
            required existingEntries,
          }) {
            return ref
                .read(importRepositoryProvider)
                .createExcelPreview(
                  path: path,
                  saveSnapshot: saveSnapshot,
                  semester: semester,
                  existingEntries: existingEntries,
                );
          },
    );
  }

  Future<void> _pickAi(
    AiScheduleSourceType sourceType,
    Semester? semester,
  ) async {
    await _pickAndPreview(
      semester: semester,
      allowedExtensions: sourceType == AiScheduleSourceType.pdf
          ? const ['pdf']
          : const ['png', 'jpg', 'jpeg', 'webp'],
      aiAction: true,
      loadPreview:
          ({
            required path,
            required saveSnapshot,
            required semester,
            required existingEntries,
          }) {
            return ref
                .read(importRepositoryProvider)
                .createAiPreview(
                  path: path,
                  saveSnapshot: saveSnapshot,
                  sourceType: sourceType,
                  semester: semester,
                  existingEntries: existingEntries,
                );
          },
    );
  }

  Future<void> _pickAndPreview({
    required Semester? semester,
    required List<String> allowedExtensions,
    required bool aiAction,
    required Future<ImportPreviewSession> Function({
      required String path,
      required bool saveSnapshot,
      required Semester semester,
      required Iterable<CourseEntry> existingEntries,
    })
    loadPreview,
  }) async {
    if (kIsWeb) {
      _showMessage('当前 Web 预览版仅支持 Windows/Android 导入');
      return;
    }
    if (semester == null) {
      _showMessage('请先创建或选择学期');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() {
      _busy = true;
      _busyMessage = aiAction
          ? 'AI正在识别课表，PDF会先上传并抽取文本，可能需要1-2分钟。'
          : '正在解析文件...';
    });
    try {
      final saveSnapshot = await ref.read(importSnapshotEnabledProvider.future);
      final existingEntries = await ref
          .read(scheduleRepositoryProvider)
          .getEntriesForSemester(semester.id);
      final session = await loadPreview(
        path: path,
        saveSnapshot: saveSnapshot,
        semester: semester,
        existingEntries: existingEntries,
      );
      setState(() {
        _session = session;
        _items = session.result.items;
        _warnings = session.result.warnings;
        _previewSemesterName = semester.name;
        _busyMessage = null;
      });
      ref.invalidate(importBatchesProvider);
      _showMessage(aiAction ? 'AI执行完成：已生成导入预览' : '已生成导入预览');
    } on Object catch (error) {
      setState(() {
        _session = null;
        _items = const [];
        _warnings = ['解析失败：$error'];
        _previewSemesterName = null;
        _busyMessage = null;
      });
      ref.invalidate(importBatchesProvider);
      _showMessage('解析失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  Future<void> _confirmImport() async {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _busyMessage = '正在导入课程...';
    });
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
        _previewSemesterName = null;
        _busyMessage = null;
      });
      _showMessage('已导入 $count 门课程');
    } on Object catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
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

  String _sourceLabel(String sourceType) {
    return switch (sourceType) {
      'excel' => 'Excel / CSV',
      'aiPdf' => 'AI PDF 识别',
      'aiImage' => 'AI 图片识别',
      _ => sourceType,
    };
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_compactMessage(message)), showCloseIcon: true),
    );
  }

  String _compactMessage(String message) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160)}...';
  }
}

class _ImportSourcePanel extends StatelessWidget {
  const _ImportSourcePanel({
    required this.busy,
    required this.snapshotAsync,
    required this.semestersAsync,
    required this.currentSemesterAsync,
    required this.selectedSemester,
    required this.onSemesterChanged,
    required this.onPickExcel,
    required this.onPickAiPdf,
    required this.onPickAiImage,
  });

  final bool busy;
  final AsyncValue<bool> snapshotAsync;
  final AsyncValue<List<Semester>> semestersAsync;
  final AsyncValue<Semester?> currentSemesterAsync;
  final Semester? selectedSemester;
  final ValueChanged<int?> onSemesterChanged;
  final VoidCallback onPickExcel;
  final VoidCallback onPickAiPdf;
  final VoidCallback onPickAiImage;

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
              '多源导入',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择目标学期后导入 Excel、PDF 或课表图片，确认预览后再写入本地课表。',
              style: TextStyle(color: SeekUColors.muted),
            ),
            const SizedBox(height: 16),
            semestersAsync.when(
              data: (semesters) {
                if (semesters.isEmpty) {
                  return const _InfoLine(
                    icon: Icons.school_outlined,
                    text: '尚未创建学期',
                    color: SeekUColors.warning,
                  );
                }
                return DropdownButtonFormField<int>(
                  initialValue: selectedSemester?.id,
                  decoration: const InputDecoration(
                    labelText: '导入学期',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: semesters
                      .map(
                        (semester) => DropdownMenuItem<int>(
                          value: semester.id,
                          child: Text(semester.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: busy ? null : onSemesterChanged,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('学期加载失败：$error'),
            ),
            const SizedBox(height: 12),
            currentSemesterAsync.when(
              data: (semester) => _InfoLine(
                icon: Icons.flag_outlined,
                text: semester == null ? '当前学期未设置' : '当前学期：${semester.name}',
                color: SeekUColors.muted,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('当前学期加载失败：$error'),
            ),
            const SizedBox(height: 8),
            snapshotAsync.when(
              data: (enabled) => _InfoLine(
                icon: Icons.archive_outlined,
                text: enabled ? '将保存导入原始文件副本' : '不保存导入原始文件副本',
                color: enabled ? SeekUColors.success : SeekUColors.muted,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('读取设置失败：$error'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onPickExcel,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('选择 Excel / CSV'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPickAiPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('AI 识别 PDF'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPickAiImage,
                icon: const Icon(Icons.image_search_outlined),
                label: const Text('AI 识别图片'),
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

class _BusyView extends StatelessWidget {
  const _BusyView({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          SizedBox(
            width: 360,
            child: Text(
              message ?? '正在处理...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: SeekUColors.muted),
            ),
          ),
        ],
      ),
    );
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: SingleChildScrollView(
          child: Text(
            warnings.take(4).join('\n') +
                (warnings.length > 4 ? '\n还有 ${warnings.length - 4} 条提示' : ''),
            style: const TextStyle(color: SeekUColors.text, fontSize: 13),
          ),
        ),
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
                  if ((draft.campus ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '校区：${draft.campus}',
                      style: const TextStyle(color: SeekUColors.muted),
                    ),
                  ],
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
