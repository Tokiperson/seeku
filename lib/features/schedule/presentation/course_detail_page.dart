import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../openlib/domain/openlib_models.dart';
import '../domain/schedule_models.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final int courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  late final Future<CourseEntry?> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = ref
        .read(scheduleRepositoryProvider)
        .getEntryByCourseId(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => context.go('/courses/${widget.courseId}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '删除课程',
                onPressed: () => _deleteCourse(context),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
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
                        _OpenlibResourceSection(course: entry.course),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCourse(BuildContext context) async {
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
    await ref.read(scheduleRepositoryProvider).deleteCourse(widget.courseId);
    ref.invalidate(currentSemesterEntriesProvider);
    if (context.mounted) {
      context.go('/');
    }
  }
}

class _OpenlibResourceSection extends ConsumerWidget {
  const _OpenlibResourceSection({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(courseOpenlibResourcesProvider(course));
    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: '相关资源链接', value: '暂未匹配到 Openlib 资源'),
              _OpenlibAttribution(),
            ],
          );
        }
        final best = resources.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResourceLinkRow(label: '相关资源链接', resource: best),
            const _OpenlibAttribution(),
            if (resources.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 96, bottom: 6),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text('展开查看全部候选结果（${resources.length}）'),
                  children: [
                    for (final resource in resources.skip(1))
                      _OpenlibCandidateTile(resource: resource),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: '相关资源链接', value: '正在检索 Openlib...'),
          _OpenlibAttribution(),
        ],
      ),
      error: (error, stackTrace) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: '相关资源链接', value: 'Openlib 检索失败'),
          _OpenlibAttribution(),
        ],
      ),
    );
  }
}

class _ResourceLinkRow extends StatelessWidget {
  const _ResourceLinkRow({required this.label, required this.resource});

  final String label;
  final LearningResource resource;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _openOpenlibResource(context, resource.url),
                icon: const Icon(Icons.open_in_browser_outlined, size: 18),
                label: Text(
                  Uri.decodeFull(resource.url.toString()),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenlibAttribution extends StatelessWidget {
  const _OpenlibAttribution();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 96, bottom: 8),
      child: Text(
        '资源来自 CQU-Openlib 检索，仅展示外部链接，不下载或搬运资源文件。',
        style: TextStyle(color: SeekUColors.muted, fontSize: 12),
      ),
    );
  }
}

class _OpenlibCandidateTile extends StatelessWidget {
  const _OpenlibCandidateTile({required this.resource});

  final LearningResource resource;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link_outlined, color: SeekUColors.cquBlue),
      title: Text(resource.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        resource.summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('${(resource.matchScore * 100).round()}%'),
      onTap: () => _openOpenlibResource(context, resource.url),
    );
  }
}

Future<void> _openOpenlibResource(BuildContext context, Uri uri) async {
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) {
      return;
    }
  } catch (_) {
    if (!context.mounted) {
      return;
    }
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('无法打开 Openlib 链接'), showCloseIcon: true),
  );
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
