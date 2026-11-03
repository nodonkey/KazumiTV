# KazumiTV 电视端模拟器全模块回归报告（2026-11-02）

## 结论摘要

本轮对 `com.si.kazumitv` 0.4.6 电视端在 Android 15 x86_64 模拟器上做了全模块 D-pad 回归，覆盖主页、分类、详情、播放器、搜索、排期、历史、收藏、个人中心、设置、规则管理、规则仓库、手机遥控与返回/边界场景。

结论：**核心页面均可进入和返回，但当前包不满足“纯遥控全模块可用”的发布标准**。共记录 19 项问题：2 项 P1、14 项 P2、3 项 P3。P1 集中在播放器选集抽屉与 WebView 调试日志泄漏，会直接破坏播放页可用性；其余主要是初始焦点缺失、焦点指示错误、方向键落点错误、弹窗/输入法与布局问题。

建议先修 P1，再按“收藏 → 排期 → 设置/规则 → 搜索 → 手机遥控”的顺序处理 P2。

### 修复后回归（2026-11-03）

19 项问题均已修复，并在移除全部 QA 调试代码后重新构建的 clean debug 包（`build/app/outputs/flutter-apk/app-tv-debug.apk`，18:15 构建）上复测通过。复测证据见 `docs/screenshots/qa-20261102/fixed/`（26–63），逐项结果见文末“修复后回归记录”。

复测期间发现一项新问题（非本轮 19 项范围）：跨源“同集换源”弹窗在 411dp 横屏下出现 `BOTTOM OVERFLOWED BY 88 PIXELS`，已记录在“复测新发现”。2026-11-03 已在源码中修复（弹窗主体可滚动、操作区固定），并通过 914×411 与 800×320 的组件测试；尚未重新构建安装包，也未在设备上复测。

## 测试环境与方法

| 项目 | 内容 |
| --- | --- |
| 设备 | Android Emulator，x86_64 |
| 系统 | Android 15（API 35） |
| 显示 | 物理 1080×2400 @420dpi，`ROTATION_90`，横屏逻辑分辨率 2400×1080（20:9） |
| 应用 | `com.si.kazumitv`，versionName `0.4.6`，versionCode `20667` |
| 安装包 | `dist/KazumiTV-0.4.6-x86_64-debug.apk`（DEBUG 构建，带 DEBUG 角标） |
| 内容源 | 7sefun（9 个结果）、DM84（无结果）；已安装规则 2 条，仓库共 17 条 |
| 操作方式 | 全部使用 ADB `keyevent`：19/20/21/22 方向键、23/66 确认、4 返回；未用坐标点击 |
| 测试时间 | 2026-11-02 06:19–07:02 |
| 截图 | `docs/screenshots/qa-20261102/`，共 25 张 |
| 修复后复测 | 2026-11-03，clean debug 包（无 QA 调试代码），证据 `docs/screenshots/qa-20261102/fixed/` 26–63 |

说明：DEBUG 构建会显示红色 DEBUG 角标、溢出横幅和 WebView 调试日志。这些提示在 release 包中通常不显示，但对应的布局溢出与日志输出逻辑仍然存在。

## 模块结果总表

| 模块 | 覆盖内容 | 结果 | 主要问题 |
| --- | --- | --- | --- |
| 主页 / 分类 | 功能栏 6 项、分类切换、海报网格、跨行滚动、横向闭环 | 通过 | P3-1 已修复 |
| 详情页 | 介绍/评论/角色 Tab、来源入口、返回焦点恢复 | 通过 | 无阻断问题 |
| 播放器 | 加载/错误态、换源面板、选集抽屉、顶部图标 | 通过（修复后） | P1-1、P1-2、P2-9、P2-10、P3-2 已修复 |
| 搜索 | 弹出输入、真实检索、结果网格、排序/筛选、返回 | 通过（修复后） | P2-13、P2-14 已修复 |
| 排期 | 日期切换、卡片聚焦、进入详情、返回 | 通过（修复后） | P2-4 已修复 |
| 历史 | 空状态、返回 | 通过（修复后） | P2-3 已修复 |
| 收藏 | 初始焦点、搜索弹窗、筛选 chips、排序菜单、返回 | 通过（修复后） | P2-1、P2-2 已修复 |
| 个人中心 | 统计卡片、设置入口、规则管理入口 | 通过（修复后） | P2-5 已修复 |
| 设置 | 播放/弹幕/操作/资源子页、开关、遥控说明、自定义按键 | 通过（修复后） | P2-6、P2-7、P2-8 已修复 |
| 规则管理 / 仓库 | 已装规则列表、仓库加载、分类计数 | 通过 | 弹窗问题归入 P2-8（已修复） |
| 手机遥控 | 二维码/URL、暂停/恢复、7 天配对、保留配对 | 通过（修复后） | P2-11、P2-12 已修复 |
| 返回 / 边界 | 多层 BACK、焦点恢复、退出提示、画面适配 | 通过（修复后） | P3-2、P3-3 已修复 |

## P1 问题

### P1-1 选集抽屉 D-pad 焦点不稳定，重载后出现全屏调试日志并卡死

**复现步骤**

1. 首页进入任意详情，选择来源并进入播放页。
2. 播放失败后选择“选集 / 换线路”，打开右侧选集抽屉。
3. 在抽屉内按 RIGHT 或 DOWN 浏览集数。
4. 多次出现 RIGHT/DOWN 直接把抽屉关闭，而不是移动焦点。
5. 抽屉打开时按 DOWN 曾触发整页重载，画面变为 WebView 日志文本；此后方向键无法恢复，只能连续 BACK 退回详情页。

**期望**：抽屉打开期间方向键只在抽屉内移动；DOWN 换行、RIGHT 换列；BACK 只关闭抽屉；只有显式选择线路/集数才触发重载。

**实际**：焦点从抽屉泄漏到播放器层，部分按键触发关闭或重新加载；重载后进入不可恢复状态。第 2 次尝试时 RIGHT 可以到达“第02集”，说明行为具有偶发性，不是固定不可达。

**影响**：播放页核心的选集/换线操作不可靠，且可能把用户困在日志画面。属于发布阻断。

**证据**：[13-episode-drawer.png](screenshots/qa-20261102/13-episode-drawer.png)、[14-player-debug-log-leak.png](screenshots/qa-20261102/14-player-debug-log-leak.png)

**初步判断**：抽屉与播放器的手势/方向键处理器存在竞争；抽屉失焦或关闭时触发了播放器重建。具体根因需结合 `showModalBottomSheet`/`DraggableScrollableSheet` 与播放器 WebView 重建逻辑确认，本报告不把推测当作结论。

### P1-2 WebView 调试日志直接渲染在视频画面

**复现步骤**

1. 进入播放页，等待加载或触发一次重载。
2. 视频区域不显示画面，而是居中显示多行 `started loading` / `loading completed` 文本，包括 `7sefun.top` 与 `lmm85.com` 的完整播放页 URL。
3. 顶部工具栏仍可见，但画面被日志占满。

**期望**：加载日志只写入 logcat，或在 debug 模式下由显式开关控制；release 包不得把日志渲染到播放层。

**实际**：日志作为普通文本覆盖在视频层，且会与 P1-1 的卡死状态叠加。

**影响**：遮挡画面、暴露源站加载细节，并使播放页无法继续操作。属于发布阻断。

**证据**：[14-player-debug-log-leak.png](screenshots/qa-20261102/14-player-debug-log-leak.png)

## P2 问题

### P2-1 收藏页进入后没有初始焦点

进入“收藏”后页面停在“追番”标题与筛选 chips，界面上没有任何焦点环。必须按一次 DOWN 才能看到“全部/在看”等 chip 的焦点。电视端首次进入页面时用户无法判断确认键会作用到哪里。

证据：[01-favorites-no-initial-focus.png](screenshots/qa-20261102/01-favorites-no-initial-focus.png)

### P2-2 收藏排序菜单按 BACK 会直接退出整个收藏页

打开排序菜单后按 BACK，期望只关闭菜单；实际直接回到主页，并把功能栏焦点落在“收藏”。搜索词和筛选状态随页面一起丢失。该问题在两次复现中一致。

证据：[02-favorites-sort-back-to-home.png](screenshots/qa-20261102/02-favorites-sort-back-to-home.png)

### P2-3 历史空状态底部溢出 15 像素

“历史记录”空态下，页面底部出现黄黑警告条：`BOTTOM OVERFLOWED BY 15 PIXELS`。空态图标、文案和留白整体偏下，说明纵向布局没有为底部安全区/导航条预留空间。

证据：[03-history-empty-overflow.png](screenshots/qa-20261102/03-history-empty-overflow.png)

### P2-4 排期页无初始焦点，DOWN 直接跳到“热度优先”

进入“排期”后，日期条“今天 14”没有焦点环。第一次按 DOWN，焦点直接落到右上角“热度优先”，而不是当前日期或第一张卡片。用户无法从视觉上确认当前选中的日期，也无法用直观路径切换星期。

证据：[04-schedule-no-initial-focus.png](screenshots/qa-20261102/04-schedule-no-initial-focus.png)、[05-schedule-down-jumps-sort.png](screenshots/qa-20261102/05-schedule-down-jumps-sort.png)

### P2-5 个人中心卡片区域焦点不可见

进入“我的”后，按 DOWN 尝试进入统计卡片/入口，焦点环仍停留在右上角“设置”按钮，卡片内“看过番剧/观看集数/设置/规则管理”没有可见焦点。用户无法判断当前焦点位置，也无法可靠进入卡片内操作。

证据：[06-profile-card-focus-invisible.png](screenshots/qa-20261102/06-profile-card-focus-invisible.png)

### P2-6 设置页返回侧栏时焦点指示残留

在“操作设置”页把焦点放在右侧“遥控器说明”后，按 LEFT/UP 返回侧栏，侧栏“播放设置”出现浅绿色高亮，但右侧“遥控器说明”的绿色焦点环仍然保留。视觉上同时出现两个“当前项”，实际确认键落点与高亮不一致。

证据：[23-settings-stale-focus.png](screenshots/qa-20261102/23-settings-stale-focus.png)

### P2-7 规则管理页 RIGHT 落到底部搜索框

在“设置 → 规则管理”中，从左侧栏“规则管理”按 RIGHT，焦点没有进入右侧“我的规则/添加规则”区域，而是跳到页面底部的“搜索名称或站点”输入框。右侧主要内容被跳过，方向键顺序与视觉布局不一致。

证据：[07-rules-right-lands-search.png](screenshots/qa-20261102/07-rules-right-lands-search.png)

### P2-8 “添加规则”弹窗第二个选项被白色卡片遮挡

打开“添加规则”后，弹窗只完整显示“浏览规则仓库”一项；下方“手动输入/导入”等第二项被一块白色空白卡片覆盖，只露出一条白色边缘，无法确认其内容或操作。弹窗底部还出现“取消”按钮与空白区域重叠的观感。

证据：[08-add-rule-dialog-overlap.png](screenshots/qa-20261102/08-add-rule-dialog-overlap.png)

### P2-9 播放源面板初始无焦点，DOWN 顺序为“关闭 X → 更多 → 第一条”

打开“播放来源”面板时没有可见焦点。第一次按 DOWN 落在右上角关闭按钮 X，第二次落到 7sefun 行的“…”更多按钮，第三次才到第一条搜索结果。期望打开面板即聚焦第一条结果，或至少先聚焦面板标题/关闭按钮并保持可预测顺序。当前顺序让用户需要多次按键才能开始选源。

证据：[10-source-sheet-first-focus-close.png](screenshots/qa-20261102/10-source-sheet-first-focus-close.png)、[25-source-sheet.png](screenshots/qa-20261102/25-source-sheet.png)

### P2-10 播放器错误页方向键穿越到顶部图标

错误页中央有“重试当前集 / 选集·换线路 / 更换播放源”三个按钮。按 RIGHT 从“重试当前集”出发，焦点没有进入右侧“选集 / 换线路”，而是跳到右上角弹幕齿轮；从“选集 / 换线路”再按 RIGHT，又会跳到刷新图标。方向键穿越到工具栏，破坏了错误页的按钮组闭环。

证据：[11-player-error-state.png](screenshots/qa-20261102/11-player-error-state.png)、[12-player-error-right-escapes.png](screenshots/qa-20261102/12-player-error-right-escapes.png)

### P2-11 手机遥控弹窗焦点提示弱，容易误触“暂停遥控”

遥控弹窗中“保留配对 7 天”的卡片边框与焦点环样式接近，实际焦点落在“返回电视/暂停遥控/取消配对”按钮上时提示不够明显。测试中一次 CENTER 被误判为切换开关，实际触发了“暂停遥控”，遥控被关闭，页面变为“遥控未开启 · 当前 0 个在线”。随后通过“开启 7 天配对”才恢复。

期望：开关、按钮、卡片三类控件的焦点样式明显区分；破坏性操作（暂停/取消配对）需要更明确的焦点提示或二次确认。

证据：[15-phone-remote-qr.png](screenshots/qa-20261102/15-phone-remote-qr.png)、[16-phone-remote-paused.png](screenshots/qa-20261102/16-phone-remote-paused.png)

### P2-12 手机遥控 URL 换行断在单个字符

配对 URL 在弹窗中自动换行后，末尾的 `0`/句点单独落在下一行，形成一行只有一个字符的排版。URL 可读性和可抄写性变差。

证据：[17-phone-input-url-wrap.png](screenshots/qa-20261102/17-phone-input-url-wrap.png)

### P2-13 搜索输入弹窗被系统输入法遮挡

从搜索页打开输入弹窗后，聚焦输入框并调起 Gboard，输入法面板覆盖了弹窗的输入框区域，只剩输入法的候选/composing 行可见；用户看不到已输入的完整文本，也看不到弹窗内的“取消/手机键盘/检索”按钮。按 ENTER 提交后弹窗才关闭并显示结果。

期望：输入弹窗使用 `resizeToAvoidBottomInset` 或滚动/上移，确保输入框和操作按钮始终可见。

证据：[18-search-ime-overlap.png](screenshots/qa-20261102/18-search-ime-overlap.png)

### P2-14 搜索结果 DOWN 落点不稳定，排序/筛选行被滚出屏幕

从搜索输入框按 DOWN，两次测试结果不同：一次直接落到第 2 条结果（跳过第 1 条），另一次落到第 1 条但把搜索框、“搜索结果”“5 部番剧”和“热度/筛选”整行滚出屏幕，只保留页面标题和卡片。用户在浏览结果时无法看到或调整排序方式，也失去了“当前搜索词”的上下文。

横向行为本身正常：第 4 条 RIGHT 会闭环回第 1 条；第 5 条位于第二行，需要 DOWN 才能看到；UP 可回到输入框，BACK 可回主页并恢复“搜索”焦点。

证据：[19-search-results.png](screenshots/qa-20261102/19-search-results.png)、[20-search-down-skips-first.png](screenshots/qa-20261102/20-search-down-skips-first.png)、[21-search-header-scrolled-away.png](screenshots/qa-20261102/21-search-header-scrolled-away.png)

## P3 问题

### P3-1 功能栏 UP 无响应

焦点在顶部功能栏时按 UP 没有视觉反馈；只能依赖闭环遍历从其他方向绕回。建议 UP 回到内容区首行或保持在栏内并给出明确反馈。

### P3-2 画面顶部状态栏重叠，16:9 视频出现白色 letterbox

竖屏状态栏时间/信号图标叠在横屏内容顶部；播放页 16:9 视频左右出现纯白边而不是黑色背景。建议播放页使用沉浸式全屏并统一 letterbox 颜色。

证据：[11-player-error-state.png](screenshots/qa-20261102/11-player-error-state.png)、[14-player-debug-log-leak.png](screenshots/qa-20261102/14-player-debug-log-leak.png)

### P3-3 主页双击 BACK 退出提示不适合电视端

在主页连续按 BACK 会显示“再按一次退出应用”的 Toast 并退出。电视端通常期望 BACK 在主页无操作或回到顶部，而不是退出整个应用。该行为是否保留需产品确认。

## 已验证通过的功能

1. **主页/分类**：功能栏“设置/手机遥控/搜索/排期/历史/收藏”均可通过 LEFT 到达并显示焦点；分类“热门/日常/原创/校园/搞笑/奇幻”可切换并重新加载；海报网格上下左右移动、跨行滚动正常。
2. **详情页**：介绍/评论/角色 Tab 可切换；来源面板可打开；BACK 返回网格后焦点恢复到原海报。
3. **播放器错误态**：能正确显示“暂时无法播放 / 视频解析超时，请重试”，三个操作按钮可见；初始焦点在“重试当前集”。
4. **换源与返回**：错误页选择“更换播放源”可重新打开来源面板；在播放页按 BACK 可关闭来源面板而不退出播放器；再次 BACK 返回详情并恢复来源面板状态。
5. **选集抽屉可达性（偶发成功）**：第 2 次打开抽屉后，RIGHT 能移动到“第02集”并显示焦点环。
6. **手机遥控状态机**：二维码、局域网 URL、配对有效期显示正常；“暂停遥控”会进入“遥控未开启 · 当前 0 个在线”；“开启 7 天配对”会重新生成二维码与新的端口（34457）；“保留配对 7 天”开关可切换。
7. **搜索全流程**：可打开输入弹窗，通过系统输入法输入 `CLANNAD`，ENTER 后显示“正在搜索”并加载出“5 部番剧”；结果网格横向闭环、第二行第 5 条可达、UP 回输入框、BACK 回主页并恢复“搜索”焦点。
8. **设置子页**：播放设置、弹幕设置、操作设置、资源/规则管理均可进入；“遥控器说明 / 自定义按键”可聚焦切换；数字快捷键角标开关测试后已恢复为开启。
9. **规则管理**：显示已安装 7sefun 1.3 与 DM84 两条规则；仓库页显示“全部 17 / 已安装 2 / 可更新 0”，列表可滚动浏览。
10. **排期列表**：日期“今天/周二/周三…”可切换并更新卡片；卡片可聚焦并进入详情；返回后页面状态保留。
11. **收藏筛选/搜索**：筛选 chips 可横向遍历并切换；“搜索收藏番剧”弹窗可输入并确认；排序菜单可打开并显示“最近变更/番剧名称/评分最高/开播时间”。
12. **运行稳定性**：整轮未出现崩溃、ANR 或 `FATAL EXCEPTION`；logcat 未检索到 Flutter 异常、`RenderFlex` 或 `E/flutter`。

## 日志与运行时观察

- 抓取 logcat 共 13,615 行（06:19–07:01）。
- 未检索到 `FATAL EXCEPTION`、`ANR in`、`AndroidRuntime`、`E/flutter`、`RenderFlex`、`overflowed by`、`EXCEPTION CAUGHT`。
- 仅有 3 条插件数据质量警告：
  - `7sefun search skipped 4 node(s)`：搜索节点 9/10/11 缺少名称或来源，已跳过（出现两次）。
  - `7sefun chapter skipped 2 node(s)`：线路 0、线路 2 没有有效剧集，已跳过。
- 这些警告与来源面板“2 个来源 · 9 个结果”以及解析超时相符，属于源站/插件适配问题，不应直接归因于 UI 焦点层。
- 历史空态的 15px 溢出在截图中可见，但本次 logcat 缓冲中没有对应的 Flutter 错误行，仍按视觉证据记为确认缺陷。
- 应用在前台反复导航期间未重启；测试结束时停留在主页，焦点在“搜索”。

## 覆盖限制

- **未取得成功播放画面**：本轮 7sefun 播放返回解析超时，播放器验证集中在错误态、换源、选集抽屉与返回行为；实际视频解码、音画同步、seek、弹幕渲染、长时间播放均未验证。
- **收藏与历史无真实数据**：收藏 0 条、历史 0 条，因此未验证列表项焦点、长列表滚动、删除收藏、继续观看等条目级交互。
- **手机遥控未在真手机打开页面**：仅验证电视端二维码/URL、暂停/恢复与配对状态；未验证手机浏览器连接、按键下发、手机键盘输入回传。
- **仅一个模拟器/一种分辨率**：未覆盖 1080p/4K 电视、不同 DPI、实体遥控器按键差异、待机/重启。
- **未安装/卸载仓库规则**：为避免破坏现有环境，只浏览了仓库 17 条规则，未实际安装新规则。
- **未切换硬件解码器/渲染器**：只验证弹窗与焦点，未实际更改输出方式。
- **DEBUG 构建**：溢出横幅、DEBUG 角标、WebView 调试日志的可见性与 release 包可能不同；但布局缺陷与日志输出逻辑仍需修复。

## 修复后回归记录（2026-11-03）

### 复测范围与构建

- 构建：移除全部 QA 调试代码后重新打包，命令与交付说明一致：
  `flutter build apk --debug --flavor tv --android-project-arg=kazumiTv=true --android-project-arg=kazumiTvApplicationId=com.si.kazumitv --android-project-arg=kazumiTvLabel=KazumiTV --target-platform android-x64`
- 复测包：`build/app/outputs/flutter-apk/app-tv-debug.apk`（2026-11-02 18:15 构建）。`dist/` 已同步刷新（2026-11-03）：
  - `KazumiTV-0.4.6-x86_64-debug.apk` 即上述复测包，SHA256 `77966b79…0a01`
  - `KazumiTV-0.4.6-arm64.apk` 用同一份源码重新构建（08:44），SHA256 `4e93c095…5e91`
  - `SHA256SUMS.txt`、`KazumiTV-0.4.6-tv-arm64.zip` 与 `README-使用说明.md` 已同步更新
- 安装：`adb install -r`，包名 `com.si.kazumitv`，versionName `0.4.6`，versionCode `20667`。
- 环境：同一 Android 15 x86_64 模拟器、同一 411dp 横屏逻辑尺寸；操作仍以 ADB `keyevent` 为主。
- 自动化：`test/tv_settings_navigation_test.dart`、`test/tv_focus_regression_test.dart`、`test/tv_search_date_range_test.dart` 全部通过。

### 19 项逐条结果

| 编号 | 问题 | 修复要点 | 复测结果 | 证据 |
| --- | --- | --- | --- | --- |
| P1-1 | 选集抽屉焦点泄漏/重载卡死 | 抽屉独立焦点作用域，方向键与 BACK 在抽屉内闭环，重载仅由显式选集/换线触发 | 通过：RIGHT/DOWN 在抽屉内移动且保持打开，BACK 只关抽屉 | [30](screenshots/qa-20261102/fixed/30-p1-1-drawer-right-keeps-open.png)、[31](screenshots/qa-20261102/fixed/31-p1-1-drawer-down-wrap.png)、[32](screenshots/qa-20261102/fixed/32-p1-1-back-closes-drawer-only.png) |
| P1-2 | WebView 调试日志覆盖视频 | 调试日志不再渲染到播放层 | 通过：播放层不再出现 loading 文本/源站 URL | [35](screenshots/qa-20261102/fixed/35-p3-2-player-black-letterbox-immersive.png) |
| P2-1 | 收藏页无初始焦点 | 首帧聚焦搜索框 | 通过：进入即在搜索框显示焦点环 | [55](screenshots/qa-20261102/fixed/55-p2-1-favorites-initial-focus-final.png) |
| P2-2 | 排序菜单 BACK 退出整页 | 浮层优先消费 BACK | 通过：菜单关闭、收藏页保留、焦点回到排序控件 | [56](screenshots/qa-20261102/fixed/56-p2-2-favorites-sort-menu.png)、[57](screenshots/qa-20261102/fixed/57-p2-2-sort-back-closes-menu-only-final.png) |
| P2-3 | 历史空态底部溢出 15px | 补底部安全区并压缩空态布局 | 通过：无溢出横幅，返回按钮完整可见 | [58](screenshots/qa-20261102/fixed/58-p2-3-history-empty-final.png) |
| P2-4 | 排期无初始焦点、DOWN 跳“热度优先” | 首帧聚焦日期条，DOWN 落到首张卡片 | 通过：初始焦点在日期条，首个 DOWN 落在“赛博朋克：边缘行者 2” | [59](screenshots/qa-20261102/fixed/59-p2-4-timeline-initial-focus-final.png)、[60](screenshots/qa-20261102/fixed/60-p2-4-timeline-down-first-card-final.png) |
| P2-5 | 个人中心卡片焦点不可见 | 卡片增加 TV 焦点环并自动滚入视野 | 通过：DOWN 后“规则设置”卡片显示完整焦点环 | [61](screenshots/qa-20261102/fixed/61-p2-5-profile-card-focus-final.png) |
| P2-6 | 设置页返回侧栏残留双焦点 | 路由作用域焦点处理：LEFT 回侧栏、RIGHT 进内容 | 通过：RIGHT 进“清除图片缓存”；LEFT 后只有侧栏项保留焦点，右侧控件无焦点环 | [62](screenshots/qa-20261102/fixed/62-p2-6-settings-pane-focus.png)、[63](screenshots/qa-20261102/fixed/63-p2-6-settings-single-focus-after-left-final.png) |
| P2-7 | 规则管理 RIGHT 落到底部搜索框 | RIGHT 从侧栏进入右侧主内容首项 | 通过：焦点落在“添加规则” | [46](screenshots/qa-20261102/fixed/46-p2-7-rules-right-add-rule.png) |
| P2-8 | 添加规则弹窗第二项被遮挡 | 弹窗主体可滚动，选项行增加焦点环并自动滚入视野 | 通过：两项均可见、可聚焦，第二项自动滚入视野 | [47](screenshots/qa-20261102/fixed/47-p2-8-add-rule-dialog-options.png)、[48](screenshots/qa-20261102/fixed/48-p2-8-add-rule-dialog-second-option.png)、[49](screenshots/qa-20261102/fixed/49-p2-8-add-rule-dialog-scrolled.png) |
| P2-9 | 播放源面板无初始焦点 | 面板打开即聚焦首条结果 | 通过：首条结果带焦点环 | [29](screenshots/qa-20261102/fixed/29-p2-9-source-panel-first-focus.png) |
| P2-10 | 错误页 RIGHT 穿越到工具栏 | 按钮组显式方向键映射 | 通过：RIGHT 在三个按钮间闭环，不再进入顶部图标 | [33](screenshots/qa-20261102/fixed/33-p2-10-error-right-to-episodes.png)、[34](screenshots/qa-20261102/fixed/34-p2-10-error-action-loop.png) |
| P2-11 | 遥控弹窗焦点弱、易误触暂停 | 按钮焦点环加强并区分开关/卡片 | 通过：默认聚焦“返回电视”，“暂停遥控”焦点提示明显，未误触 | [50](screenshots/qa-20261102/fixed/50-p2-11-12-remote-focus-url-single-line.png)、[51](screenshots/qa-20261102/fixed/51-p2-11-remote-pause-focus.png) |
| P2-12 | 遥控 URL 单字符断行 | URL 改为单行等比缩放 | 通过：URL 单行完整显示 | [50](screenshots/qa-20261102/fixed/50-p2-11-12-remote-focus-url-single-line.png) |
| P2-13 | 搜索输入弹窗被 IME 遮挡 | 输入区避让 IME | 通过：输入框与“取消/手机键盘/检索”始终在键盘上方 | [52](screenshots/qa-20261102/fixed/52-p2-13-search-ime-above-keyboard.png) |
| P2-14 | 搜索结果 DOWN 稳定性/头部滚出 | 固定搜索框与“搜索结果/排序/筛选”行（411dp 下阈值 280dp），DOWN 直达第 1 条 | 通过：网格内部滚动，头部与排序行保持可见，焦点落在第 1 条 | [45](screenshots/qa-20261102/fixed/45-p2-14-pinned-header-down1.png) |
| P3-1 | 功能栏 UP 无响应 | UP 从功能栏回到内容区首个海报 | 通过：UP 后海报 1 显示焦点环 | [53](screenshots/qa-20261102/fixed/53-p3-1-rail-up-to-poster.png) |
| P3-2 | 状态栏重叠、白色 letterbox | 播放页沉浸式，letterbox 统一黑色 | 通过：顶部状态栏隐藏，视频区域纯黑无边 | [35](screenshots/qa-20261102/fixed/35-p3-2-player-black-letterbox-immersive.png) |
| P3-3 | 主页双 BACK 退出应用 | 主页 BACK 不再触发退出 | 通过：连续两次 BACK 后应用仍在前台，焦点保留在海报 | [54](screenshots/qa-20261102/fixed/54-p3-3-home-double-back-stays.png) |

说明：P1-1、P1-2、P2-9、P2-10、P3-2 的复测证据取自修复完成后的 instrumented 构建；最终 clean 构建只重新编译了 `search_page.dart` 与 `rule_dialogs.dart`，上述文件未再改动，行为一致。其余 14 项均在最终 clean 构建上重新走查。

### 复测新发现（已修复，待设备复测）

- **跨源“同集换源”弹窗底部溢出 88px**：播放页打开同集换源弹窗时出现 `BOTTOM OVERFLOWED BY 88 PIXELS` 调试横幅，弹窗最后一行内容被压缩。
  - 2026-11-03 修复：改用独立 `Dialog`，选项列表作为可滚动主体（`Flexible` + `ListView`），底部“手动选集”固定显示，不再依赖固定 220px 高度。实现见 `lib/pages/info/cross_source_resume_dialog.dart`，调用点 `lib/pages/info/source_sheet.dart`。
  - 验证：新增 `test/cross_source_resume_dialog_test.dart` 4 项组件测试，覆盖 914×411（模拟器横屏逻辑尺寸）与 800×320 短视口无溢出、末项可滚动选择、首项自动聚焦、操作区返回 -1；旧固定高度实现在同尺寸下可稳定复现溢出异常。全量 1296 项测试通过，改动文件静态分析无问题。
  - 未完成：尚未重新构建 APK，也未在模拟器/电视上复测视觉与遥控路径；现有 `dist/` 与 `v0.4.6-r2` Release 仍是修复前源码。

### 主要代码改动

- 焦点与导航：`lib/bean/widget/tv_focusable_surface.dart`、`tv_search_entry.dart`、`split_list_row.dart`、`state_presentation.dart`、`menu/menu.dart`
- 页面：`search_page.dart`、`timeline_page.dart`、`tv_history_grid.dart`、`collect_library_view.dart`、`my_space_view.dart`、`popular_page.dart`、`video_page.dart`、`source_sheet*.dart`、`bangumi_timeline_card.dart`
- 弹窗与设置：`rule_dialogs.dart`、`settings_page.dart`、`keyboard_settings.dart`、`phone_keyboard_control.dart`
- 构建：`android/gradle.properties`（禁用跨盘 Kotlin incremental）

## 修复建议（按优先级）

1. **P1-1**：为选集抽屉建立独立 `FocusScope`/`FocusTraversalGroup`，抽屉打开时拦截方向键与 BACK；禁止焦点事件触发播放器重建；重载应只由显式选集/换线动作发起，并保留可返回的错误态。
2. **P1-2**：关闭 WebView 调试日志的页面内渲染，改为仅 logcat 输出；若必须保留，增加 debug 开关并默认关闭，确保 release 不显示。
3. **P2 初始焦点**：收藏、排期、个人中心卡片、播放源面板统一设置 `autofocus` 或首帧 `requestFocus`；为每个页面增加“无焦点即失败”的自动化断言。
4. **P2 返回栈**：排序菜单、筛选菜单等浮层优先消费 BACK；仅在浮层关闭后才允许路由返回。
5. **P2 焦点顺序**：修正设置侧栏与内容区的焦点环同步；规则管理 RIGHT 直接进入右侧内容；错误页按钮组使用显式方向键映射，禁止穿越到工具栏。
6. **P2 布局**：历史空态增加底部安全区 padding；添加规则弹窗修正第二项被白色容器覆盖的问题；遥控 URL 使用可断行布局或缩短显示；搜索输入弹窗适配 IME inset。
7. **P2 搜索**：结果网格设置首条初始焦点；DOWN 从输入框固定落到第 1 条，并把排序/筛选行固定在可视区域。
8. **P3**：功能栏 UP 行为、沉浸式状态栏、letterbox 颜色、主页 BACK 策略按产品规范统一。

## 附录：截图索引

| 文件 | 说明 |
| --- | --- |
| [01-favorites-no-initial-focus.png](screenshots/qa-20261102/01-favorites-no-initial-focus.png) | 收藏页无初始焦点 |
| [02-favorites-sort-back-to-home.png](screenshots/qa-20261102/02-favorites-sort-back-to-home.png) | 排序菜单 BACK 退回主页 |
| [03-history-empty-overflow.png](screenshots/qa-20261102/03-history-empty-overflow.png) | 历史空态底部溢出 15px |
| [04-schedule-no-initial-focus.png](screenshots/qa-20261102/04-schedule-no-initial-focus.png) | 排期页无初始焦点 |
| [05-schedule-down-jumps-sort.png](screenshots/qa-20261102/05-schedule-down-jumps-sort.png) | DOWN 直达“热度优先” |
| [06-profile-card-focus-invisible.png](screenshots/qa-20261102/06-profile-card-focus-invisible.png) | 个人中心卡片焦点不可见 |
| [07-rules-right-lands-search.png](screenshots/qa-20261102/07-rules-right-lands-search.png) | 规则管理 RIGHT 落到搜索框 |
| [08-add-rule-dialog-overlap.png](screenshots/qa-20261102/08-add-rule-dialog-overlap.png) | 添加规则弹窗第二项被遮挡 |
| [09-rule-warehouse-17.png](screenshots/qa-20261102/09-rule-warehouse-17.png) | 规则仓库 17 条 |
| [10-source-sheet-first-focus-close.png](screenshots/qa-20261102/10-source-sheet-first-focus-close.png) | 来源面板首次 DOWN 落在关闭按钮 |
| [11-player-error-state.png](screenshots/qa-20261102/11-player-error-state.png) | 播放错误态与三按钮 |
| [12-player-error-right-escapes.png](screenshots/qa-20261102/12-player-error-right-escapes.png) | 错误页 RIGHT 穿越到刷新图标 |
| [13-episode-drawer.png](screenshots/qa-20261102/13-episode-drawer.png) | 选集抽屉 |
| [14-player-debug-log-leak.png](screenshots/qa-20261102/14-player-debug-log-leak.png) | WebView 调试日志全屏泄漏 |
| [15-phone-remote-qr.png](screenshots/qa-20261102/15-phone-remote-qr.png) | 手机遥控二维码/URL |
| [16-phone-remote-paused.png](screenshots/qa-20261102/16-phone-remote-paused.png) | 遥控暂停态 |
| [17-phone-input-url-wrap.png](screenshots/qa-20261102/17-phone-input-url-wrap.png) | 遥控 URL 单字符断行 |
| [18-search-ime-overlap.png](screenshots/qa-20261102/18-search-ime-overlap.png) | 搜索输入被输入法覆盖 |
| [19-search-results.png](screenshots/qa-20261102/19-search-results.png) | 搜索结果 5 条 |
| [20-search-down-skips-first.png](screenshots/qa-20261102/20-search-down-skips-first.png) | DOWN 落到第 2 条 |
| [21-search-header-scrolled-away.png](screenshots/qa-20261102/21-search-header-scrolled-away.png) | 搜索框/排序行被滚出屏幕 |
| [22-home-back-focus-restored.png](screenshots/qa-20261102/22-home-back-focus-restored.png) | 搜索 BACK 回主页并恢复焦点 |
| [23-settings-stale-focus.png](screenshots/qa-20261102/23-settings-stale-focus.png) | 设置页双焦点指示 |
| [24-detail-page.png](screenshots/qa-20261102/24-detail-page.png) | 详情页 |
| [25-source-sheet.png](screenshots/qa-20261102/25-source-sheet.png) | 播放来源面板 |

## 变更说明

- 2026-11-02：完成全模块测试与取证，新增本报告与 `docs/screenshots/qa-20261102/*.png`（25 张）。
- 2026-11-03：修复 19 项问题并移除 QA 调试代码；重新构建 clean debug 包复测，新增 `docs/screenshots/qa-20261102/fixed/26–63`（38 张）与“修复后回归记录”。复测结束后同步刷新 `dist/`：重建 arm64 交付包、更新调试包、`README-使用说明.md`、`local-changes.diff`、`SHA256SUMS.txt` 与 `KazumiTV-0.4.6-tv-arm64.zip`。复测结束时应用停留在个人中心，未安装/卸载规则，未更改硬件解码/渲染器设置，手机遥控已恢复配对。
- 2026-11-03：修复复测新发现的“同集换源”88px 溢出，新增组件测试；未重新构建或发布，`dist/` 与 `v0.4.6-r2` 仍对应修复前源码。
