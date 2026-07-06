# 计划 · 记录 —— 个人专属「计划 + 记录」双生态 AI 助理

一个用 Flutter 写的、温暖米白风的安卓 App。核心是两个互相打通的生态——**计划**（向前看、管行动）与**记录**（向后看、管沉淀），再由**复盘洞察**把两者串起来，AI（DeepSeek）帮你自动排计划、对话调整、给建议、做周期洞察。

> 数据全部保存在你手机本地（sqflite），不上传任何服务器。AI 的 API Key 也只存在本机。

---

## ✅ 当前状态：环境已配好，APK 已编译成功

开发环境已经在这台电脑上装好（全部在 D 盘），并且已经**成功编译出可安装的 APK**：

- **可直接安装的 APK**：`D:\计划记录-app-release.apk`（约 54 MB，release 版）
  - 备用路径：`D:\cc_test\warm_planner\build\app\outputs\flutter-apk\app-release.apk`
- 已安装：Flutter 3.44.4（`D:\dev\flutter`）、JDK 17（`D:\dev\jdk17`）、Android SDK（`D:\dev\Android\Sdk`）
- 已配好环境变量（用户级）：`PUB_HOSTED_URL`、`FLUTTER_STORAGE_BASE_URL`（国内镜像加速）、`PUB_CACHE=D:\dev\pub-cache`、`JAVA_HOME=D:\dev\jdk17`、`ANDROID_SDK_ROOT=D:\dev\Android\Sdk`
- 已生成 `android/` 平台工程，并加好了联网权限 + 中文应用名「计划 · 记录」

**你现在就可以做的：** 把 `D:\计划记录-app-release.apk` 传到手机安装即可使用（安装时允许「未知来源」）。首次用 AI 前，在 App「设置」里填入 DeepSeek API Key。

> ⚠️ 一个已知的无害警告：编译时会提示 `share_plus` 使用了旧式 Kotlin 插件（"apply KGP"）。当前 Flutter 3.44.4 **能正常编译**，只是**未来某个更高版本的 Flutter** 可能要求升级该依赖。届时把 `share_plus` 升到支持 Built-in Kotlin 的新版本即可（会顺带改一处分享代码的 API）。

下面是从零配置环境的完整说明（**换电脑**或想了解细节时看）。如果只想重新编译，直接跳到 **「如何重新编译 / 在手机上运行」**。

---

## 一、这个项目里有什么

```
warm_planner/
├── pubspec.yaml            # 依赖清单
├── analysis_options.yaml
├── README.md               # ← 你正在看的文件
└── lib/
    ├── main.dart           # 入口
    ├── core/               # 主题（温暖米白风集中管理）、工具
    ├── data/
    │   ├── models/         # Goal / Task / Record / Settings（含未来扩展字段）
    │   ├── repositories/   # ★ 抽象接口（业务只依赖接口）
    │   └── local/          # ★ 接口的本地实现（sqflite）
    ├── services/
    │   ├── ai/             # DeepSeek 封装 + 排计划/洞察 Prompt 编排
    │   └── backup/         # 导出/导入 JSON 备份
    ├── app/                # 依赖注入（Riverpod）、主框架
    └── features/           # 今日 / 目标 / 记录 / 复盘 / 设置 / 对话 / 排计划
```

**这个文件夹目前只包含 Dart 源码，没有 `android/` 平台工程**——因为 `android/` 里的构建脚本要精确匹配你电脑上安装的 Flutter 版本，所以最可靠的方式是安装好 Flutter 后，用一条命令自动生成它（下面第 4 步）。

---

## 二、你需要装什么（都装到 D 盘）

| 软件 | 作用 | 建议安装位置 |
|---|---|---|
| **Flutter SDK** | 编译 Flutter 项目的核心 | `D:\dev\flutter` |
| **Android Studio** | 提供 Android SDK、构建工具、手机驱动 | 安装到 `D:\dev\Android\Android Studio`，SDK 放 `D:\dev\Android\Sdk` |
| **（自带）Git** | Flutter 需要 | 一般随 Android Studio 或单独装到 D 盘 |

> 全程约需 6–10 GB 空间，请确保 D 盘足够。

---

## 三、逐步安装（新手照着做）

### 第 1 步：安装 Flutter SDK 到 D 盘

1. 打开官网下载页：https://docs.flutter.dev/get-started/install/windows
2. 下载 **Flutter SDK 的 zip 压缩包**（Stable 稳定版）。
3. 在 D 盘新建文件夹 `D:\dev`，把压缩包**解压到这里**，最终得到 `D:\dev\flutter`（里面能看到 `bin` 文件夹）。
   - ⚠️ 不要解压到 `C:\Program Files`（需要管理员权限，容易出问题）。
4. **把 Flutter 加入 PATH 环境变量**：
   - 按 `Win` 键搜索「编辑系统环境变量」→ 打开 →「环境变量」。
   - 在「用户变量」里找到 `Path` → 编辑 → 新建一行，填 `D:\dev\flutter\bin` → 一路确定。
5. （可选，推荐）**把 pub 缓存也放到 D 盘**，避免占用 C 盘：
   - 在「用户变量」里「新建」：变量名 `PUB_CACHE`，变量值 `D:\dev\pub-cache`。

### 第 2 步：安装 Android Studio 到 D 盘

1. 下载：https://developer.android.com/studio
2. 安装时，**安装路径选到 D 盘**，例如 `D:\dev\Android\Android Studio`。
3. 首次启动会弹出 **Setup Wizard**，选择 **Standard** 安装，在选择 SDK 位置时把 **Android SDK Location 改到 `D:\dev\Android\Sdk`**，然后让它自动下载 SDK、平台工具、模拟器等。
4. 安装完成后，进入 **Settings → Languages & Frameworks → Android SDK**：
   - 在 **SDK Platforms** 勾选一个较新的 Android 版本（如 Android 14）。
   - 在 **SDK Tools** 确认勾选了 **Android SDK Command-line Tools** 和 **Android SDK Build-Tools**，点 Apply 下载。

### 第 3 步：让 Flutter 认识 Android 环境

打开一个新的 **PowerShell** 窗口（新窗口才会加载新 PATH），依次运行：

```powershell
flutter --version          # 能打印版本号，说明 PATH 配好了
flutter doctor             # 体检：检查各项是否就绪
flutter doctor --android-licenses   # 同意 Android 许可（一路输入 y）
```

`flutter doctor` 里 **[✓] Flutter** 和 **[✓] Android toolchain** 打勾就够编译 APK 了（Visual Studio / Chrome 那几项是给 Windows 桌面/网页用的，可以不管）。

> 如果 doctor 提示找不到 Android SDK，运行：
> `flutter config --android-sdk "D:\dev\Android\Sdk"`

### 第 4 步 & 第 5 步：已经帮你做好了 ✅

在这台电脑上，以下都已完成，**换电脑时才需要重做**：
- 已生成 `android/` 平台工程（`flutter create --platforms=android .`）。
- 已 `flutter pub get` 拉好依赖。
- 已在 `android/app/src/main/AndroidManifest.xml` 加好联网权限 `<uses-permission android:name="android.permission.INTERNET"/>`（DeepSeek 必需，release 版没有它会连不上），并把应用名设为中文「计划 · 记录」。

> 换新电脑重装时，进入项目目录依次执行：`flutter create --platforms=android .`（不会覆盖 `lib/` 和 `pubspec.yaml`）→ `flutter pub get` → 手动在 AndroidManifest 里加上面那行联网权限。

---

## 三之半、如何重新编译 / 在手机上运行（环境已就绪）

因为 Flutter 还没加进当前命令行的 PATH，示例里用**完整路径**调用；你把 `D:\dev\flutter\bin` 加进 PATH 后，直接写 `flutter` 即可。

**重新打包 APK：**
```powershell
cd D:\cc_test\warm_planner
D:\dev\flutter\bin\flutter.bat build apk --release
```
产物：`D:\cc_test\warm_planner\build\app\outputs\flutter-apk\app-release.apk`

**改完代码想验证有没有语法/编译问题（快）：**
```powershell
cd D:\cc_test\warm_planner
D:\dev\flutter\bin\flutter.bat analyze
```

---

## 四、把 App 装到你的安卓手机上

### 方式 A：手机连电脑直接运行（推荐，能实时调试）

1. 手机进入**开发者模式**：设置 → 关于手机 → 连点「版本号」7 次。
2. 回到设置 → 系统 → 开发者选项 → 打开 **USB 调试**。
3. 用数据线连接电脑，手机弹出「允许 USB 调试」时点**允许**。
4. 在 PowerShell 里：

```powershell
flutter devices          # 应能看到你的手机
flutter run              # 编译并安装到手机，实时运行
```

首次编译较慢（要下载 Gradle 等，几分钟到十几分钟），耐心等。运行起来后，改代码存盘、在终端按 `r` 可热重载。

### 方式 B：打包成 APK 文件，手动安装

```powershell
cd D:\cc_test\warm_planner
flutter build apk --release
```

编译完成后，APK 在：

```
D:\cc_test\warm_planner\build\app\outputs\flutter-apk\app-release.apk
```

把这个 `app-release.apk` 传到手机（微信/QQ 发给自己、数据线拷贝、网盘均可），在手机上点开安装（需允许「安装未知来源应用」）。

> 想要更小的体积可用：`flutter build apk --split-per-abi`，会按 CPU 架构分出几个更小的 APK，选 `app-arm64-v8a-release.apk`（绝大多数手机适用）。

---

## 五、第一次打开 App 怎么用

1. **配置 AI（用 AI 功能前必做一次）**：底部「设置」→ **DeepSeek AI 配置** → 填入你的 **API Key**（去 https://platform.deepseek.com 获取）。API 地址和模型名已有默认值。点「测试连接」确认通。
2. **填约束条件**（可选但推荐）：设置 → **我的约束条件**，填作息、可支配时段等，AI 排计划会当硬性条件遵守。
3. **极简起步**：今日页 →「一句话开始」→ 输入「我想每天运动30分钟+学英语1小时」→ AI 直接排出今天的计划。
4. **快捷打卡**：今日页任务前的圆圈，点一下即完成，关联目标的进度条会自动增长。
5. **设定时提醒**：今日页任务右侧「⋯」→ 打开「定时提醒」开关 → 选日期时间 → 保存。到点会弹安卓通知。首次会请求通知权限，请允许。
6. **对话调整**：今日页右下「对话调整」→ 晚间复盘、重排计划、聊聊完成率。
7. **记录**：底部「记录」→ 写复盘（踩坑）或灵感，可让 AI 给建议。
8. **复盘洞察**：底部「复盘」→ 选本周/本月 → 看完成率 → 生成 AI 洞察。
9. **备份**：设置 → 导出数据（存成 JSON 发给自己），换机或清数据后用「导入数据」恢复。

---

## 六、常见问题

- **`flutter` 不是内部命令**：PATH 没配好或没开新窗口。重开 PowerShell，确认 `D:\dev\flutter\bin` 在 Path 里。
- **AI 一直失败 / 超时**：检查 API Key 是否正确、手机是否联网、第 5 步的 INTERNET 权限是否加了（尤其是 release APK）。
- **Gradle 下载很慢**：属正常，首次构建需联网下载。可保持网络畅通耐心等待。
- **`flutter doctor` 报 cmdline-tools 缺失**：回到 Android Studio 的 SDK Tools 勾选「Android SDK Command-line Tools」下载。

---

## 七、架构说明（给未来的你 / 开发者）

- **分层**：表现层（`features/`）→ 依赖注入（`app/providers.dart`）→ 仓库接口（`data/repositories/`）→ 本地实现（`data/local/`）。业务与 UI **只依赖接口**，不碰数据库。
- **上云只改一处**：未来要接云端实时同步，只需在 `app/providers.dart` 里把 `LocalXxxRepository` 换成 `CloudXxxRepository`（实现同一接口），其余代码零改动。代码中相关扩展点均有注释标明。
- **本地通知提醒（已实现）**：给任务设 `reminderTime`，`NotificationService`（`lib/services/notifications/`）到点弹安卓本地通知。当前固定按**中国时区 Asia/Shanghai** 计算（单一时区、无夏令时）；未来若要跨时区，接入 `flutter_timezone` 动态获取即可（代码里已注释标明扩展点）。
- **已预留的未来扩展**（第一版不实现，字段/结构已留好）：
  - 账号登录：各模型的 `userId` 字段。
  - 记录搜索与标签：`RecordEntry.tags` 字段。
  - 深色主题：主题色集中在 `core/theme/app_theme.dart`，加 `darkTheme` 即可。
```
