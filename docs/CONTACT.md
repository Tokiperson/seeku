# 联系我们

感谢你关注 SeekU。SeekU 是一个面向重庆大学学生课表场景的开源项目，欢迎反馈问题、建议功能或参与贡献。

## 下载软件

普通用户推荐从 GitHub Releases 下载 Windows 安装包：

- 下载页面：[SeekU Releases](https://github.com/Tokiperson/seeku/releases)
- 当前推荐版本：`v0.1.0-rc.2`
- 安装包命名：`SeekU-v0.1.0-rc.2-setup.exe`

如果 Releases 中暂未看到目标安装包，说明该版本安装包可能仍在发布准备中；开发者可参考 README 从源码运行或构建。

## 反馈问题

如果你遇到以下情况，建议通过项目仓库提交 Issue：

- 课表显示异常。
- Excel / CSV / PDF / 图片导入解析错误。
- AI 识别结果结构不正确。
- 设置、学期管理或课程编辑行为不符合预期。
- Windows 桌面端窗口、托盘或构建问题。

提交问题时，请尽量说明：

- 使用的 SeekU 版本，例如 `v0.1.0-rc.2`。
- 操作系统和 Flutter 运行环境。
- 触发问题的操作步骤。
- 期望结果与实际结果。
- 可公开的脱敏样例或截图。

请不要提交真实 API Key、完整个人课表、未脱敏截图或其他隐私数据。

## 参与贡献

建议贡献流程：

1. 先提出 Issue 或任务说明。
2. 每次变更聚焦一个功能或一个 Bug。
3. 涉及解析器、仓库或 UI 行为时，同步补充测试。
4. 提交前运行 `flutter analyze` 和 `flutter test`。
5. 不要在提交中包含密钥、私密课表或个人截图。

## 项目信息

- 项目名称：SeekU
- 维护者：Tokiperson
- 主要技术：Flutter、Dart、Riverpod、go_router、Drift / SQLite
- 开源协议：Apache License 2.0

SeekU 仍在快速迭代中，清晰、可复现、脱敏充分的反馈会非常有帮助。
