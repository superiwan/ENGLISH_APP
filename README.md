# English Word App

一个用于个人高频背词的 Flutter 应用，支持 PDF 导入、模块化词库浏览、选择题/拼写训练、错题本管理、学习统计与断点续学。

## 主要功能

- PDF 导入单词
  - 导入后自动清洗格式（音标/释义）并写入本地数据库。
- 单词本模块化浏览
  - 形近词、同义词、前缀相同、后缀相同、全部单词。
  - 模块页默认展示子模块，点击子模块后才展开单词列表。
- 训练模式
  - 选择题：看英文选中文释义。
  - 拼写：看中文拼英文。
  - 答错自动进入错题本。
- 错题本管理
  - 按题型分组（选择题/拼写）。
  - 支持删除单条、按类型清空、从错题直接重练。
- 统计页
  - 总词数、已练习、正确率、掌握量等指标。
- 断点续学
  - 首页提供“继续学习”入口。
  - 自动记录最近学习模式与进度并支持恢复。

## 技术栈

- Flutter (Material 3)
- SQLite (`sqflite`, `sqflite_common_ffi`)
- 本地 PDF 解析与导入

## 目录结构（核心）

- `lib/main.dart`：应用入口、主题、底部导航。
- `lib/database/app_database.dart`：SQLite 表结构与数据访问。
- `lib/pages/`：业务页面（单词本、训练、错题本、统计等）。
- `lib/models/`：数据模型。
- `lib/utils/`：PDF 导入、文本处理工具。

## 本地运行

在项目根目录打开终端：

```bash
cd D:/English_app
flutter pub get
flutter run -d windows
```

## 打包 Android APK

```bash
cd D:/English_app
flutter build apk --release
```

生成文件：

- `build/app/outputs/flutter-apk/app-release.apk`

说明：如果提示未找到 Android SDK，请先安装 Android Studio 并配置 `ANDROID_HOME / ANDROID_SDK_ROOT`。

## 发布到 GitHub Release

先确保已安装并登录 GitHub CLI：

```bash
gh auth login
```

然后在项目根目录执行（示例版本号 `v1.0.1`）：

```bash
cd D:/English_app
git add .
git commit -m "chore: android release build fixes"
git tag v1.0.1
git push origin DEV --tags
gh release create v1.0.1 build/app/outputs/flutter-apk/app-release.apk --title "v1.0.1" --notes "Android release APK"
```

发布后可在仓库 Release 页面直接下载 `app-release.apk`。

## 版本记录（最近）

- UI 现代化改版：卡片化布局、圆角导航、统一主题。
- 模块页交互：子模块默认收起，点击展开。
- 学习连续性：新增断点续学存储与首页恢复入口。
