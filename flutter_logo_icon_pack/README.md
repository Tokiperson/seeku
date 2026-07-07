# Flutter Logo Icon Pack（透明背景版）

本包根据提供的 `master_logo_original_1254.png` 生成，已移除原图白色圆角底板与阴影背景，其余蓝色图形设计、位置比例与原始画布关系保持不变。

## 内容

- `master_logo_original_1254.png`：1254×1254 透明背景主图
- `master_logo_1024.png`：1024×1024 透明背景主图
- `android/`：Android 常规 PNG 与 adaptive icon foreground 候选尺寸
- `ios/`：iOS 常用 PNG 尺寸
- `web/`：Web favicon 与 PWA 图标尺寸
- `windows/`：Windows PNG 与 `.ico`
- `flutter_project/`：可直接替换到 Flutter 项目对应平台目录的图标文件
- `flutter_launcher_icons_config.yaml`：透明背景版本的 `flutter_launcher_icons` 参考配置

## 使用提示

### Android

将 `flutter_project/android/app/src/main/res/` 下的 `mipmap-*` 目录复制到项目的：

```text
android/app/src/main/res/
```

也可使用 `android/adaptive_icon_candidates/` 中的 foreground 文件作为 adaptive icon 前景素材。

### iOS

将：

```text
flutter_project/ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

替换到 Flutter 项目对应位置。

注意：iOS / App Store 通常要求 App Icon 为不透明图标。此包按你的要求保留透明背景，但正式上架前建议再准备一版不透明底图。

### Web

将 `flutter_project/web/favicon.png`、`flutter_project/web/icons/`、`flutter_project/web/manifest.json` 复制到 Flutter 项目的：

```text
web/
```

### Windows

将：

```text
flutter_project/windows/runner/resources/app_icon.ico
```

替换到 Flutter 项目的同名位置。

## 生成说明

所有 PNG 均由同一透明背景主图按目标尺寸缩放生成，未重新绘制或改变 logo 构图。
