

---

# 开源鸿蒙PC移植实战：Eric IDE登陆鸿蒙桌面端

> **摘要**：本文记录了将开源 Python/Ruby IDE「Eric」移植到开源鸿蒙PC平台的完整过程。项目采用 ArkTS 复刻 Eric6 的完整 IDE 布局，通过交叉编译 CPython 3.13 for aarch64-linux-ohos，并使用 NAPI 桥接层实现 ArkTS 与 CPython 引擎的双向通信。目前项目已支持代码编辑、文件管理、Python 真实执行等核心功能，运行于鸿蒙PC（2in1设备）上。代码托管于 AtomGit。
#欢迎加入开源鸿蒙PC社区

**欢迎加入开源鸿蒙PC社区：https://harmonypc.csdn.net/**

**欢迎在PC社区平台申请新建项目：https://atomgit.com/OpenHarmonyPCDeveloper**
## 软件迁移能力与阶段划分（T0 / T1 / T2）

本项目将开源桌面 IDE 的迁移过程拆分为三个可验收阶段，便于社区协作、问题定位和后续发布：

| 阶段 | 迁移目标 | 当前状态 | 核心验收标准 |
|------|----------|----------|--------------|
| **T0** | 先完成界面复刻与基础编辑闭环 | ✅ 已完成 | 能打开项目、编辑代码、管理文件并在 ArkTS 端运行基础示例 |
| **T1** | 接入真实 CPython 运行时 | ✅ 已完成 | 能在鸿蒙设备上执行完整 Python 语法、捕获输出并展示 traceback |
| **T2** | 补齐桌面 IDE 的完整能力 | 🔄 进行中 | 完成持久化、调试、扩展能力和真机回归后再进入发布阶段 |

### T0 阶段：界面复刻与基础编辑 — ✅ 已完成

- 复刻标题栏、菜单栏、工具栏、活动栏、侧边栏、编辑区、终端面板和状态栏。
- 支持多标签页、文件树、新建/保存/重命名、撤销重做和剪贴板操作。
- ArkTS 端保留 PythonSimulator 作为无原生环境时的基础运行兜底。
- **验收结果**：项目可启动，界面结构完整，基础编辑操作可以形成闭环。

### T1 阶段：原生运行时集成 — ✅ 已完成

- 交叉编译 CPython 3.13 for `aarch64-linux-ohos`，将运行时随 HAP 分发。
- 通过 NAPI 和 Base64 编码在 ArkTS 与 CPython 之间安全传递代码。
- 支持 f-string、列表推导式、函数、循环、标准库导入和 traceback 输出。
- **验收结果**：真机/模拟器点击运行后能返回真实输出，错误代码能显示可读的异常信息。

### T2 阶段：完整 IDE 能力与发布准备 — 🔄 进行中

- 文件持久化与项目级导入，避免应用重启后丢失编辑内容。
- 调试器能力：断点、单步执行、变量查看和调用栈展示。
- 插件/扩展机制以及更多语言的编辑识别；运行时仍以 Python 为主。
- 完成 phone/2in1 真机回归、签名、隐私政策、第三方声明和发布审计。
- **验收结果**：功能稳定、文档可复现、发布门禁通过后进入正式发布。

## 一、项目背景

Eric6 是一款基于 PyQt5 的开源 Python/Ruby 集成开发环境（IDE），以轻量、快速著称。随着开源鸿蒙（OpenHarmony）生态的发展，越来越多的桌面端应用需要移植到鸿蒙PC平台。

**开源鸿蒙PC** 作为 HarmonyOS 生态的重要组成部分，基于 OpenHarmony 内核，支持 2in1 设备形态。将传统桌面端 IDE 移植到鸿蒙PC，不仅能够丰富鸿蒙桌面生态，也为开发者提供了在鸿蒙平台上编写和运行 Python 代码的能力。

### 1.1 为什么选择 Eric

| 特性 | Eric | VS Code | PyCharm |
|------|-------|---------|---------|
| 体积 | 极小（< 5MB） | 中等（~100MB） | 极大（> 1GB） |
| 启动速度 | 毫秒级 | 秒级 | 十秒级 |
| Python支持 | 原生 | 插件 | 原生 |
| Ruby支持 | 原生 | 插件 | 不支持 |
| 移植难度 | 低 | 中 | 高 |

Eric 的简洁架构使其成为移植到鸿蒙PC 的理想选择。

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

### 2.1 UI 层：ArkTS 复刻 Eric 布局

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
EricPC/
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

## 四、ArkTS 开发细节

### 4.1 状态管理：@State / @Prop / @Link

ArkTS 使用装饰器管理组件状态，这是与传统 TypeScript 最大的差异之一。

| 装饰器 | 方向 | 用途 |
|--------|------|------|
| `@State` | 组件内部 | 声明本地状态，驱动 UI 刷新 |
| `@Prop` | 父 → 子（单向） | 接收父组件数据，子组件改动不回传 |
| `@Link` | 父 ↔ 子（双向） | 双向绑定，子组件改动会同步父组件 |

以终端面板为例，运行结果需要从主页面传递到终端组件，且终端可能需要更新滚动位置，因此使用 `@Link`：

```typescript
// 主页面（父组件）
BottomPanel({ consoleEntries: $consoleEntries })

// 终端组件（子组件）
@Component
export struct BottomPanel {
  @Link consoleEntries: ConsoleEntry[]
  // ...
}
```

**踩坑记录**：最初使用 `@Prop` 传递运行结果数组，发现点击运行后终端没有任何反应。原因是 `@Prop` 是单向同步，且对自定义类数组的变更检测不敏感。改用 `@Link` 后问题解决。

### 4.2 组件通信与事件回调

子组件不能直接修改父组件状态，需要通过回调函数上抛事件：

```typescript
// 子组件声明回调
@Component
export struct ToolBar {
  onRun: () => void = () => {}
  // 点击运行按钮时
  // this.onRun()
}

// 父组件传入实现
ToolBar({
  onRun: () => { this.doRun() }
})
```

### 4.3 ArkTS 的语法限制

ArkTS 是 TypeScript 的超集，但比标准 TypeScript 严格得多：

- **禁止 `any` / `unknown`**：所有类型必须显式声明
- **禁止 catch 子句类型注解**：只能写 `catch (e)`，不能写 `catch (e: Error)`
- **`@Entry` 组件只能有一个根节点**：且必须是容器组件
- **部分 Web 属性不可用**：如 `selectable`、`wordWrap`、`cursorColor`

示例（正确的 ArkTS 写法）：

```typescript
// 错误：catch (e: Error)
// 正确：
try {
  let result: string = RunHandler.execute(code, Language.PYTHON);
} catch (e) {
  let msg: string = String(e);
}
```

## 五、CPython 嵌入详解

### 5.1 为什么选择嵌入 CPython 而非模拟执行

早期版本使用 ArkTS 编写的 Python 模拟器（`PythonSimulator.ets`），但模拟器存在明显局限：

| 对比项 | ArkTS 模拟器 | CPython 嵌入 |
|--------|-------------|--------------|
| 语法支持 | 基础（print/变量/循环） | 完整 Python 语法 |
| f-string | 不支持 | 支持 |
| 列表推导式 | 部分支持 | 完整支持 |
| 标准库 | 无 | 33 内置 + 64 共享模块 |
| 错误栈 | 简单提示 | 完整 traceback |
| 执行速度 | 慢 | 原生速度 |

因此 T1 阶段引入了真正的 CPython 引擎。

### 5.2 Python C API 调用流程

嵌入 CPython 的核心流程：

```cpp
// 1. 初始化（只执行一次）
Py_Initialize();

// 2. 获取主模块的全局字典
PyObject* mainModule = PyImport_AddModule("__main__");
PyObject* globalDict = PyModule_GetDict(mainModule);

// 3. 执行 Python 代码字符串
PyObject* result = PyRun_String(
    code,
    Py_file_input,   // 文件模式（可执行多行）
    globalDict,
    globalDict
);

// 4. 从全局字典读取变量
PyObject* output = PyDict_GetItemString(globalDict, "_output");

// 5. 转换为 C 字符串
const char* text = PyUnicode_AsUTF8(output);

// 6. 清理
Py_DECREF(result);
Py_Finalize();
```

### 5.3 输出捕获原理

CPython 默认将 `print()` 输出到系统 stdout，但在 HarmonyOS 应用中没有终端。因此需要用 Python 的 `io.StringIO` 重定向输出：

```python
import sys, io
_capturer = io.StringIO()
_old_stdout = sys.stdout
sys.stdout = _capturer        # 重定向 print 输出

exec(user_code, {'__name__': '__main__'})

sys.stdout = _old_stdout      # 恢复输出
_output = _capturer.getvalue()  # 获取捕获的内容
```

同样地，`sys.stderr` 也被重定向，这样异常堆栈也能被捕获并显示在终端面板。

### 5.4 Base64 编码的作用

用户代码中可能包含引号、三引号、换行等特殊字符，直接拼接进 Python 字符串会破坏转义。解决办法是先做 Base64 编码：

```cpp
// C++ 端编码
std::string encoded = base64Encode(userCode);

// 生成的 Python 脚本中解码
"_code = base64.b64decode('" + encoded + "').decode('utf-8')"
```

这样无论用户代码包含什么字符，都能安全传递。

## 六、性能优化

### 6.1 异步执行避免 UI 卡顿

Python 代码可能执行很长时间，如果在 ArkUI 主线程运行会导致界面冻结。解决方案是将执行放到后台线程：

```typescript
// 伪代码：异步执行
this.isRunning = true;
// 切换到后台任务执行
let output: string = await runPythonAsync(code);
// 回到主线程更新 UI
this.consoleEntries = formatOutput(output);
this.isRunning = false;
```

### 6.2 动态库加载优化

`libpython3.13.so` 约 20MB，首次加载较慢。优化措施：

- 使用 `IMPORTED` 方式链接，避免重复打包
- Python 引擎只初始化一次（使用 `g_isPythonInitialized` 标志）
- 后续运行代码直接复用已初始化的解释器

```cpp
static bool g_isPythonInitialized = false;

if (!g_isPythonInitialized) {
    Py_Initialize();
    g_isPythonInitialized = true;
}
```

### 6.3 行号同步显示

代码编辑器需要行号随代码滚动同步。实现方式是将行号列与 TextArea 放在同一 Row 中，行号高度根据字体大小动态计算：

```typescript
Row() {
  // 行号列
  Column() {
    ForEach(this.codeLines, (_line: string, idx: number) => {
      Text((idx + 1).toString())
        .fontSize(this.settings.fontSize - 2)
        .height(this.settings.fontSize * 1.6)
    })
  }
  .width(48)

  // 代码编辑区
  TextArea({ text: this.editorContent })
    .layoutWeight(1)
}
```

## 七、PC 适配要点

### 9.1 设备类型声明

在 `module.json5` 中声明支持 2in1（PC）设备：

```json5
"deviceTypes": ["phone", "2in1"]
```

### 9.2 布局适配参数

| 区域 | 宽度 | 高度 | 说明 |
|------|------|------|------|
| 活动栏 | 48px | 100% | 图标顶部对齐 |
| 侧边栏 | 200px | 100% | 可折叠 |
| 编辑区 | 自适应 | 100% | layoutWeight(1) |
| 底部面板 | 100% | 180px | 可折叠 |
| 状态栏 | 100% | 22px | 固定底部 |

### 9.3 原生库加载

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

## 八、功能演示

### 8.1 运行 Hello World

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
![image.png](https://raw.atomgit.com/user-images/assets/10556976/e05e7eca-e722-4b9c-a7c0-d562ca5551a3/image.png 'image.png')
### 8.2 运行函数和循环

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
![image.png](https://raw.atomgit.com/user-images/assets/10556976/32d900d7-dbbd-4331-b4d9-f65f0a067572/image.png 'image.png')
## 九、遇到的问题与解决方案

### 9.1 Python.h 找不到

**问题**：C++ 编译时报 `Python.h: No such file or directory`

**解决**：在 `CMakeLists.txt` 中添加 Python 头文件路径：

```cmake
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include/python3.13
)
```
![image.png](https://raw.atomgit.com/user-images/assets/10556976/8f8e8b41-3746-4d0d-9456-60a7db0a894e/image.png 'image.png')
### 9.2 libpython3.13.so 加载失败

**问题**：运行时提示 `cannot load library`

**解决**：确保 `.so` 文件位于 `entry/libs/arm64-v8a/` 目录下，且 CMake 中使用相对路径引用。

### 9.3 ArkTS 组件 @Prop 与 @Link 的区别

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

## 十、构建与运行

要求 DevEco Studio、HarmonyOS SDK 6.0.2/API 22 和 Native SDK。

```bash
# 克隆代码
git clone https://atomgit.com/zl2222/EricIDE.git
cd EricIDE

# 命令行构建
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home

/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  --mode module -p product=default -p buildMode=release assembleHap --no-daemon
```

签名产物位于：

```text
entry/build/default/outputs/default/entry-default-signed.hap
```

也可以直接用 DevEco Studio 打开项目，连接鸿蒙PC 设备或 2in1 模拟器后点击 ▶ 运行。

详细编译说明请参考 [README.OpenHarmony_CN.md](README.OpenHarmony_CN.md)。

## 十一、代码托管

项目代码托管于 **AtomGit**：

- **仓库地址**：https://atomgit.com/zl2222/EricIDE
- **镜像地址**：https://github.com/ZW1-ing/ericIDE

```bash
git clone https://atomgit.com/zl2222/EricIDE.git
```

## 十二、踩坑经验总结

在整个移植过程中，我们遇到了不少问题，这里整理出最有代表性的几个，供后来者参考。

### 12.1 交叉编译的坑

**问题**：`configure` 阶段报 `checking for sqlite3 >= 3.15.2... no`，导致 `_sqlite3` 模块缺失。

**原因**：交叉编译时找不到目标平台的 sqlite3 库，`configure` 会自动跳过。

**解决**：对于 IDE 场景，sqlite3 并非必需。通过 `ac_cv_*` 变量跳过不必要的检查：

```bash
./configure     ac_cv_file__dev_ptmx=yes     ac_cv_file__dev_ptc=no     ac_cv_header_libintl_h=no
```

### 12.2 动态库路径的坑

**问题**：CMake 中写绝对路径 `/Users/xxx/.../libpython3.13.so`，别人拉取代码后编译失败。

**原因**：绝对路径只在原作者机器上有效。

**解决**：改用相对路径，基于 `CMAKE_CURRENT_SOURCE_DIR` 计算：

```cmake
IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../../../../libs/arm64-v8a/libpython3.13.so"
```

### 12.3 ArkTS 作用域的坑

**问题**：`Cannot find name 'lastBracketCol'`。

**原因**：变量在 for 循环内声明，但在循环外使用。ArkTS 的块级作用域检查比普通 TypeScript 更严格。

**解决**：将变量声明提升到函数级别。

## 十三、总结与展望

### 13.1 成果回顾

本文介绍了将开源 Eric6 IDE 移植到开源鸿蒙PC 平台的完整技术方案。通过 ArkTS UI 复刻、CPython 3.13 交叉编译、NAPI 桥接三层架构，实现了在鸿蒙PC 上编写和运行 Python 代码的能力。

核心成果：

- **完整的 IDE 界面**：14 个 ArkTS 组件，1:1 复刻 Eric6 布局
- **真实的 Python 执行**：内嵌 CPython 3.13，支持完整语法和标准库
- **稳定的桥接层**：NAPI + Base64 编码，安全传递任意代码
- **PC 适配**：支持 2in1 设备形态，布局自适应

### 13.2 未来规划

| 方向 | 内容 | 优先级 |
|------|------|--------|
| 文件持久化 | 使用 HarmonyOS 分布式文件系统保存项目 | 高 |
| 调试器 | 断点、单步执行、变量查看 | 高 |
| 多语言 | 集成 Ruby、JavaScript 运行时 | 中 |
| 插件系统 | 支持自定义扩展 | 中 |
| 性能 | 优化启动速度和内存占用 | 中 |

### 13.3 社区贡献

项目代码已开源在 AtomGit，欢迎社区开发者参与贡献。无论是修复 Bug、完善文档，还是提交新功能，都非常欢迎。

贡献方式：

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/xxx`
3. 提交改动：`git commit -m "feat: xxx"`
4. 推送分支：`git push origin feature/xxx`
5. 创建 Pull Request

**欢迎加入开源鸿蒙PC社区，一起推动开源软件在鸿蒙生态的落地！**

---

**参考资料：**


- [Eric6 IDE 官网](https://eric-ide.sourceforge.net/)
- [eric-ide-zh_CN 中文项目](https://github.com/suifengtec/eric-ide-zh_CN)
- [CPython 官方仓库](https://github.com/python/cpython)
- [DevEco Studio 开发指南](https://developer.huawei.com/consumer/cn/deveco-studio/)

**欢迎加入开源鸿蒙PC社区：https://harmonypc.csdn.net/**

**欢迎在PC社区平台申请新建项目：https://atomgit.com/OpenHarmonyPCDeveloper**
