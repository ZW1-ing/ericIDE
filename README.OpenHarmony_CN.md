# EricPC — 环境配置与编译运行指南

> 跳过 DevEco Studio 安装等基础步骤，聚焦项目特有的环境配置。

---

## 一、SDK 与工具链要求

| 项目 | 版本要求 |
|------|----------|
| HarmonyOS SDK | **6.0.2 (API 22)** |
| Native SDK | **必须安装**（含 CMake、Ninja） |
| DevEco Studio | 5.0.0 Release+ |
| 编译器 | BiSheng（项目已配置） |

### 确认 Native SDK 已安装

**File → Settings → SDK → HarmonyOS**，确认勾选了 **Native** 选项卡并已下载。

如果没装，C++ 编译会报 `cmake not found` 或 `ninja not found`。

---

## 二、项目打开与同步

1. **File → Open**，选择项目根目录（包含 `build-profile.json5` 的文件夹）
2. 等待右下角 hvigor 同步完成
3. 如果提示 **"Sync Failed"**，点击 **File → Sync Project** 重新同步

### 验证同步成功

底部 **Build** 窗口出现以下内容即表示成功：
```
BUILD SUCCESSFUL in xxx s
```

---

## 三、签名配置（真机必须）

### 快速自动签名

1. **Build → Build Types**
2. 点击 **debug** 标签页
3. 勾选 **Automatically generate signature**
4. 点击 **OK**
5. 等待证书申请完成（弹窗提示即可）

### 验证签名

**File → Project Structure → Modules → entry → Signing Configs**，确认：
- **Store file**: 有路径（如 `debugKeyStore.p12`）
- **Key alias**: 不为空
- **Key password / Store password**: 不为空

> 模拟器运行不需要签名，可以直接跳过。

---

## 四、设备连接

### 真机

1. 手机 **设置 → 关于手机 → 连续点版本号 7 次** 开启开发者模式
2. **设置 → 系统和更新 → 开发人员选项 → USB 调试** 打开
3. USB 连接电脑，手机弹窗点 **允许**
4. DevEco Studio 顶部工具栏显示设备名称即连接成功

### 模拟器

1. **Tools → Device Manager → +**
2. 选择设备模板，下载镜像（首次约 2-3GB）
3. 启动模拟器
4. 顶部工具栏选择该模拟器

### 验证连接

底部 **Terminal** 执行：
```bash
hdc list targets
```
输出设备 UDN 即连接成功。

---

## 五、编译与运行

### 编译

**Build → Build Hap(s)/App(s) → Build Hap(s)**

等待底部 **Build** 窗口出现 `BUILD SUCCESSFUL`。

### 运行

1. 顶部工具栏选择目标设备
2. 点击绿色 **▶ Run** 按钮
3. 应用安装并自动启动

### 命令行方式

```bash
# 编译
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 安装
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# 启动
hdc shell aa start -a EntryAbility -b com.ericide.entry
```

---

## 六、原生 C++ 模块说明

项目通过 NAPI 桥接 ArkTS 和 CPython 3.13，编译时 CMake 会自动构建。

### 关键文件

| 文件 | 作用 |
|------|------|
| `entry/libs/arm64-v8a/libpython3.13.so` | Python 动态库（已包含在仓库中） |
| `entry/src/main/cpp/napi_init.cpp` | NAPI 桥接代码 |
| `entry/src/main/cpp/CMakeLists.txt` | CMake 构建脚本 |
| `entry/src/main/cpp/include/python3.13/` | Python 头文件 |

### 如果 C++ 编译失败

**检查点 1**：确认 Native SDK 已安装
```
File → Settings → SDK → HarmonyOS → Native 选项卡
```

**检查点 2**：确认 `libpython3.13.so` 文件存在
```bash
ls -la entry/libs/arm64-v8a/libpython3.13.so
```

**检查点 3**：清理重新编译
```
Build → Clean Project
Build → Build Hap(s)/App(s) → Build Hap(s)
```

---

## 七、PC（2in1）适配配置

### 设备类型声明

`entry/src/main/module.json5` 中已配置：
```json5
"deviceTypes": ["phone", "2in1"]
```

### 运行在 PC 上

1. 连接 HarmonyOS PC 或 2in1 设备
2. DevEco Studio 顶部选择该设备
3. 点击 ▶ 运行
4. 应用自动以全屏 IDE 布局启动

### 布局参数

| 区域 | 宽度 | 高度 |
|------|------|------|
| 活动栏 | 48px 固定 | 100% |
| 侧边栏 | 200px | 100% |
| 底部面板 | 100% | 180px（可折叠） |
| 标签栏 | 100% | 30px |
| 状态栏 | 100% | 22px 固定 |

---

## 八、预览器说明

打开任意 `.ets` 文件，右侧 **Previewer** 面板可实时预览 UI。

> **注意**：预览器中 Python 执行功能使用 Mock 模拟，不会真正运行代码。需要真机或模拟器才能完整测试。

---

## 九、常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `cmake not found` | Native SDK 未安装 | Settings → SDK → 勾选 Native |
| `Python.h not found` | 头文件路径错误 | 确认 `include/python3.13/` 目录存在 |
| 签名失败 | 未配置签名 | Build Types → 自动签名 |
| 安装 HAP 失败 | 签名不匹配 | 重新生成签名证书 |
| 点击运行无输出 | 预览器 Mock 模式 | 改用真机或模拟器 |
| `libentry.so` 加载失败 | C++ 编译失败 | Clean Project 后重新编译 |
| 底部 hvigor 报错 | 依赖未下载 | 联网等待自动下载 |

---

## 十、调试技巧

### 查看应用日志
```bash
hdc shell hilog | grep ERIC_IDE
```

### 重新安装
```bash
hdc shell aa uninstall -b com.ericide.entry
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

### 清理编译产物
```
Build → Clean Project
```
