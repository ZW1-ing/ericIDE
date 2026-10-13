---
title: "开源鸿蒙PC移植实战：Eric6 IDE登陆鸿蒙桌面端"
author: "EricPC 开发团队"
date: 2026-10-13
description: "本文详细介绍如何将开源 Python/Ruby IDE——Eric6 移植到开源鸿蒙PC（OpenHarmony 2in1）平台，包含完整的ArkTS UI复刻、CPython 3.13交叉编译与NAPI桥接技术方案。"
keywords: ["开源鸿蒙", "鸿蒙PC", "OpenHarmony", "鸿蒙桌面端", "软件移植", "Eric6", "ArkTS", "CPython", "NAPI"]
schema:
  type: "Article"
  headline: "开源鸿蒙PC移植实战：Eric6 IDE登陆鸿蒙桌面端"
---

# 欢迎加入开源鸿蒙PC社区

**欢迎加入开源鸿蒙PC社区：https://harmonypc.csdn.net/**

**欢迎在PC社区平台申请新建项目：https://atomgit.com/OpenHarmonyPCDeveloper**

---

# 开源鸿蒙PC移植实战：Eric6 IDE登陆鸿蒙桌面端

> **摘要**：本文记录了将开源 Python/Ruby IDE「Eric6」移植到开源鸿蒙PC平台的完整过程。项目采用 ArkTS 复刻 Eric6 的完整 IDE 布局，通过交叉编译 CPython 3.13 for aarch64-linux-ohos，并使用 NAPI 桥接层实现 ArkTS 与 CPython 引擎的双向通信。目前项目已支持代码编辑、文件管理、Python 真实执行等核心功能，运行于鸿蒙PC（2in1设备）上。代码托管于 AtomGit。

## 一、项目背景

Eric6 是一款基于 PyQt5 的开源 Python/Ruby 集成开发环境（IDE），以轻量、快速著称。随着开源鸿蒙（OpenHarmony）生态的发展，越来越多的桌面端应用需要移植到鸿蒙PC平台。

**开源鸿蒙PC** 作为 HarmonyOS 生态的重要组成部分，基于 OpenHarmony 内核，支持 2in1 设备形态。将传统桌面端 IDE 移植到鸿蒙PC，不仅能够丰富鸿蒙桌面生态，也为开发者提供了在鸿蒙平台上编写和运行 Python 代码的能力。

### 1.1 为什么选择 Eric6

| 特性 | Eric6 | VS Code | PyCharm |
|------|-------|---------|---------|
| 体积 | 极小（< 5MB） | 中等（~100MB） | 极大（> 1GB） |
| 启动速度 | 毫秒级 | 秒级 | 十秒级 |
| Python支持 | 原生 | 插件 | 原生 |
| Ruby支持 | 原生 | 插件 | 不支持 |
| 移植难度 | 低 | 中 | 高 |

Eric6 的简洁架构使其成为移植到鸿蒙PC 的理想选择。

## 二、技术架构

整个项目分为三层：

```
┌─────────────────────────────────────┐
│        ArkTS UI 层（ArkUI）          │
│  TitleBar / ToolBar / CodeEditor    │
├─────────────────────────────────────┤
│        NAPI 桥接层（C++）            │
│  napi_init.cpp → PyRun_String       │
├─────────────────────────────────────┤
│      CPython 3.13 引擎（C）          │
│  libpython3.13.so (aarch64-ohos)    │
└─────────────────────────────────────┘
```

### 2.1 UI 层：ArkTS 复刻 Eric6 布局

UI 层使用 ArkTS（HarmonyOS 的声明式 UI 框架）完整复刻了 Eric6 的 IDE 布局：

- **标题栏**：深灰色背景，绿色 ERIC6 标志，窗口控制按钮
- **菜单栏**：文件(F)、编辑(E)、搜索(U)、视图(V)、调试(D)、帮助(H)
- **工具栏**：运行/停止、新建/保存、撤销/重做、搜索
- **活动栏**：左侧窄条（48px），图标顶部对齐
- **侧边栏**：EXPLORER 文件树，支持展开/折叠
- **编辑区**：标签页管理，行号同步显示
- **终端面板**：终端/输出/问题/调试控制台
- **状态栏**：语言、文件名、光标位置、编码信息

### 2.2 桥接层：NAPI 实现 ArkTS 与 CPython 通信

核心桥接代码位于 `entry/src/main/cpp/napi_init.cpp`，通过 Base64 编码安全传递代码，避免了特殊字符转义问题：

```cpp
static napi_value RunPythonCode(napi_env env, napi_callback_info info) {
    // 1. 获取 ArkTS 传入的 Python 代码
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 2. Base64 编码（避免引号/三引号转义问题）
    std::string encoded = base64Encode(std::string(codeBuffer.data(), codeLen));

    // 3. 构建 Python 执行脚本
    std::string pyScript =
        "import sys, io, base64, traceback\n"
        "_code = base64.b64decode('" + encoded + "').decode('utf-8')\n"
        "_capturer = io.StringIO()\n"
        "sys.stdout = _capturer\n"
        "sys.stderr = _capturer\n"
        "try:\n"
        "    exec(_code, {'__name__': '__main__'})\n"
        "except Exception:\n"
        "    traceback.print_exc()\n"
        "_output = _capturer.getvalue()\n";

    // 4. 通过 CPython API 执行
    PyObject* mainModule = PyImport_AddModule("__main__");
    PyObject* globalDict = PyModule_GetDict(mainModule);
    PyObject* evalRes = PyRun_String(pyScript.c_str(), Py_file_input, globalDict, globalDict);

    // 5. 捕获输出返回给 ArkTS
    PyObject* outputObj = PyDict_GetItemString(globalDict, "_output");
    const char* utf8Chars = PyUnicode_AsUTF8(outputObj);

    napi_value returnValue;
    napi_create_string_utf8(env, utf8Chars, NAPI_AUTO_LENGTH, &returnValue);
    return returnValue;
}
```

ArkTS 端调用方式：

```typescript
import libentry from 'libentry.so';

// 运行 Python 代码
let result: string = libentry.runPython(editorContent);
consoleEntries = result.split('\n');
```

### 2.3 引擎层：交叉编译 CPython 3.13

CPython 3.13 需要使用 OpenHarmony SDK 的 LLVM/Clang 工具链进行交叉编译，目标平台为 `aarch64-linux-ohos`。

**交叉编译步骤：**

```bash
# 1. 设置 OpenHarmony Native SDK 路径
export OHOS_SDK=/path/to/oh.openharmonySDK/20/native

# 2. 配置交叉编译环境
export CC="$OHOS_SDK/llvm/bin/clang --target=aarch64-linux-ohos"
export CXX="$OHOS_SDK/llvm/bin/clang++ --target=aarch64-linux-ohos"
export AR="$OHOS_SDK/llvm/bin/llvm-ar"
export RANLIB="$OHOS_SDK/llvm/bin/llvm-ranlib"

# 3. 配置 Python 构建选项
cd Python-3.13.2
make clean
./configure \
    --host=aarch64-linux-gnu \
    --build=aarch64-apple-darwin \
    --enable-shared \
    --disable-ipv6 \
    --with-build-python=$(which python3.13) \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no

# 4. 编译（约 10-15 分钟）
make -j4

# 5. 拷贝动态库到项目
cp libpython3.13.so.1.0 ../EricPC_MVP2/entry/libs/arm64-v8a/libpython3.13.so
```

**编译结果：**
- 生成 `libpython3.13.so`（约 20MB），支持 33 个内置模块 + 64 个共享模块
- 包含 `_decimal`、`_elementtree`、`pyexpat`、`_sha2` 等核心模块
- 不含 `_ssl`、`_sqlite3` 等依赖外部库的模块（鸿蒙PC 上暂不需要）

## 三、项目结构

```
EricPC_MVP2/
├── entry/src/main/ets/
│   ├── pages/                    # ArkTS UI 组件
│   │   ├── Index.ets            # 主页面入口
│   │   ├── TitleBar.ets         # 标题栏
│   │   ├── MenuBar.ets          # 菜单栏
│   │   ├── ToolBar.ets          # 工具栏
│   │   ├── ActivityBar.ets      # 活动栏
│   │   ├── SideBar.ets          # 侧边栏（文件树）
│   │   ├── CodeEditor.ets       # 代码编辑器
│   │   ├── BottomPanel.ets      # 终端面板
│   │   └── StatusBar.ets        # 状态栏
│   ├── models/
│   │   └── IDEModels.ets        # 数据模型
│   └── utils/
│       ├── PythonSimulator.ets  # ArkTS 端 Python 模拟器（备用）
│       ├── RunHandler.ets       # 运行处理器
│       └── FileManager.ets      # 文件管理
├── entry/src/main/cpp/
│   ├── napi_init.cpp            # NAPI 桥接（核心）
│   ├── CMakeLists.txt           # C++ 构建脚本
│   └── include/python3.13/      # Python 头文件
└── entry/libs/arm64-v8a/
    └── libpython3.13.so         # 交叉编译的 Python 引擎
```

## 四、PC 适配要点

### 4.1 设备类型声明

在 `module.json5` 中声明支持 2in1（PC）设备：

```json5
"deviceTypes": ["phone", "2in1"]
```

### 4.2 布局适配参数

| 区域 | 宽度 | 高度 | 说明 |
|------|------|------|------|
| 活动栏 | 48px | 100% | 图标顶部对齐 |
| 侧边栏 | 200px | 100% | 可折叠 |
| 编辑区 | 自适应 | 100% | layoutWeight(1) |
| 底部面板 | 100% | 180px | 可折叠 |
| 状态栏 | 100% | 22px | 固定底部 |

### 4.3 原生库加载

鸿蒙PC 设备使用 arm64 架构，`libpython3.13.so` 需要放置在 `entry/libs/arm64-v8a/` 目录下。CMake 构建时通过相对路径引用：

```cmake
add_library(python SHARED IMPORTED)
set_target_properties(python PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../../../../libs/arm64-v8a/libpython3.13.so"
)
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    python
)
```

## 五、功能演示

### 5.1 运行 Hello World

在编辑器中输入：

```python
print("Hello, HarmonyOS PC!")
print("Eric6 IDE is running on OpenHarmony")
```

点击工具栏绿色 ▶ 按钮，底部终端面板显示：

```
▶ 运行代码
[1] Hello, HarmonyOS PC!
[2] Eric6 IDE is running on OpenHarmony
✓ 运行完成 | 输出 2 行 | 耗时 16ms
```

### 5.2 运行函数和循环

```python
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

for i in range(5):
    print(f"factorial({i}) = {factorial(i)}")
```

输出：

```
[1] factorial(0) = 1
[2] factorial(1) = 1
[3] factorial(2) = 2
[4] factorial(3) = 6
[5] factorial(4) = 24
```

## 六、移植阶段划分

本项目按照以下三个阶段推进：

| 阶段 | 目标 | 状态 |
|------|------|------|
| **T0** | UI 复刻完成，ArkTS 模拟器可运行基础 Python | ✅ 已完成 |
| **T1** | CPython 原生引擎集成，支持真实 Python 执行 | ✅ 已完成 |
| **T2** | 完整 IDE 功能（调试器、插件系统、文件持久化） | 🔄 进行中 |

### T0 阶段成果
- 完整的 Eric6 风格 IDE 布局（14 个 ArkTS 组件）
- ArkTS 端 Python 模拟器（支持 print、变量、函数、循环、条件）
- 文件树管理、标签页管理、撤销/重做

### T1 阶段成果
- CPython 3.13 for aarch64-linux-ohos 交叉编译成功
- NAPI 桥接层实现 ArkTS ↔ CPython 双向通信
- Base64 编码安全传递代码，支持 f-string、列表推导式等复杂语法

### T2 阶段规划
- 文件持久化（HarmonyOS 分布式文件系统）
- 调试器（断点、单步执行、变量查看）
- 插件系统
- Ruby 运行时集成

## 七、遇到的问题与解决方案

### 7.1 Python.h 找不到

**问题**：C++ 编译时报 `Python.h: No such file or directory`

**解决**：在 `CMakeLists.txt` 中添加 Python 头文件路径：

```cmake
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include/python3.13
)
```

### 7.2 libpython3.13.so 加载失败

**问题**：运行时提示 `cannot load library`

**解决**：确保 `.so` 文件位于 `entry/libs/arm64-v8a/` 目录下，且 CMake 中使用相对路径引用。

### 7.3 ArkTS 组件 @Prop 与 @Link 的区别

**问题**：子组件不响应父组件状态变化

**解决**：
- `@Prop`：单向同步（父→子），适合只读数据
- `@Link`：双向同步（父↔子），适合需要更新父组件的数据

终端输出使用 `@Link` 实现双向绑定：

```typescript
// 父组件
BottomPanel({ consoleEntries: $consoleEntries })

// 子组件
@Link consoleEntries: ConsoleEntry[]
```

## 八、代码托管

项目代码托管于 **AtomGit**：

- **仓库地址**：https://atomgit.com/zl2222/EricIDE
- **镜像地址**：https://github.com/ZW1-ing/ericIDE

### 克隆代码

```bash
git clone https://atomgit.com/zl2222/EricIDE.git
cd EricIDE
```

### 编译运行

1. 使用 DevEco Studio 5.0+ 打开项目
2. SDK 版本：HarmonyOS 6.0.2 (API 22)
3. 连接鸿蒙PC 设备或 2in1 模拟器
4. 点击 ▶ 运行

详细编译说明请参考仓库中的 `README.OpenHarmony_CN.md`。

## 九、总结

本文介绍了将开源 Eric6 IDE 移植到开源鸿蒙PC 平台的完整技术方案。通过 ArkTS UI 复刻、CPython 3.13 交叉编译、NAPI 桥接三层架构，实现了在鸿蒙PC 上编写和运行 Python 代码的能力。

项目代码已开源在 AtomGit，欢迎社区开发者参与贡献。

---

**参考资料：**

- [OpenHarmony 官方文档](https://gitee.com/openharmony/docs)
- [Eric6 IDE 官网](https://eric-ide.sourceforge.net/)
- [eric-ide-zh_CN 中文项目](https://github.com/suifengtec/eric-ide-zh_CN)
- [CPython 官方仓库](https://github.com/python/cpython)
- [DevEco Studio 开发指南](https://developer.huawei.com/consumer/cn/deveco-studio/)
