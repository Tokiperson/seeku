import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import 'app_exit_stub.dart' if (dart.library.io) 'app_exit_io.dart';
import 'router.dart';
import 'theme.dart';

class UserAgreementGate extends ConsumerStatefulWidget {
  const UserAgreementGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UserAgreementGate> createState() => _UserAgreementGateState();
}

class _UserAgreementGateState extends ConsumerState<UserAgreementGate> {
  bool _dialogScheduled = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    settingsAsync.whenData((settings) {
      if (settings.userAgreementAccepted || _dialogScheduled) {
        return;
      }
      _dialogScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAgreementDialog();
        }
      });
    });
    return widget.child;
  }

  Future<void> _showAgreementDialog() async {
    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) {
      _dialogScheduled = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final accepted = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => const _UserAgreementDialog(),
    );
    if (accepted == true) {
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.acceptUserAgreement();
      ref.invalidate(settingsRepositoryProvider);
      return;
    }
    await _exitApplication();
  }

  Future<void> _exitApplication() => exitSeekUApplication();
}

class _UserAgreementDialog extends StatelessWidget {
  const _UserAgreementDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Row(
                children: const [
                  Icon(Icons.article_outlined, color: SeekUColors.cquBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SeekU 用户协议',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString('docs/User_Agreement.md'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('用户协议加载失败：${snapshot.error}'));
                  }
                  return Markdown(
                    data: snapshot.data ?? '',
                    selectable: true,
                    padding: const EdgeInsets.all(24),
                    styleSheet: _agreementStyle(context),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消并退出'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_outlined),
                    label: const Text('同意并继续'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _agreementStyle(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      h1: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: SeekUColors.text,
      ),
      h2: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: SeekUColors.text,
      ),
      p: const TextStyle(fontSize: 14, height: 1.62, color: SeekUColors.text),
      listBullet: const TextStyle(fontSize: 14, color: SeekUColors.text),
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
    );
  }
}
