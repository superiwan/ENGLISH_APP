帮我用Flutter开发一个本地运行的英语单词学习手机APP，仅供个人使用，要求代码完整、结构清晰、可以直接运行。

【技术要求】

- 使用 Flutter（Material UI）
- 使用 sqflite 作为本地数据库
- 不使用后端服务器（纯本地应用）
- 项目结构清晰（models / database / pages / utils）
- 每个页面单独文件
- 提供完整 main.dart

---

【核心功能模块】

1️⃣ 单词本模块（Word Book）

- 从SQLite读取单词数据
- 列表展示：word + phonetic + meaning
- 点击进入详情页
- 详情页展示：
  - 单词
  - 音标
  - 中文释义
  - 词组搭配（phrase）
  - 前缀（prefix）
  - 后缀（suffix）
  - 形近词（similar words）
  - 同义词（synonyms）

---

2️⃣ 选择题训练模块（Multiple Choice）

- 每次随机抽取一个单词作为题目
- 显示英文单词
- 提供4个选项（1正确 + 3错误）
- 错误选项从数据库随机生成（尽量同类词）

功能要求：

- 点击后立即判断对错
- 显示正确答案
- 自动进入下一题

错误处理：

- 选错 → 加入错题本（mistakes表）
- wrong_count +1
- familiarity -15

正确处理：

- familiarity +10

---

3️⃣ 拼写训练模块（Spelling）

- 显示中文意思
- 用户输入英文单词
- 判断拼写是否正确

要求：

- 提供输入框
- 支持简单容错（编辑距离 ≤ 2 时提示错误位置）
- 拼写错误加入错题本

---

4️⃣ 错题本模块（Mistakes）

- 展示所有错误单词
- 显示错误次数
- 区分类型（选择题 / 拼写）
- 点击可重新训练

---

5️⃣ 进度统计模块（Progress）
显示：

- 总单词数
- 已练习数量
- 正确率
- 已掌握数量（familiarity > 80）

---

6️⃣ PDF导入模块（重点功能）

功能：

- 用户点击按钮选择本地PDF文件
- 解析PDF文本内容
- 自动提取单词数据并存入数据库

技术要求：

- 使用 file_picker 选择PDF
- 使用 pdf_text 解析文本

PDF格式示例：
accumulate /ə'kjuːmjuleɪt/ vt. 积累

解析规则（使用正则）：

- 单词：第一个英文单词
- 音标：/ / 中间内容
- 中文：后面的内容

示例正则：
(\w+)\s*/([^/]+)/\s*(.*)

处理要求：

- 解析失败的行自动跳过
- 防止重复插入（word唯一）
- 导入完成后显示：
  “成功导入 XXX 个单词”

UI要求：

- 一个“导入PDF”按钮
- 显示导入进度

---

【数据库设计】

表1：words

- id INTEGER PRIMARY KEY
- word TEXT UNIQUE
- phonetic TEXT
- meaning TEXT
- phrase TEXT
- prefix TEXT
- suffix TEXT
- familiarity INTEGER DEFAULT 0
- wrong_count INTEGER DEFAULT 0

表2：mistakes

- word_id INTEGER
- type TEXT（choice / spelling）
- count INTEGER

---

【核心逻辑】

1. 熟练度系统：

- 正确：+10
- 错误：-15

2. 出题逻辑：

- 优先出错题（wrong_count高）
- 否则随机

3. 拼写判断：

- 完全正确 → 正确
- 编辑距离 ≤2 → 提示错误
- 否则 → 错误

---

【UI设计】

- 使用 Material Design
- 底部导航栏包含：

  - 单词本
  - 选择题
  - 拼写
  - 错题本
  - 统计
- 页面简洁（以实用为主）

---

【额外要求】

- 提供数据库初始化代码
- 提供示例数据插入方法（CSV或默认数据）
- 代码注释清晰
- 可直接运行

---

请输出完整Flutter代码，包括：

- main.dart
- 页面代码
- 数据库模块
- PDF导入实现
