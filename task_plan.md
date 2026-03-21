# Task Plan

## 目标
- 把单词本主页改成模块入口
- 模块进入后显示对应单词列表
- 单词列表可继续进入详情

## 范围
- 只改 `WordBook` 相关页面
- 不改 `database / mistakes / quiz / spelling`

## 验证
- 运行 `flutter analyze`，只检查本次改到的页面文件

## 流程
1. 读现有 `WordBook` 页面和单词数据结构
2. 拆出模块入口页和模块列表页
3. 调整主页交互
4. 做静态分析验证
