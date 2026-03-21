# Task Plan

## 当前目标（UI MVP 第二阶段）
- 统一视觉风格：主题、间距、卡片、列表项。
- 保持原功能不变：导入、选择题、拼写、错题本、统计。
- 增强学习入口：单词本首页可直接进入选择题和拼写。
- 提升详情信息层级：单词详情分为主信息、学习状态、构词扩展。

## 范围
- 修改页面：`main.dart`、`word_book_page.dart`、`word_detail_page.dart`、`multiple_choice_page.dart`、`spelling_page.dart`、`mistakes_page.dart`、`progress_page.dart`。
- 新增基础 UI 组件与主题：`lib/ui/app_theme.dart`、`lib/widgets/*`。
- 不改数据库表结构和业务规则（只做 UI 层接入）。

## 系统块图（简化）
```text
HomeShell
  ├─ WordBookPage  -> WordBookModulePage -> WordDetailPage
  ├─ MultipleChoicePage
  ├─ SpellingPage
  ├─ MistakesPage
  └─ ProgressPage

All Pages -> AppDatabase (SQLite)
All Pages -> AppTheme + Shared Widgets
```

## 实施流程（Checklist）
1. 抽离统一主题与基础组件。
2. 套用到选择题/拼写/错题本/统计页面。
3. 改造单词本首页为“导入 + 学习入口 + 模块入口”。
4. 改造单词详情页信息层级。
5. 执行 `dart format` + `flutter analyze` + `flutter test`。
