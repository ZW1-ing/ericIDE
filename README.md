# EricPC — 开源鸿蒙PC版 Eric6 IDE

> EricPC 是将开源 Python/Ruby IDE「Eric6」移植到开源鸿蒙PC（OpenHarmony 2in1）平台的项目。

**欢迎加入开源鸿蒙PC社区：https://harmonypc.csdn.net/**

**欢迎在PC社区平台申请新建项目：https://atomgit.com/OpenHarmonyPCDeveloper**

---

## 项目简介

EricPC 采用三层架构，将 Eric6 的完整 IDE 体验带到鸿蒙桌面端：

| 层 | 技术 | 说明 |
|----|------|------|
| UI 层 | ArkTS / ArkUI | 复刻 Eric6 完整 IDE 布局 |
| 桥接层 | C++ / NAPI | ArkTS ↔ CPython 双向通信 |
| 引擎层 | CPython 3.13 | 交叉编译 for aarch64-linux-ohos |

## 软件迁移能力（T0 / T1 / T2 阶段）

本项目按照三个阶段推进软件迁移：

### T0 阶段：UI 复刻 — ✅ 已完成

- 完整的 Eric6 风格 IDE 布局（14 个 ArkTS 组件）
- 标题栏、菜单栏、工具栏、活动栏、侧边栏、编辑区、终端面板、状态栏
- ArkTS 端 Python 模拟器（支持 print、变量、函数、循环、条件）
- 文件树管理、标签页管理、撤销/重做、剪贴板

### T1 阶段：原生引擎集成 — ✅ 已完成

- CPython 3.13 for aarch64-linux-ohos 交叉编译成功
- NAPI 桥接层实现 ArkTS ↔ CPython 双向通信
- Base64 编码安全传递代码，支持 f-string、列表推导式等复杂语法
- 真实 Python 代码执行，输出捕获并显示在终端面板

### T2 阶段：完整 IDE 功能 — 🔄 进行中

- 文件持久化（HarmonyOS 分布式文件系统）
- 调试器（断点、单步执行、变量查看）
- 插件系统
- Ruby 运行时集成

## 功能特性

### 界面布局
- **标题栏** — 深灰色背景，绿色 ERIC6 标志，窗口控制按钮
- **菜单栏** — 文件(F)、编辑(E)、搜索(U)、视图(V)、调试(D)、帮助(H)
- **工具栏** — 运行/停止、新建/保存、撤销/重做、剪切/复制/粘贴、搜索
- **活动栏** — 左侧窄条（48px），图标顶部对齐
- **侧边栏** — EXPLORER 文件树，支持文件夹展开/折叠
- **编辑区** — 标签页管理，行号同步显示
- **终端面板** — 终端/输出/问题/调试控制台，运行结果展示
- **状态栏** — 蓝色底栏，语言、文件名、光标位置、编码、版本

### 核心功能
- 📝 **代码编辑** — TextArea 代码输入，支持多文件标签页
- ▶️ **代码运行** — CPython 3.13 原生引擎执行，点击运行按钮即可
- 📁 **文件管理** — 文件树浏览，新建/保存/另存为/关闭文件
- ↩️ **撤销/重做** — 完整的编辑历史管理
- 🔍 **搜索** — 全局搜索功能
- 🐍 **Python 支持** — print、变量、函数、循环、条件、列表推导式、f-string
- 🐛 **错误提示** — 语法错误、运行时错误的友好提示
- 📋 **终端输出** — 带行号的格式化输出，区分信息/输出/错误/系统消息

## 项目结构

```
EricPC/
├── entry/src/main/ets/
│   ├── pages/                    # ArkTS UI 组件（14 个）
│   │   ├── Index.ets            # 主页面入口
│   │   ├── TitleBar.ets         # 标题栏
│   │   ├── MenuBar.ets          # 菜单栏
│   │   ├── ToolBar.ets          # 工具栏
│   │   ├── ActivityBar.ets      # 活动栏
│   │   ├── SideBar.ets          # 侧边栏（文件树）
│   │   ├── TabBar.ets           # 标签栏
│   │   ├── CodeEditor.ets       # 代码编辑器
│   │   ├── BottomPanel.ets      # 终端面板
│   │   ├── RightPanel.ets       # 右侧面板
│   │   ├── StatusBar.ets        # 状态栏
│   │   ├── Overlays.ets         # 搜索面板
│   │   ├── DeleteDialog.ets     # 删除对话框
│   │   └── RenameDialog.ets     # 重命名对话框
│   ├── models/
│   │   └── IDEModels.ets        # 数据模型
│   └── utils/                    # 工具类
│       ├── FileManager.ets      # 文件管理
│       ├── PythonSimulator.ets  # ArkTS 端模拟器（备用）
│       ├── RunHandler.ets       # 运行处理器
│       ├── TabManager.ets       # 标签管理
│       ├── UndoManager.ets      # 撤销/重做
│       └── SyntaxHighlighter.ets # 语法高亮
├── entry/src/main/cpp/
│   ├── napi_init.cpp            # NAPI 桥接（核心）
│   ├── CMakeLists.txt           # C++ 构建脚本
│   └── include/python3.13/      # Python 头文件
├── entry/libs/arm64-v8a/
│   └── libpython3.13.so         # 交叉编译的 Python 引擎
└── docs/
    └── README.md                # 项目技术文章
```

## 快速开始

### 环境要求

| 项目 | 要求 |
|------|------|
| IDE | DevEco Studio 5.0+ |
| SDK | HarmonyOS 6.0.2 (API 22) |
| Native SDK | 必须安装 |
| 设备 | 鸿蒙PC / 2in1 设备或模拟器 |

### 编译运行

1. 克隆代码：
```bash
git clone https://atomgit.com/zl2222/EricIDE.git
cd EricIDE
```

2. 使用 DevEco Studio 打开项目
3. 连接鸿蒙PC 设备或 2in1 模拟器
4. 点击 ▶ 运行

详细编译说明请参考 [README.OpenHarmony_CN.md](README.OpenHarmony_CN.md)。

## 代码托管

项目代码托管于 **AtomGit**：

- **仓库地址**：https://atomgit.com/zl2222/EricIDE
- **镜像地址**：https://github.com/ZW1-ing/ericIDE

## 技术栈

| 技术 | 说明 |
|------|------|
| 开发语言 | ArkTS (TypeScript) |
| UI 框架 | ArkUI 声明式 UI |
| 原生代码 | C++ (NAPI 桥接) |
| Python 引擎 | CPython 3.13 (arm64) |
| 构建工具 | hvigor + CMake |
| 目标平台 | HarmonyOS Phone / 2in1 (PC) |

## 参考项目

- [eric-ide-zh_CN](https://github.com/suifengtec/eric-ide-zh_CN) — Eric6 IDE 中文语言包
- [Eric6 IDE](https://eric-ide.sourceforge.net/) — 原版 Eric6 IDE

## 社区

**欢迎加入开源鸿蒙PC社区：https://harmonypc.csdn.net/**

**欢迎在PC社区平台申请新建项目：https://atomgit.com/OpenHarmonyPCDeveloper**
