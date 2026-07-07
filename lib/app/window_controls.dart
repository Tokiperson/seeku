import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'theme.dart';
import 'tray_icon_path_stub.dart' if (dart.library.io) 'tray_icon_path_io.dart';

bool get seekuSupportsDesktopWindowControls {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

bool get _supportsWindowsTray {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}

Future<void> configureSeekUDesktopWindow() async {
  if (!seekuSupportsDesktopWindowControls) {
    return;
  }

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 820),
    minimumSize: Size(960, 680),
    center: true,
    title: 'SeekU',
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  if (_supportsWindowsTray) {
    await trayManager.setIcon(await resolveTrayIconPath());
    await trayManager.setToolTip('SeekU');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: '显示 SeekU'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
  }
}

class DesktopWindowTitleBar extends StatefulWidget {
  const DesktopWindowTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  State<DesktopWindowTitleBar> createState() => _DesktopWindowTitleBarState();
}

class _DesktopWindowTitleBarState extends State<DesktopWindowTitleBar>
    with WindowListener, TrayListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (seekuSupportsDesktopWindowControls) {
      windowManager.addListener(this);
      _syncMaximized();
    }
    if (_supportsWindowsTray) {
      trayManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (seekuSupportsDesktopWindowControls) {
      windowManager.removeListener(this);
    }
    if (_supportsWindowsTray) {
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() => _syncMaximized();

  @override
  void onWindowUnmaximize() => _syncMaximized();

  @override
  void onTrayIconMouseDown() => _restoreFromTray();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      _restoreFromTray();
    } else if (menuItem.key == 'exit') {
      windowManager.close();
    }
  }

  Future<void> _syncMaximized() async {
    if (!seekuSupportsDesktopWindowControls) {
      return;
    }
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _maximized = maximized);
    }
  }

  Future<void> _restoreFromTray() async {
    if (!seekuSupportsDesktopWindowControls) {
      return;
    }
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
    await windowManager.focus();
  }

  Future<void> _minimizeToTray() async {
    if (!_supportsWindowsTray) {
      await windowManager.minimize();
      return;
    }
    await windowManager.setSkipTaskbar(true);
    await windowManager.hide();
  }

  Future<void> _toggleMaximize() async {
    if (_maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _syncMaximized();
  }

  @override
  Widget build(BuildContext context) {
    if (!seekuSupportsDesktopWindowControls) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.white,
      child: Container(
        height: 48,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: SeekUColors.border)),
        ),
        child: Row(
          children: [
            if (widget.onBack != null)
              IconButton(
                tooltip: '返回',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: SeekUColors.cquBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: SeekUColors.text,
                          ),
                        ),
                        if ((widget.subtitle ?? '').isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: SeekUColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _TitleBarButton(
              tooltip: '最小化到系统托盘',
              icon: Icons.push_pin_outlined,
              onPressed: _minimizeToTray,
            ),
            _TitleBarButton(
              tooltip: '最小化',
              icon: Icons.minimize,
              onPressed: windowManager.minimize,
            ),
            _TitleBarButton(
              tooltip: _maximized ? '还原' : '全屏',
              icon: _maximized
                  ? Icons.filter_none_outlined
                  : Icons.crop_square_outlined,
              onPressed: _toggleMaximize,
            ),
            _TitleBarButton(
              tooltip: '关闭',
              icon: Icons.close,
              danger: true,
              onPressed: windowManager.close,
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  const _TitleBarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: danger ? SeekUColors.danger : SeekUColors.muted,
        hoverColor: danger ? SeekUColors.danger.withAlpha(24) : SeekUColors.sky,
      ),
    );
  }
}
