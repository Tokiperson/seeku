import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../app/build_info.dart';
import '../../../app/theme.dart';
import '../../../app/window_controls.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../schedule/domain/schedule_models.dart';
import '../../schedule/presentation/schedule_course_colors.dart';

class _AiApiKeyCard extends ConsumerStatefulWidget {
  const _AiApiKeyCard();

  @override
  ConsumerState<_AiApiKeyCard> createState() => _AiApiKeyCardState();
}

class _AiApiKeyCardState extends ConsumerState<_AiApiKeyCard> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _loadedKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return _Panel(
      title: 'API 配置',
      icon: Icons.key_outlined,
      child: settingsAsync.when(
        data: (settings) {
          final currentKey = settings.aiApiKey ?? '';
          if (_loadedKey != currentKey) {
            _loadedKey = currentKey;
            _controller.text = currentKey;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '默认使用你填写的本地 Key；未配置时可使用 5 天内置试用。',
                style: TextStyle(color: SeekUColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Moonshot / Kimi API Key',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? '显示' : '隐藏',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _save(settings),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('保存 Key'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: '清空 Key',
                    onPressed: () => _clear(settings),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text('AI 设置加载失败：$error'),
      ),
    );
  }

  Future<void> _save(SettingsRepository settings) async {
    await settings.setAiApiKey(_controller.text);
    ref.invalidate(aiApiKeyConfiguredProvider);
    ref.invalidate(settingsRepositoryProvider);
    await ref.read(aiCoreControllerProvider.notifier).checkCore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI API Key 已保存'), showCloseIcon: true),
    );
  }

  Future<void> _clear(SettingsRepository settings) async {
    await settings.clearAiApiKey();
    _controller.clear();
    ref.invalidate(aiApiKeyConfiguredProvider);
    ref.invalidate(settingsRepositoryProvider);
    await ref.read(aiCoreControllerProvider.notifier).checkCore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI API Key 已清空'), showCloseIcon: true),
    );
  }
}

enum _SettingsSection { schedule, semesters, global, about }

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  _SettingsSection _selected = _SettingsSection.schedule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: seekuSupportsDesktopWindowControls
          ? null
          : AppBar(
              title: const Text('设置'),
              leading: IconButton(
                tooltip: '返回课表',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
      body: Column(
        children: [
          if (seekuSupportsDesktopWindowControls)
            DesktopWindowTitleBar(title: '设置', onBack: () => context.go('/')),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return _MobileSettingsMenu(onOpen: _openMobileSection);
                }
                return Row(
                  children: [
                    _SettingsMenu(
                      selected: _selected,
                      onSelected: (section) =>
                          setState(() => _selected = section),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _SectionBody(section: _selected)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openMobileSection(_SettingsSection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(_sectionLabel(section))),
          body: _SectionBody(section: section),
        ),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({required this.selected, required this.onSelected});

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Text(
              '设置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          for (final section in _SettingsSection.values)
            _MenuTile(
              section: section,
              selected: selected == section,
              onTap: () => onSelected(section),
            ),
        ],
      ),
    );
  }
}

class _MobileSettingsMenu extends StatelessWidget {
  const _MobileSettingsMenu({required this.onOpen});

  final ValueChanged<_SettingsSection> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final section in _SettingsSection.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: SeekUColors.border),
              ),
              leading: Icon(_sectionIcon(section), color: SeekUColors.cquBlue),
              title: Text(_sectionLabel(section)),
              subtitle: Text(_sectionDescription(section)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(section),
            ),
          ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: SeekUColors.sky,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(_sectionIcon(section)),
        title: Text(_sectionLabel(section)),
        subtitle: Text(_sectionDescription(section)),
        onTap: onTap,
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      _SettingsSection.schedule => const _ScheduleSettingsView(),
      _SettingsSection.semesters => const _SemesterManagementView(),
      _SettingsSection.global => const _GlobalSettingsView(),
      _SettingsSection.about => const _AboutView(),
    };
  }
}

class _ScheduleSettingsView extends ConsumerWidget {
  const _ScheduleSettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    return settingsAsync.when(
      data: (settings) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Panel(
            title: '课表设置',
            icon: Icons.calendar_month_outlined,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: settings.visibleSectionCount,
                  decoration: const InputDecoration(
                    labelText: '节次数量',
                    prefixIcon: Icon(Icons.view_agenda_outlined),
                  ),
                  items: [
                    for (var section = 1; section <= 13; section++)
                      DropdownMenuItem(
                        value: section,
                        child: Text('$section 节'),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setVisibleSectionCount(value);
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.visibility_outlined),
                  title: const Text('显示非本周课程'),
                  subtitle: const Text('非本周课程会在课表中淡化显示'),
                  value: settings.showOffWeekCourses,
                  onChanged: (value) async {
                    await settings.setShowOffWeekCourses(value);
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: '时间设置',
            icon: Icons.schedule_outlined,
            child: timeSlotsAsync.when(
              data: (slots) => Column(
                children: [for (final slot in slots) _TimeSlotTile(slot: slot)],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('节次加载失败：$error'),
            ),
          ),
          const SizedBox(height: 16),
          const _CourseColorPanel(),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('设置加载失败：$error')),
    );
  }
}

class _TimeSlotTile extends ConsumerWidget {
  const _TimeSlotTile({required this.slot});

  final TimeSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        onPressed: () => _editSlot(context, ref, slot),
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
    if (result == null) return;
    await ref.read(scheduleRepositoryProvider).updateTimeSlot(result);
    ref.invalidate(timeSlotsProvider);
  }
}

class _CourseColorPanel extends ConsumerWidget {
  const _CourseColorPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final entriesAsync = ref.watch(currentSemesterEntriesProvider);
    return _Panel(
      title: '课表颜色管理',
      icon: Icons.palette_outlined,
      trailing: settingsAsync.maybeWhen(
        data: (settings) => TextButton.icon(
          onPressed: () async {
            await settings.clearAllCourseColorOverrides();
            ref.invalidate(settingsRepositoryProvider);
          },
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('全部自动'),
        ),
        orElse: () => null,
      ),
      child: settingsAsync.when(
        data: (settings) => entriesAsync.when(
          data: (entries) {
            final courseNames =
                entries.map((entry) => entry.course.name).toSet().toList()
                  ..sort();
            if (courseNames.isEmpty) {
              return const Text('当前学期暂无课程');
            }
            return Column(
              children: [
                for (final courseName in courseNames)
                  _CourseColorTile(courseName: courseName, settings: settings),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text('课程加载失败：$error'),
        ),
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text('设置加载失败：$error'),
      ),
    );
  }
}

class _CourseColorTile extends ConsumerWidget {
  const _CourseColorTile({required this.courseName, required this.settings});

  final String courseName;
  final SettingsRepository settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = CourseColorPalette.colorForCourse(
      courseName,
      settings.courseColorOverrides,
    );
    final custom = settings.courseColorOverrides.containsKey(courseName);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SeekUColors.border),
        ),
      ),
      title: Text(courseName),
      subtitle: Text(custom ? '自定义颜色' : '自动稳定颜色'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<Color>(
            tooltip: '选择颜色',
            icon: const Icon(Icons.color_lens_outlined),
            onSelected: (value) async {
              await settings.setCourseColorOverride(
                courseName,
                value.toARGB32(),
              );
              ref.invalidate(settingsRepositoryProvider);
            },
            itemBuilder: (context) => [
              for (final option in _themeColorOptions)
                PopupMenuItem(
                  value: option.color,
                  child: Row(
                    children: [
                      _ColorDot(color: option.color),
                      const SizedBox(width: 10),
                      Text(option.label),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: '恢复自动颜色',
            onPressed: custom
                ? () async {
                    await settings.clearCourseColorOverride(courseName);
                    ref.invalidate(settingsRepositoryProvider);
                  }
                : null,
            icon: const Icon(Icons.auto_fix_high_outlined),
          ),
        ],
      ),
    );
  }
}

class _SemesterManagementView extends ConsumerWidget {
  const _SemesterManagementView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Panel(
          title: '学期管理',
          icon: Icons.school_outlined,
          trailing: FilledButton.icon(
            onPressed: () => showSemesterEditor(context, ref, null),
            icon: const Icon(Icons.add_outlined),
            label: const Text('新增学期'),
          ),
          child: semestersAsync.when(
            data: (semesters) {
              if (semesters.isEmpty) return const Text('尚未创建学期');
              return Column(
                children: [
                  for (final semester in semesters)
                    _SemesterTile(semester: semester),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('学期加载失败：$error'),
          ),
        ),
      ],
    );
  }
}

class _SemesterTile extends ConsumerWidget {
  const _SemesterTile({required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        semester.isCurrent ? Icons.flag : Icons.school_outlined,
        color: semester.isCurrent ? SeekUColors.success : SeekUColors.cquBlue,
      ),
      title: Text(semester.name),
      subtitle: Text(
        '${_formatDate(semester.startsOn)} - ${_formatDate(semester.endsOn)} · ${semester.academicYear} 第 ${semester.termIndex} 学期',
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: '设为当前学期',
            onPressed: semester.isCurrent
                ? null
                : () async {
                    await ref
                        .read(scheduleRepositoryProvider)
                        .setCurrentSemester(semester.id);
                    _invalidateSemesterRefs(ref);
                  },
            icon: const Icon(Icons.flag_outlined),
          ),
          IconButton(
            tooltip: '编辑学期',
            onPressed: () => showSemesterEditor(context, ref, semester),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '删除学期',
            onPressed: () => _deleteSemester(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSemester(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学期'),
        content: Text('确认删除“${semester.name}”吗？该学期下的课程也会一起删除。'),
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
    if (confirmed != true) return;
    await ref.read(scheduleRepositoryProvider).deleteSemester(semester.id);
    _invalidateSemesterRefs(ref);
  }
}

class _GlobalSettingsView extends ConsumerWidget {
  const _GlobalSettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final snapshotAsync = ref.watch(importSnapshotEnabledProvider);
    return settingsAsync.when(
      data: (settings) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Panel(
            title: '全局设置',
            icon: Icons.tune_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('软件整体颜色'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in _themeColorOptions)
                      ChoiceChip(
                        selected:
                            settings.primaryColorValue ==
                            option.color.toARGB32(),
                        avatar: _ColorDot(color: option.color),
                        label: Text(option.label),
                        onSelected: (_) async {
                          await settings.setPrimaryColorValue(
                            option.color.toARGB32(),
                          );
                          ref.invalidate(settingsRepositoryProvider);
                        },
                      ),
                  ],
                ),
                const Divider(height: 28),
                const Text('软件语言'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: settings.languageCode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                    DropdownMenuItem(value: 'en', child: Text('English（占位）')),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setLanguageCode(value);
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
                const Divider(height: 28),
                const Text('字体大小'),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'small', label: Text('小')),
                    ButtonSegment(value: 'medium', label: Text('中')),
                    ButtonSegment(value: 'large', label: Text('大')),
                  ],
                  selected: {settings.fontSizeName},
                  onSelectionChanged: (selection) async {
                    await settings.setFontSizeName(selection.first);
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
                const Divider(height: 28),
                snapshotAsync.when(
                  data: (enabled) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.archive_outlined),
                    title: const Text('保存导入原始文件'),
                    subtitle: const Text('用于重跑解析与排查导入问题'),
                    value: enabled,
                    onChanged: (value) async {
                      await settings.setSaveImportSnapshots(value);
                      ref.invalidate(importSnapshotEnabledProvider);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('设置加载失败：$error'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _AiApiKeyCard(),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('设置加载失败：$error')),
    );
  }
}

class _AboutView extends StatelessWidget {
  const _AboutView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: const [
            Center(
              child: Image(
                image: AssetImage(
                  'flutter_logo_icon_pack/master_logo_1024.png',
                ),
                width: 132,
                height: 132,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                SeekUBuildInfo.displayVersion,
                style: TextStyle(
                  color: SeekUColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 24),
            _AboutTile(
              title: '关于SeekU',
              icon: Icons.info_outline,
              assetPath: 'docs/ABOUT.md',
              format: _DocumentFormat.markdown,
            ),
            _AboutTile(
              title: '用户协议',
              icon: Icons.article_outlined,
              assetPath: 'docs/ABOUT.md',
              format: _DocumentFormat.markdown,
              initialHeading: '当前限制',
            ),
            _AboutTile(
              title: '联系我们',
              icon: Icons.mail_outline,
              assetPath: 'docs/CONTACT.md',
              format: _DocumentFormat.markdown,
            ),
            _AboutTile(
              title: '开源协议',
              icon: Icons.balance_outlined,
              assetPath: 'LICENSE',
              format: _DocumentFormat.plainText,
            ),
          ],
        ),
      ),
    );
  }
}

enum _DocumentFormat { markdown, plainText }

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.title,
    required this.icon,
    required this.assetPath,
    required this.format,
    this.initialHeading,
  });

  final String title;
  final IconData icon;
  final String assetPath;
  final _DocumentFormat format;
  final String? initialHeading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _DocumentReaderPage(
            title: title,
            assetPath: assetPath,
            format: format,
            initialHeading: initialHeading,
          ),
        ),
      ),
    );
  }
}

class _DocumentReaderPage extends StatelessWidget {
  const _DocumentReaderPage({
    required this.title,
    required this.assetPath,
    required this.format,
    this.initialHeading,
  });

  final String title;
  final String assetPath;
  final _DocumentFormat format;
  final String? initialHeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('文档加载失败：${snapshot.error}'));
          }
          final data = _normalizeDocument(snapshot.data ?? '');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: format == _DocumentFormat.markdown
                  ? Markdown(
                      data: data,
                      selectable: true,
                      padding: const EdgeInsets.all(28),
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            h1: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: SeekUColors.text,
                            ),
                            h2: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: SeekUColors.text,
                            ),
                            p: const TextStyle(
                              fontSize: 14,
                              height: 1.65,
                              color: SeekUColors.text,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: SeekUColors.sky,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: SeekUColors.border),
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: SeekUColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: SeekUColors.border),
                            ),
                          ),
                    )
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: SelectableText(
                          data,
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 13,
                            height: 1.45,
                            color: SeekUColors.text,
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  String _normalizeDocument(String value) {
    final heading = initialHeading;
    if (heading == null || heading.isEmpty) {
      return value;
    }
    final marker = '## $heading';
    final index = value.indexOf(marker);
    if (index < 0) {
      return value;
    }
    return '# $title\n\n${value.substring(index)}';
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SeekUColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SeekUColors.cquBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ...trailing == null ? const <Widget>[] : [trailing!],
            ],
          ),
          const SizedBox(height: 16),
          Material(color: Colors.transparent, child: child),
        ],
      ),
    );
  }
}

class _ThemeColorOption {
  const _ThemeColorOption(this.label, this.color);

  final String label;
  final Color color;
}

const _themeColorOptions = [
  _ThemeColorOption('CQU 蓝', SeekUColors.cquBlue),
  _ThemeColorOption('湖绿', Color(0xFF1E7D6E)),
  _ThemeColorOption('松石', Color(0xFF247BA0)),
  _ThemeColorOption('梅红', Color(0xFFB03A5B)),
  _ThemeColorOption('石墨', Color(0xFF425466)),
];

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: SeekUColors.border),
      ),
    );
  }
}

Future<void> showSemesterEditor(
  BuildContext context,
  WidgetRef ref,
  Semester? semester,
) async {
  final now = DateTime.now();
  final defaultStart = DateTime(now.year, now.month, now.day);
  final nameController = TextEditingController(text: semester?.name ?? '');
  final yearController = TextEditingController(
    text: semester?.academicYear ?? '2025-2026',
  );
  final termController = TextEditingController(
    text: (semester?.termIndex ?? 2).toString(),
  );
  final startController = TextEditingController(
    text: _formatDate(semester?.startsOn ?? defaultStart),
  );
  final endController = TextEditingController(
    text: _formatDate(
      semester?.endsOn ?? defaultStart.add(const Duration(days: 139)),
    ),
  );
  final result = await showDialog<Semester>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(semester == null ? '新增学期' : '编辑学期'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '学期名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(labelText: '学年，例如 2025-2026'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: termController,
              decoration: const InputDecoration(labelText: '学期序号，例如 1 或 2'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: '开始日期 yyyy-mm-dd'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: '结束日期 yyyy-mm-dd'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final startsOn = DateTime.tryParse(startController.text.trim());
            final endsOn = DateTime.tryParse(endController.text.trim());
            final termIndex = int.tryParse(termController.text.trim());
            if (nameController.text.trim().isEmpty ||
                startsOn == null ||
                endsOn == null ||
                termIndex == null ||
                endsOn.isBefore(startsOn)) {
              return;
            }
            Navigator.of(context).pop(
              Semester(
                id: semester?.id ?? 0,
                name: nameController.text.trim(),
                academicYear: yearController.text.trim(),
                termIndex: termIndex,
                startsOn: startsOn,
                endsOn: endsOn,
                isCurrent: semester?.isCurrent ?? true,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
  nameController.dispose();
  yearController.dispose();
  termController.dispose();
  startController.dispose();
  endController.dispose();
  if (result == null) return;
  if (semester == null) {
    await ref.read(scheduleRepositoryProvider).createSemester(result);
  } else {
    await ref.read(scheduleRepositoryProvider).updateSemester(result);
  }
  _invalidateSemesterRefs(ref);
}

void _invalidateSemesterRefs(WidgetRef ref) {
  ref.invalidate(semestersProvider);
  ref.invalidate(currentSemesterProvider);
  ref.invalidate(currentSemesterEntriesProvider);
}

String _formatDate(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String _sectionLabel(_SettingsSection section) {
  return switch (section) {
    _SettingsSection.schedule => '课表设置',
    _SettingsSection.semesters => '学期管理',
    _SettingsSection.global => '全局设置',
    _SettingsSection.about => '关于软件',
  };
}

String _sectionDescription(_SettingsSection section) {
  return switch (section) {
    _SettingsSection.schedule => '节次、时间、颜色和非本周课程',
    _SettingsSection.semesters => '日期、新增、删除和当前学期',
    _SettingsSection.global => '颜色、API、语言和字体大小',
    _SettingsSection.about => '版本、协议和联系方式',
  };
}

IconData _sectionIcon(_SettingsSection section) {
  return switch (section) {
    _SettingsSection.schedule => Icons.calendar_month_outlined,
    _SettingsSection.semesters => Icons.school_outlined,
    _SettingsSection.global => Icons.tune_outlined,
    _SettingsSection.about => Icons.info_outline,
  };
}
