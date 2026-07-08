# SeekU Planning Map

## 项目定位

SeekU 是面向重庆大学学生的智能课表与学习辅助应用。项目以 Flutter 为基础，优先建设 Windows 桌面端，先完成稳定的本地课表、导入、离线查看能力，再逐步扩展到 Android、AI 识别、CQU-Openlib 学习资源推荐与云端同步。

一句话定位：面向 CQU 学生的智能课表管理与课程学习资源助手，支持多源导入、AI 结构化识别、统一节次适配、Openlib 资源关联和离线查看。

## 已确认决策

- v0.1 优先 Windows 桌面端；Android 当前已有窄屏页面与基础 Widget 覆盖，正式发布仍放在 v0.2 以后。
- 教务入口为 `https://my.cqu.edu.cn/workspace/home`。
- 教务导入仍规划采用内置 WebView：用户自行登录并打开“我的课表”，SeekU 抓取当前页面内容后解析；当前 rc.2 尚未接入 WebView。
- v0.1 即支持多学期，课程数据必须绑定到学期。
- 离线能力优先满足查看已保存课表、课程详情、已缓存资源摘要与手动编辑。
- 学校统一节次时间表可先在代码中预设，具体时间后续开发时补充。
- AI API Key 当前采用用户本地明文配置，后续再升级为安全存储。
- 未配置用户 API Key 时，允许从首次打开软件起 5 天内使用内置 API Key 试用；达到 5 天后强制要求用户配置。
- 大模型接入优先考虑 Moonshot / Kimi，后续再扩展 DeepSeek。
- CQU-Openlib 在 v0.2 阶段先做“链接 + 摘要”，不默认下载或搬运资源文件。
- 账号体系预计 v0.3 以后上线，云同步预计 v0.5 以后上线。

## 当前状态

- 项目已从 v0.1alpha / snapshot 技术切片推进到 `v0.1.0-rc.2`（pubspec: `0.1.0-rc.2+6`）。
- 已建立 `app/`、`core/`、`features/`、`shared/` 模块化工程结构。
- 已接入 `go_router`、`flutter_riverpod`、`drift`、`shared_preferences`、`file_picker`、`path_provider`、`excel`、`pointycastle` 等依赖。
- 已实现 Windows 桌面端本地 SQLite 课表存储、默认学期、默认 CQU 节次表、课程 CRUD、导入批次与设置项；首页启动后默认展示今日所在教学周的周视图。
- 已实现 CQU 蓝白风格的周视图、日视图、课程详情、新增 / 编辑 / 删除课程、多源导入页、设置页和 Android 窄屏首页基础适配。
- 已实现 Excel / CSV 真实解析、导入学期选择、导入预览、冲突检测和确认入库闭环。
- 已初步接入 AI 核心框架：Moonshot / Kimi API 管理、PDF 文本抽取、图片视觉识别、AI 结构化课表解析、AI 核心状态检测与 API Key 配置；未配置 API Key 时每次启动软件最多弹窗提醒一次。
- 已实现导入教室到校区的自动推断：教室首字符为英文时写入大写校区，否则留空。
- 已同步 `README.md`、`ABOUT.md`、`CONTACT.md` 与用户协议到 `v0.1.0-rc.2`，README 已加入 GitHub Releases 下载导览。
- 已完成规则、数据库、导入解析、AI JSON 解析、AI 设置和 Widget smoke 测试；当前代码可通过 `flutter analyze` 与 Windows Release 构建，部分本机环境下 `flutter test` 可能在测试 shell 启动阶段断连，需继续排查。
- 已存在协作目录：`log/`、`AIUsage/`、`trash/`。
- 已创建规划目录：`docs/`，并维护 README 顶部展示图 `docs/seeku.png`。

## 核心目标

1. 建立可维护、可测试、可扩展的 Flutter 应用架构。
2. 完成课程表展示、编辑、导入预览、本地持久化与离线查看闭环。
3. 统一教务网页、Excel、PDF、截图等来源的课程数据结构。
4. 围绕重庆大学场景内置教学周、节次时间、校区与教室字段。
5. 后续接入 DeepSeek / Moonshot 与 CQU-Openlib，形成学习资源推荐和学习建议能力。

## v0.1 MVP 范围

v0.1 聚焦 Windows 桌面端和本地课表闭环：

- Windows 桌面端应用。
- 本地多学期课表。
- 周视图、日视图、当前周定位与当前课程提示。
- 手动新增、编辑、删除课程。
- 教务 WebView 导入（仍在规划，rc.2 未接入）。
- Excel 导入。
- 导入预览与冲突提示。
- 重庆大学统一节次表预设接口。
- 本地数据库持久化。
- 离线查看已保存课程。
- 基础设置页。

## v0.1alpha 技术切片

v0.1alpha 是 v0.1 的第一个可试用技术切片，目标是优先打通 Windows 本地课表闭环，而不是一次性完成 v0.1 全量能力。

已确认并实现：

- Windows 桌面端优先，版本号为 `0.1.0-alpha+1`。
- CQU 蓝白风格 UI，辅以中性色和状态色，避免界面单一蓝色。
- 模块化工程结构：`app/`、`core/`、`features/`、`shared/`。
- 本地数据库采用 Drift + SQLite；alpha 阶段通过自定义 SQL 接入，暂不引入 `.g.dart` 代码生成。
- 使用 `go_router` 管理页面路由。
- 使用 `flutter_riverpod` 管理全局状态、仓储和 UI 状态。
- 使用 `shared_preferences` 保存导入快照开关等轻量设置。
- 使用 `file_picker`、`path_provider`、`path` 支持导入文件选择与快照路径管理。
- 支持本地多学期数据结构，当前 alpha 默认创建一个当前学期。
- 支持周视图、日视图、当前日期与当前节次高亮。
- 支持课程详情查看。
- 支持手动新增、编辑、删除课程。
- 支持离线查看已保存课程。
- 支持内置 CQU 默认节次表，并在设置页中手动编辑。
- 支持导入原始文件快照开关。
- Excel 导入已从占位推进到真实解析：选择 `.xlsx`、`.xls`、`.csv` 文件，创建 `ImportBatch`，按设置决定是否保存原始文件副本，并生成可确认的课程预览。
- 已固定并复用导入管线接口：`ImportSource`、`RawImportSnapshot`、`CourseDraft`、`ImportValidator`、`ConflictDetector`。
- 已支持周次表达式与节次表达式解析测试。
- 已支持同一学期、同一周、同一天、重叠节次的冲突检测。
- 已支持从导入教室首个英文字符推断校区字段。

v0.1alpha 暂不实现：

- 教务 WebView 导入（仍在规划，rc.2 未接入）。
- Excel 真实字段解析与表格映射。
- Android 发布。
- PDF / 截图 OCR 导入。
- DeepSeek / Moonshot AI 解析。
- CQU-Openlib 智能推荐。
- 账号系统。
- 云同步。

v0.1alpha Windows 构建注意事项：

- `sqlite3` native-assets hook 已配置为使用系统库，避免构建时从 GitHub 下载预编译 DLL：

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: sqlite3
```

- Windows 运行命令：

```powershell
flutter pub get
flutter run -d windows
```

- 当前 Web 构建不可用，原因是 v0.1alpha 使用 Drift native SQLite 与 `dart:ffi`，Web 端后续如需预览应单独增加 Web Preview / Mock Repository 适配。

暂不进入 v0.1：

- Android 正式发布。
- PDF / 截图 OCR 导入。
- DeepSeek / Moonshot AI 解析。
- CQU-Openlib 智能推荐。
- 账号系统。
- 云同步。

## 功能规划

### 课程表基础能力

- 周视图课程表展示。
- 日视图课程列表展示。
- 当前周、当前日期与当前时间段高亮。
- 多学期切换。
- 课程详情查看。
- 手动新增、编辑、删除课程。
- 课程颜色、分类、备注字段预留。

### 多源导入

所有导入方式统一进入同一条导入管线：

```text
导入源
→ 原始内容快照
→ 解析器
→ 标准课程草稿
→ 规则校验
→ 冲突检测
→ 用户预览/修改
→ 写入正式课表
```

导入源规划：

- 教务网页导入：内置 WebView 打开教务网站，用户登录并进入课表页面后抓取 DOM / HTML。
- Excel 导入：读取 `.xlsx`、`.xls`、`.csv`，映射为标准课程草稿。
- AI PDF 导入：snapshot2 已通过 Moonshot / Kimi 文件上传与 `file-extract` 抽取文本，再要求模型返回固定 JSON。
- AI 图片导入：snapshot2 已通过视觉模型识别 `.png`、`.jpg`、`.jpeg`、`.webp` 课表图片，再进入导入预览。
- 手动导入：作为所有自动导入失败时的兜底能力。

### 教务网页解析

教务课表页面形态已按截图确认：

- 横向为周一到周日。
- 纵向包含一、二、三、四、五、整周等课表区块。
- 课程卡片包含课程名、课程代码或教学班编号、周次、节次、教室等信息。
- 页面可能存在“还有 N 条未展开”的折叠课程。
- 顶部存在周次筛选。
- 存在整周课程、实践课或集中周课程。

解析策略：

- 抓取前尽量自动展开所有隐藏课程。
- 优先读取完整 DOM 数据，不只依赖可见文本。
- 保存原始 HTML 快照，方便解析错误排查。
- 对周次表达式、单双周、离散周、节次跨度做独立解析器。

需支持的周次表达式：

```text
[1-16周]
[1-4,6-9,11-12周]
[2,4,6周]
[10周]
[17-19周]
```

需支持的节次表达式：

```text
[1-2节]
[3-4节]
[6-7节]
[8-9节]
[10-11节]
[10-13节]
[1-4节]
```

### Openlib 与学习建议

CQU-Openlib 是重庆大学开源资源共享计划，SeekU 在 v0.2 后接入。第一阶段只缓存资源标题、链接、摘要与匹配分数，不默认下载文件。

资源匹配优先级：

1. 课程名精确匹配。
2. 课程名去括号、去编号、去实践/实验等后缀匹配。
3. 教材名、关键词、专业方向匹配。
4. 大模型根据课程信息生成检索关键词。
5. 用户手动选择相关资源。

Openlib 模块流程：

```text
Course
→ ResourceSearchQuery
→ OpenlibResourceProvider
→ LearningResource[]
→ AI Summary / Recommendation
→ 课程详情页展示
```

### AI 能力

snapshot2 已初步接入 Moonshot / Kimi，所有模型能力必须通过统一接口调用，不直接耦合 UI。

当前已实现接口与组件：

```dart
abstract class AiApiManager {
  Future<ImportParseResult> parseScheduleImport(...);
}

abstract class ScheduleAiParser {
  Future<ImportParseResult> parseSchedule(...);
}
```

当前实现方向：

- `DefaultAiApiManager`：统一管理 AI 用途入口，后续扩展 DeepSeek 和学习建议能力。
- `MoonshotApiClient`：封装 Kimi OpenAI 兼容接口、文件上传、文件内容抽取、视觉输入和 JSON Mode。
- `MoonshotScheduleParser`：把 PDF / 图片识别结果转换为本地导入预览数据。
- `ScheduleAiJsonParser`：解析模型返回 JSON，转换为 `CourseDraft`，并执行本地校验与冲突检测。
- `AiCoreStatusButton`：主页面右下角 AI 核心状态检测与提示入口。

AI Key 策略：

- 用户可在设置页填写 Moonshot / Kimi API Key，本地明文保存。
- 启动时检测是否配置 Key；已配置则自动连接测试。
- 未配置时每次启动软件最多弹窗提醒一次，并允许从首次打开起 5 天内使用内置 API Key 试用。
- 首次打开时间间隔大于等于 5 天后，禁止进入内置 API Key 代码段。

AI 输出不能直接入库，必须进入导入预览页并经过本地规则校验与用户确认。

## 数据模型规划

v0.1 需要提前支持：

```text
Semester
- id
- name
- academicYear
- termIndex
- startsOn
- isCurrent

Course
- id
- semesterId
- name
- code
- category
- teacher
- note
- source

CourseOccurrence
- id
- courseId
- weekday
- startSection
- endSection
- classroom
- campus
- weekExpression
- parsedWeeks

TimeSlot
- id
- section
- startTime
- endTime
- profileName

ImportBatch
- id
- sourceType
- importedAt
- rawSnapshotPath
- status
```

v0.2 后补充：

```text
LearningResource
CourseResourceLink
AiAdvice
AiRequestLog
```

## 技术栈建议

v0.1：

```text
Flutter
go_router
flutter_riverpod
drift
shared_preferences
file_picker
excel
webview_windows
dio
```

v0.1alpha / snapshot2 已实际接入：

```text
Flutter
go_router
flutter_riverpod
drift
shared_preferences
file_picker
path_provider
path
excel
pointycastle
sqlite3_flutter_libs
```

snapshot2 已接入 `excel` 和 AI 所需基础能力；`webview_windows`、`dio` 暂未接入，教务 WebView 和更完整网络层后续再纳入。

v0.2 后：

```text
pdf_text / pdf_render
image_picker 或 desktop_drop
DeepSeek / Moonshot API Client
OpenlibResourceProvider
```

本地存储建议：

- `drift`：课程、学期、节次、导入批次、资源缓存、AI 建议。
- `shared_preferences`：主题、默认学期、API 配置开关等轻量设置。
- 本地文件目录：保存导入源文件副本、HTML 快照、OCR 中间结果和资源元数据缓存。

## 工程规划

### 目录结构建议

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  core/
    constants/
    errors/
    network/
    storage/
    utils/
  features/
    schedule/
      domain/
      data/
      presentation/
    import/
      domain/
      data/
      presentation/
    teaching_web/
      domain/
      data/
      presentation/
    excel_import/
      domain/
      data/
      presentation/
    openlib/
      domain/
      data/
      presentation/
    ai/
      domain/
      data/
    settings/
      domain/
      data/
      presentation/
  shared/
    models/
    widgets/
  main.dart
```

### 模块职责

- `app/`：应用入口、路由、主题、全局 Provider。
- `core/`：错误处理、网络、存储、时间计算、教学周规则、通用工具。
- `features/schedule/`：课表展示、课程详情、课程编辑、多学期切换。
- `features/import/`：统一导入管线、导入预览、冲突检测、标准化流程。
- `features/teaching_web/`：教务 WebView、页面抓取、HTML / DOM 解析。
- `features/excel_import/`：Excel 文件读取、表格映射、课程标准化。
- `features/openlib/`：课程资源链接、摘要缓存、推荐展示。
- `features/ai/`：AI 核心状态、API Key 解析、Moonshot / Kimi 客户端、课表结构化解析、后续 DeepSeek / Mock 服务和请求日志。
- `features/settings/`：学期设置、节次表、主题、API Key 配置。
- `shared/`：通用组件、样式、弹窗、表单控件。

## 版本路线

### v0.1alpha：Windows 本地课表技术切片

- 建立模块化工程骨架。
- 定义课程、学期、节次、导入批次、课程草稿、导入源、原始快照等核心模型。
- 接入 `go_router`、`flutter_riverpod`、`drift`、`shared_preferences`、`file_picker`。
- 实现本地 SQLite 数据库与默认数据初始化。
- 实现周视图、日视图、课程详情和当前课程提示。
- 实现手动课程新增、编辑、删除。
- 实现基础设置页、节次表编辑、导入快照开关。
- 实现 Excel 导入入口、导入批次创建与预览占位。
- 实现周次 / 节次解析、导入校验与冲突检测基础逻辑。
- 已通过 `dart analyze` 与 `flutter test`。
### v0.1.0-snapshot.2：多源导入与 AI 核心框架

- 版本号更新为 `0.1.0-snapshot.2+2`。
- 完成 Excel / CSV 课表真实解析，支持导入预览、冲突提示和确认入库。
- 导入页支持选择目标学期，导入数据绑定到选定学期。
- 移除导入页的导入批次历史展示，保留底层批次记录用于追踪。
- 新增 AI PDF / 图片导入入口，PDF 走 Kimi `file-extract` 文本抽取，图片走视觉模型识别。
- 新增内置课表结构化 Prompt，要求模型返回固定 JSON Object。
- 新增 AI JSON 解析器，统一转换为 `CourseDraft` 并经过本地校验、冲突检测和用户确认。
- 新增 AI 核心状态检测、右下角悬浮状态开关、设置页 API Key 配置。
- API Key 采用用户本地配置优先，未配置时允许 5 天内置试用，过期后强制配置。
- AI HTTP 请求增加 UTF-8 请求体写入、连接超时和响应超时，避免长时间无响应。
- 导入教室首个英文字符自动推断校区字段。
- 已补充 AI 解析、AI 设置、Excel 导入和 Widget 测试，并通过 `flutter analyze` 与 `flutter test`。

### v0.1.0-rc.2：首页体验、AI 提示与发布文档

- 版本号更新为 `v0.1.0-rc.2` / `0.1.0-rc.2+6`。
- 首页启动后默认定位到今日所在教学周，并保持周视图展示。
- “今日”入口可同步回到当前教学周和当天。
- 未配置 AI API Key 时，每次启动软件最多弹窗提醒一次；手动点击 AI 状态按钮仍可主动检测。
- 字体大小设置差异加大，小 / 中 / 大分别对应更明显的缩放层级。
- 同步 Windows 安装包脚本：`installer/seeku.iss` 与 `installer/seeku-v0.1.0-rc.2.iss`。
- README 顶部加入 `docs/seeku.png` 展示图，并加入 GitHub Releases 下载导览。
- 同步关于、联系、用户协议与规划文档中的版本、能力和限制说明。
- `flutter analyze` 与 `flutter build windows` 已通过；部分本机环境下 `flutter test` 在测试 shell 启动阶段断连，需后续继续排查。

### v0.1：Windows 本地课表闭环

- 继续完善多学期管理体验与边界状态。
- 扩充 Excel / CSV 脱敏样例，继续提升字段映射兼容性。
- 完善导入预览页，支持课程草稿编辑、批量修正、校验结果展示和冲突确认。
- 获取脱敏教务 HTML / DOM 片段后实现教务 WebView 导入和解析。
- 完善课程冲突提示与导入确认流程。
- 补齐课程颜色、分类、备注等展示与编辑体验。
- 完善离线查看与错误反馈。

### v0.2：AI 与资源增强

- Android 端适配与发布准备。
- PDF / 截图导入。
- DeepSeek / Moonshot 接入。
- AI 结构化解析课表。
- CQU-Openlib 课程资源匹配。
- 课程详情中展示资源链接和简短摘要。
- API Key 配置与请求日志。

### v0.3：账号与配置迁移

- 账号体系。
- 用户配置迁移。
- 多设备基础身份能力。
- 更完善的安全存储方案。

### v0.5：云同步

- 云端数据同步。
- 多端数据一致性。
- 备份与恢复。
- 冲突合并策略。

## 风险与待确认

- 重庆大学统一节次时间表的具体上下课时间仍需补充。
- 教务课表页面需要脱敏 HTML 或 DOM 片段，以便实现稳定解析器。
- Excel 导入已基于当前脱敏样例实现，但仍需收集更多 CQU 常见导出格式以提升兼容性。
- 教务页面折叠课程必须处理，否则可能漏课。
- 教务网站结构可能变动，需要保存快照与错误反馈机制。
- AI PDF / 图片识别依赖外部 API、网络质量和模型稳定性，必须保留导入预览和人工修正。
- CQU-Openlib 是否有稳定 API、是否允许爬取与缓存元数据仍需进一步确认。
- v0.1alpha 已采用 CQU 蓝白视觉方向；后续仍需结合真实课程密度继续调整桌面端信息层级。
- 当前 Web 构建不支持 native SQLite，若需要浏览器预览，需要新增 Web Preview 数据适配层。
- `sqlite3` native-assets 默认会尝试访问 GitHub 下载预编译 DLL，当前通过 `hooks.user_defines.sqlite3.source = system` 规避。
- 当前 AI Key 本地明文保存，后续需要迁移到更安全的本地安全存储。

## 下一步建议

1. 收集更多脱敏 Excel / PDF / 图片样例，覆盖不同学院、整周课程、折叠课程、单双周和多校区场景。
2. 完善导入预览页，支持草稿编辑、批量调整、冲突确认和失败项快速修正。
3. 获取脱敏教务课表 HTML / DOM 片段，确认折叠课程和整周课程结构。
4. 接入 `webview_windows`，实现教务登录后页面抓取与快照保存。
5. 将 AI Key 从 `shared_preferences` 明文保存迁移到更安全的本地安全存储。
6. 增加 AI 请求日志、错误分类、重试策略和更细粒度的上传 / 抽取 / 解析进度提示。
7. 补齐完整多学期创建 / 编辑 / 切换体验。
8. 继续优化 Windows 桌面端课表密度、可读性和小窗口响应式布局。
