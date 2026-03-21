# Progress

## 已完成
- 新增统一主题与设计令牌：`lib/ui/app_theme.dart`。
- 新增通用组件：`SectionHeader`、`MetricCard`、`WordListItem`。
- 已接入主题：`lib/main.dart`。
- 选择题页完成卡片化与按钮统一：`lib/pages/multiple_choice_page.dart`。
- 拼写页完成卡片化与输入区统一：`lib/pages/spelling_page.dart`。
- 错题本完成分组头规范化并复用通用列表项：`lib/pages/mistakes_page.dart`。
- 统计页改为通用指标卡布局：`lib/pages/progress_page.dart`。
- 单词本首页新增“今日学习入口卡”（可直接进入选择题/拼写）：`lib/pages/word_book_page.dart`。
- 单词详情页层级优化（主卡 + 学习状态 + 构词扩展）：`lib/pages/word_detail_page.dart`。

## 验证
- `dart format` 通过。
- `flutter analyze` 通过（No issues found）。
- `flutter test` 通过（All tests passed）。

## 当前状态
- UI MVP 第二阶段可用，核心流程未回归出阻断问题。
- UI 第三阶段已完成并热重载验证：
  - 深色模式切换（AppBar 按钮）
  - 底部模块切换轻动画过渡
  - 单词本新增“卡片学习”入口
  - 新增卡片分页学习页（左右滑动、上一张/下一张、中文释义显隐）
- 验证通过：`flutter analyze` + `flutter test` 全绿。
