# EricPC — HarmonyOS OpenHarmony 编译运行指南

> 本指南确保任何人按步骤操作都能完整复刻项目，不会出现错误。

---

## 一、环境准备

### 1.1 安装 DevEco Studio

| 项目 | 要求 |
|------|------|
| IDE | DevEco Studio 5.0.0 Release 或更高版本 |
| 下载地址 | https://developer.huawei.com/consumer/cn/deveco-studio/ |
| 操作系统 | Windows 10/11 64-bit 或 macOS 11+ |

安装完成后，打开 DevEco Studio，按提示完成首次配置向导。

### 1.2 安装 SDK

1. 打开 **File → Settings → SDK**（macOS: **DevEco Studio → Preferences → SDK**）
2. 勾选 **HarmonyOS** 选项卡
3. 安装以下版本：
   - **HarmonyOS SDK**: **6.0.2 (API 22)**
   - **Native SDK**: 勾选安装（项目包含 C++ 原生代码）
4. 点击 **Apply** 等待下载完成

### 1.3 安装工具链

确保已安装以下工具（DevEco Studio 通常自动安装）：

- ** hvigor 构建工具** — 首次打开项目时自动下载
- **CMake 3.5+** — 构建原生代码需要
- **Ninja** — CMake 构建后端

---

## 二、获取源码

### 方式一：Git 克隆

```bash
git clone https://github.com/ZW1-ing/ericIDE.git
```

### 方式二：下载 ZIP

打开 https://github.com/ZW1-ing/ericIDE ，点击 **Code → Download ZIP**，解压到任意目录。

---

## 三、打开项目

1. 打开 **DevEco Studio**
2. 点击 **Open**（或 **File → Open**）
3. 选择 `ericIDE` 文件夹（包含 `build-profile.json5` 的根目录）
4. 等待项目同步完成（右下角进度条消失）
5. 首次打开会自动下载 hvigor 依赖，请确保网络通畅

> **注意**：项目根目录下必须有 `build-profile.json5`、`oh-package.json5`、`hvigorfile.ts` 这三个文件，否则目录选错了。

---

## 四、配置签名

真机运行必须配置签名，模拟器可以跳过此步。

### 4.1 自动生成签名（推荐）

1. **Build → Generate Key and CSR**（或 **Build → Edit Build Types**）
2. 在 **Signing Configs** 中点击 **+** 添加新配置
3. 勾选 **Automatically generate signature**
4. DevEco Studio 会自动创建调试证书
5. 等待证书申请完成（约 1-2 分钟）

### 4.2 手动配置

如果自动签名失败：
1. 访问 https://developer.huawei.com/consumer/cn/ 申请开发者账号
2. 在 **AppGallery Connect** 创建应用并获取签名信息
3. 在 **Project Structure → Modules → entry → Signing Configs** 中填入

---

## 五、连接设备

### 5.1 HarmonyOS 真机

1. 手机开启 **开发者模式**：**设置 → 关于手机 → 连续点击版本号 7 次**
2. 开启 **USB 调试**：**设置 → 系统和更新 → 开发人员选项 → USB 调试**
3. 用 USB 数据线连接电脑
4. 手机弹窗选择 **允许调试**
5. DevEco Studio 顶部工具栏应显示设备名称

### 5.2 HarmonyOS 模拟器

1. **Tools → Device Manager**
2. 点击 **+** 创建模拟器
3. 选择 **Phone** 或 **2in1（PC）** 设备模板
4. 下载系统镜像（首次需要，约 2-3GB）
5. 启动模拟器
6. DevEco Studio 顶部工具栏应显示模拟器名称

---

## 六、编译项目

### 6.1 全量编译

```bash
# 在项目根目录执行（也可以用 DevEco Studio 图形界面）
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

或在 DevEco Studio 中：
- 点击菜单 **Build → Build Hap(s)/App(s) → Build Hap(s)**

### 6.2 编译原生 C++ 模块

项目包含 C++ 原生代码（Python 引擎桥接），会自动编译。

如果编译报错找不到 `Python.h`：
- 检查 `entry/src/main/cpp/CMakeLists.txt` 中的路径
- 确保 `entry/libs/arm64-v8a/libpython3.13.so` 文件存在

### 6.3 编译产物

编译成功后，HAP 文件位于：
```
entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 七、运行项目

### 方式一：DevEco Studio 运行

1. 顶部工具栏选择目标设备（真机或模拟器）
2. 点击绿色 **▶ Run** 按钮（或 **Run → Run 'entry'**）
3. 等待安装完成，应用自动启动

### 方式二：命令行安装

```bash
# 安装到设备
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# 启动应用
hdc shell aa start -a EntryAbility -b com.ericide.entry
```

### 方式三：预览器

1. 打开任意 `.ets` 文件
2. 点击右上角 **Previewer** 面板
3. 选择预览设备类型为 **2in1**（PC 模式）

> **注意**：预览器中 Python 执行功能不可用（使用 Mock 模拟），需要真机或模拟器才能完整运行。

---

## 八、项目结构说明

```
ericIDE/
├── build-profile.json5              # 构建配置（SDK 版本、签名）
├── oh-package.json5                 # 依赖管理
├── hvigorfile.ts                    # 构建脚本
├── AppScope/                        # 应用级配置
│   ├── app.json5                    # 应用信息
│   └── resources/                   # 应用资源
├── entry/                           # 主模块
│   ├── build-profile.json5          # 模块构建配置
│   ├── oh-package.json5             # 模块依赖
│   ├── libs/
│   │   └── arm64-v8a/
│   │       └── libpython3.13.so     # Python 动态库（20MB）
│   └── src/main/
│       ├── ets/                     # ArkTS 源码
│       │   ├── pages/
│       │   │   ├── Index.ets        # 主页面入口
│       │   │   ├── TitleBar.ets     # 标题栏
│       │   │   ├── MenuBar.ets      # 菜单栏
│       │   │   ├── ToolBar.ets      # 工具栏
│       │   │   ├── ActivityBar.ets  # 活动栏（左侧图标）
│       │   │   ├── SideBar.ets      # 侧边栏（文件树）
│       │   │   ├── TabBar.ets       # 标签栏
│       │   │   ├── CodeEditor.ets   # 代码编辑器
│       │   │   ├── BottomPanel.ets  # 底部终端面板
│       │   │   ├── RightPanel.ets   # 右侧面板
│       │   │   ├── StatusBar.ets    # 状态栏
│       │   │   ├── Overlays.ets     # 搜索面板
│       │   │   ├── EditorPanel.ets  # 编辑器面板
│       │   │   ├── DeleteDialog.ets # 删除对话框
│       │   │   └── RenameDialog.ets # 重命名对话框
│       │   ├── models/
│       │   │   └── IDEModels.ets    # 数据模型
│       │   └── utils/
│       │       ├── FileManager.ets      # 文件管理
│       │       ├── PythonSimulator.ets  # Python 模拟器
│       │       ├── RunHandler.ets       # 运行处理
│       │       ├── TabManager.ets       # 标签管理
│       │       ├── UndoManager.ets      # 撤销/重做
│       │       ├── ClipboardManager.ets # 剪贴板
│       │       ├── DialogManager.ets    # 对话框管理
│       │       ├── ActionRouter.ets     # 动作路由
│       │       ├── SettingsManager.ets  # 设置
│       │       └── SyntaxHighlighter.ets # 语法高亮
│       ├── cpp/                     # C++ 原生代码
│       │   ├── CMakeLists.txt       # CMake 构建脚本
│       │   ├── napi_init.cpp        # NAPI 桥接（Python 引擎）
│       │   ├── include/python3.13/  # Python 头文件
│       │   └── types/libentry/      # NAPI 类型声明
│       ├── resources/               # 资源文件
│       └── module.json5             # 模块配置
└── README.md                        # 项目说明
```

---

## 九、PC 适配说明

本项目支持 HarmonyOS PC（2in1 设备）运行。

### 9.1 设备类型配置

在 `entry/src/main/module.json5` 中：
```json5
"deviceTypes": ["phone", "2in1"]
```
- `phone` — 手机模式
- `2in1` — PC/平板模式

### 9.2 PC 模式运行

1. 连接 HarmonyOS PC 或 2in1 设备
2. 在 DevEco Studio 顶部选择设备
3. 点击 ▶ 运行
4. 应用以全屏 IDE 布局启动

### 9.3 布局适配

- 活动栏宽度固定 48px，图标顶部对齐
- 侧边栏宽度 200px，可折叠
- 编辑区自适应剩余空间
- 底部面板高度 180px，可折叠
- 状态栏高度 22px，固定底部

---

## 十、常见问题排查

### Q1: 编译报错 "Cannot find module"

**原因**：hvigor 依赖未下载完成

**解决**：等待右下角进度条完成，或执行：
```bash
hvigorw --version
```

### Q2: 编译报错 "Python.h: No such file"

**原因**：C++ 头文件路径错误

**解决**：确认 `entry/src/main/cpp/include/python3.13/Python.h` 文件存在

### Q3: 运行报错 "Permission denied"

**原因**：设备未开启 USB 调试或未授权

**解决**：
1. 检查设备开发者选项
2. 重新授权 USB 调试
3. 重新插拔数据线

### Q4: 点击运行没有输出

**原因**：可能是 Mock 模式（预览器中）

**解决**：使用真机或模拟器运行，不要用预览器

### Q5: 编译报错 "Signing failed"

**原因**：签名证书未配置

**解决**：按第四节配置签名，或在 **Build → Build Types** 中自动签名

### Q6: 模拟器中 Python 代码不执行

**原因**：模拟器不支持原生 SO 库加载

**解决**：使用真机运行，或使用 ArkTS 模拟器（非 Native 模式）

### Q7: 安装 HAP 报错 "install failed"

**原因**：签名不匹配或 SDK 版本不一致

**解决**：
1. 确认 SDK 版本为 6.0.2 (API 22)
2. 重新生成签名证书
3. 卸载旧版本后重装

---

## 十一、开发调试

### 11.1 查看日志

```bash
# 过滤应用日志
hdc shell hilog | grep ERIC_IDE
```

### 11.2 热重载

1. 启动调试模式：**Run → Debug 'entry'**
2. 修改代码后自动推送到设备
3. 查看 **Log** 面板的实时日志

### 11.3 性能分析

**Tools → Profiler** 可以分析：
- CPU 使用率
- 内存占用
- 帧率

---

## 十二、技术栈总结

| 技术 | 说明 |
|------|------|
| 开发语言 | ArkTS (TypeScript) |
| UI 框架 | ArkUI 声明式 UI |
| 原生代码 | C++ (NAPI 桥接) |
| Python 引擎 | CPython 3.13 (arm64) |
| 构建工具 | hvigor + CMake |
| 目标平台 | HarmonyOS Phone / 2in1 (PC) |
| 最低 SDK | 6.0.2 (API 22) |
