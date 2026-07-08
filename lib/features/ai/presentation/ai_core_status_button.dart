import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/ai_core_models.dart';

class AiCoreStatusButton extends ConsumerStatefulWidget {
  const AiCoreStatusButton({super.key});

  @override
  ConsumerState<AiCoreStatusButton> createState() => _AiCoreStatusButtonState();
}

class _AiCoreStatusButtonState extends ConsumerState<AiCoreStatusButton> {
  static bool _startupDialogShown = false;
  bool _startupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupCheck());
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(aiCoreControllerProvider);
    final active = snapshot.status == AiCoreStatus.connected;
    final checking = snapshot.status == AiCoreStatus.checking;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(28),
      color: active ? SeekUColors.success : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: checking ? null : () => _manualCheck(),
        child: Container(
          constraints: const BoxConstraints(minWidth: 156),
          height: 56,
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon(snapshot.status),
                color: active ? Colors.white : _statusColor(snapshot.status),
              ),
              const SizedBox(width: 8),
              Text(
                _label(snapshot.status),
                style: TextStyle(
                  color: active ? Colors.white : SeekUColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: active,
                onChanged: checking ? null : (_) => _manualCheck(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runStartupCheck() async {
    if (_startupChecked || !mounted) {
      return;
    }
    _startupChecked = true;
    final snapshot = await ref
        .read(aiCoreControllerProvider.notifier)
        .checkCore();
    if (!mounted) {
      return;
    }
    if (snapshot.usingUserKey) {
      _showStatusSnack(snapshot.message);
      return;
    }
    if (_startupDialogShown) {
      return;
    }
    _startupDialogShown = true;
    await _showConfigurationDialog(snapshot);
  }

  Future<void> _manualCheck() async {
    final snapshot = await ref
        .read(aiCoreControllerProvider.notifier)
        .checkCore();
    if (!mounted) {
      return;
    }
    if (snapshot.usingUserKey) {
      _showStatusSnack(snapshot.message);
    } else {
      await _showConfigurationDialog(snapshot);
    }
  }

  Future<void> _showConfigurationDialog(AiCoreSnapshot snapshot) async {
    final trialAllowed = snapshot.builtInTrialAllowed;
    final title = snapshot.status == AiCoreStatus.trialExpired
        ? 'AI API Key 未配置'
        : '配置 AI API Key';
    final content = snapshot.status == AiCoreStatus.trialExpired
        ? 'AI核心已断开。内置 API Key 试用已满 5 天，请配置自己的 API Key 后继续使用 AI 功能。'
        : '尚未配置 AI API Key。你可以前往设置填写自己的 Key；暂不配置时，可免费使用内置 API Key ${snapshot.trialRemainingDays} 天。每次启动仅提醒一次。';
    final action = await showDialog<_AiStartupAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_AiStartupAction.cancel),
            child: const Text('稍后'),
          ),
          if (trialAllowed)
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_AiStartupAction.trial),
              child: const Text('使用内置试用'),
            ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_AiStartupAction.configure),
            child: const Text('去配置'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    switch (action) {
      case _AiStartupAction.configure:
        context.go('/settings');
      case _AiStartupAction.trial:
        _showStatusSnack(
          '已启用内置 API Key 试用，还剩 ${snapshot.trialRemainingDays} 天',
        );
      case _AiStartupAction.cancel:
      case null:
        break;
    }
  }

  void _showStatusSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_compact(message)), showCloseIcon: true),
    );
  }

  String _compact(String message) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160)}...';
  }

  String _label(AiCoreStatus status) {
    return switch (status) {
      AiCoreStatus.connected => 'AI在线',
      AiCoreStatus.checking => '检测中',
      AiCoreStatus.disconnected => 'AI断开',
      AiCoreStatus.trialExpired => '试用到期',
      AiCoreStatus.missingConfig => 'AI未配置',
      AiCoreStatus.trialAvailable => '试用可用',
      AiCoreStatus.unknown => 'AI检测',
    };
  }

  IconData _icon(AiCoreStatus status) {
    return switch (status) {
      AiCoreStatus.connected => Icons.cloud_done_outlined,
      AiCoreStatus.checking => Icons.sync_outlined,
      AiCoreStatus.disconnected => Icons.cloud_off_outlined,
      AiCoreStatus.trialExpired => Icons.lock_clock_outlined,
      AiCoreStatus.missingConfig => Icons.key_off_outlined,
      AiCoreStatus.trialAvailable => Icons.schedule_outlined,
      AiCoreStatus.unknown => Icons.auto_awesome_outlined,
    };
  }

  Color _statusColor(AiCoreStatus status) {
    return switch (status) {
      AiCoreStatus.connected => SeekUColors.success,
      AiCoreStatus.checking => SeekUColors.cquBlue,
      AiCoreStatus.disconnected => SeekUColors.danger,
      AiCoreStatus.trialExpired => SeekUColors.danger,
      AiCoreStatus.missingConfig => SeekUColors.warningText,
      AiCoreStatus.trialAvailable => SeekUColors.warningText,
      AiCoreStatus.unknown => SeekUColors.cquBlue,
    };
  }
}

enum _AiStartupAction { configure, trial, cancel }
