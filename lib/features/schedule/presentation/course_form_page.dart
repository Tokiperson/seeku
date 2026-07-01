import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/rules/schedule_rules.dart';
import '../../import/domain/import_models.dart';
import '../domain/schedule_models.dart';

class CourseFormPage extends ConsumerStatefulWidget {
  const CourseFormPage({super.key, this.courseId});

  final int? courseId;

  @override
  ConsumerState<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends ConsumerState<CourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();
  final _campusController = TextEditingController();
  final _weekExpressionController = TextEditingController(text: '[1-16周]');
  final _startSectionController = TextEditingController(text: '1');
  final _endSectionController = TextEditingController(text: '2');
  final _noteController = TextEditingController();
  Future<CourseEntry?>? _entryFuture;
  bool _loaded = false;
  int _weekday = 1;

  bool get _isEditing => widget.courseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _entryFuture = Future.microtask(
        () => ref
            .read(scheduleRepositoryProvider)
            .getEntryByCourseId(widget.courseId!),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _campusController.dispose();
    _weekExpressionController.dispose();
    _startSectionController.dispose();
    _endSectionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entryFuture != null) {
      return FutureBuilder<CourseEntry?>(
        future: _entryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final entry = snapshot.data;
          if (entry == null) {
            return const Scaffold(body: Center(child: Text('未找到课程')));
          }
          _loadEntry(entry);
          return _buildScaffold(context);
        },
      );
    }
    return _buildScaffold(context);
  }

  void _loadEntry(CourseEntry entry) {
    if (_loaded) {
      return;
    }
    _loaded = true;
    _nameController.text = entry.course.name;
    _codeController.text = entry.course.code ?? '';
    _categoryController.text = entry.course.category ?? '';
    _teacherController.text = entry.course.teacher ?? '';
    _classroomController.text = entry.occurrence.classroom ?? '';
    _campusController.text = entry.occurrence.campus ?? '';
    _weekExpressionController.text = entry.occurrence.weekExpression;
    _startSectionController.text = entry.occurrence.startSection.toString();
    _endSectionController.text = entry.occurrence.endSection.toString();
    _noteController.text = entry.course.note ?? '';
    _weekday = entry.occurrence.weekday;
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑课程' : '新增课程'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      '课程信息',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '课程名'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? '请输入课程名'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(_codeController, '课程代码')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_categoryController, '分类')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(_teacherController, '教师')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_classroomController, '教室')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_campusController, '校区')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '上课时间',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _weekday,
                      decoration: const InputDecoration(labelText: '星期'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('周一')),
                        DropdownMenuItem(value: 2, child: Text('周二')),
                        DropdownMenuItem(value: 3, child: Text('周三')),
                        DropdownMenuItem(value: 4, child: Text('周四')),
                        DropdownMenuItem(value: 5, child: Text('周五')),
                        DropdownMenuItem(value: 6, child: Text('周六')),
                        DropdownMenuItem(value: 7, child: Text('周日')),
                      ],
                      onChanged: (value) =>
                          setState(() => _weekday = value ?? 1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_startSectionController, '开始节次'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_endSectionController, '结束节次')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_weekExpressionController, '周次表达式'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: '备注'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_isEditing ? '保存修改' : '创建课程'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final semester = await ref.read(currentSemesterProvider.future);
      if (semester == null) {
        _showMessage('请先创建学期');
        return;
      }
      final start = int.parse(_startSectionController.text.trim());
      final end = int.parse(_endSectionController.text.trim());
      final weeks = WeekExpressionParser.parse(_weekExpressionController.text);
      final draft = CourseDraft(
        semesterId: semester.id,
        name: _nameController.text.trim(),
        code: _nullable(_codeController.text),
        category: _nullable(_categoryController.text),
        teacher: _nullable(_teacherController.text),
        note: _nullable(_noteController.text),
        classroom: _nullable(_classroomController.text),
        campus: _nullable(_campusController.text),
        weekday: _weekday,
        startSection: start,
        endSection: end,
        weekExpression: _weekExpressionController.text.trim(),
        parsedWeeks: weeks,
        source: 'manual',
      );
      final validation = const ImportValidator().validate(draft);
      if (!validation.isValid) {
        _showMessage(validation.errors.join('；'));
        return;
      }
      if (_isEditing) {
        await ref
            .read(scheduleRepositoryProvider)
            .updateCourse(widget.courseId!, draft);
        _invalidateSchedule();
        if (mounted) {
          context.go('/courses/${widget.courseId}');
        }
      } else {
        await ref.read(scheduleRepositoryProvider).addCourse(draft);
        _invalidateSchedule();
        if (mounted) {
          context.go('/');
        }
      }
    } on Object catch (error) {
      _showMessage('保存失败：$error');
    }
  }

  void _invalidateSchedule() {
    ref.invalidate(currentSemesterEntriesProvider);
    ref.invalidate(currentSemesterProvider);
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
