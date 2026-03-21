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
- 下一步建议：补充 1~2 个页面截图基线测试，避免后续样式回退。
