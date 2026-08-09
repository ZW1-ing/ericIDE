# EricPC - HarmonyOS Eric6 IDE 复刻版

基于 HarmonyOS ArkTS 开发的 Eric6 IDE 鸸蒙移植版，复刻了开源项目 [eric-ide-zh_CN](https://github.com/suifengtec/eric-ide-zh_CN) 的完整 UI 和功能。

## 项目简介

EricPC 是一个运行在 HarmonyOS 设备上的轻量级代码编辑器/IDE，采用类似 VS Code 的现代 IDE 布局，支持 Python 代码的编辑和模拟运行。

## 功能特性

### 界面布局
- **标题栏** - 深灰色背景，绿色 ERIC6 标志，窗口控制按钮
- **菜单栏** - 文件(F)、编辑(E)、搜索(U)、视图(V)、调试(D)、帮助(H)
- **工具栏** - 运行/停止、新建/打开/保存、撤销/重做、剪切/复制/粘贴、搜索
- **活动栏** - 左侧窄条，文件/搜索/Git/调试/扩展 图标
- **侧边栏** - EXPLORER 文件树，支持文件夹展开/折叠
- **编辑区** - 标签页管理，行号显示，代码编辑
- **终端面板** - 终端/输出/问题/调试控制台，运行结果展示
- **状态栏** - 蓝色底栏，显示语言、文件名、光标位置、编码、版本

### 核心功能
- 📝 **代码编辑** - TextArea 代码输入，支持多文件标签页
- ▶️ **代码运行** - Python 模拟器，点击运行按钮即可执行代码
- 📁 **文件管理** - 文件树浏览，新建/保存/另存为/关闭文件
- ↩️ **撤销/重做** - 完整的编辑历史管理
- 🔍 **搜索** - 全局搜索功能
- 🐍 **Python 模拟器** - 支持 print、变量、函数、循环、条件、列表推导式等
- 🐛 **错误提示** - 语法错误、运行时错误的友好提示
- 📋 **终端输出** - 带行号的格式化输出，区分信息/输出/错误/系统消息

## 项目结构

```
EricPC_MVP2/
├── entry/src/main/ets/
│   ├── pages/
│   │   ├── Index.ets              # 主页面入口
│   │   ├── TitleBar.ets           # 标题栏
│   │   ├── MenuBar.ets            # 菜单栏
│   │   ├── ToolBar.ets            # 工具栏
│   │   ├── ActivityBar.ets        # 活动栏
│   │   ├── SideBar.ets            # 侧边栏（文件树）
│   │   ├── TabBar.ets             # 标签栏
│   │   ├── CodeEditor.ets         # 代码编辑器
│   │   ├── BottomPanel.ets        # 底部终端面板
│   │   ├── RightPanel.ets         # 右侧面板
│   │   ├── StatusBar.ets          # 状态栏
│   │   ├── Overlays.ets           # 搜索面板
│   │   ├── EditorPanel.ets        # 编辑器面板
│   │   ├── DeleteDialog.ets       # 删除确认对话框
│   │   └── RenameDialog.ets       # 重命名对话框
│   ├── models/
│   │   └── IDEModels.ets          # 数据模型定义
│   ├── utils/
│   │   ├── FileManager.ets        # 文件管理
│   │   ├── PythonSimulator.ets    # Python 模拟执行器
│   │   ├── RunHandler.ets         # 运行处理器
│   │   ├── TabManager.ets         # 标签页管理
│   │   ├── UndoManager.ets        # 撤销/重做管理
│   │   ├── ClipboardManager.ets   # 剪贴板管理
│   │   ├── DialogManager.ets      # 对话框管理
│   │   ├── ActionRouter.ets       # 动作路由
│   │   ├── SettingsManager.ets    # 设置管理
│   │   └── SyntaxHighlighter.ets  # 语法高亮
│   └── entryability/
│       └── EntryAbility.ets       # 应用入口
├── entry/src/main/cpp/            # C++ 原生代码
└── AppScope/                      # 应用配置
```

## 技术栈

- **开发语言**: ArkTS (HarmonyOS)
- **UI 框架**: ArkUI 声明式 UI
- **运行环境**: HarmonyOS 设备/模拟器
- **Python 引擎**: 内置 Python 模拟器（支持基本语法）

## 快速开始

1. 使用 DevEco Studio 打开项目
2. 连接 HarmonyOS 设备或启动模拟器
3. 点击运行按钮部署应用
4. 在编辑器中编写 Python 代码
5. 点击绿色 ▶ 按钮运行代码
6. 在底部终端查看运行结果

## 内置示例代码

项目包含多个 Python 示例文件：
- `main.py` - 主程序（问候、阶乘、斐波那契）
- `utils.py` - 工具函数（单词计数、字符串反转）
- `hello.py` - Hello World 示例
- `math_demo.py` - 数学运算演示
- `data_demo.py` - 数据结构演示
- `loop_demo.py` - 循环演示
- `condition_demo.py` - 条件判断演示

## 参考项目

- [eric-ide-zh_CN](https://github.com/suifengtec/eric-ide-zh_CN) - Eric6 IDE 中文语言包
- [Eric6 IDE](https://eric-ide.sourceforge.net/) - 原版 Eric6 IDE

## 许可证

本项目仅供学习交流使用。
