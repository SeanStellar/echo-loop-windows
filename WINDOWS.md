# Echo Loop Windows（非官方本地优先版）

本仓库是 [Echo Loop](https://github.com/echo-loop/Echo-Loop) 的非官方 Windows 分支，基于上游 v1.0.46。与原作者及中央民族大学无隶属关系。

## 这个分支改了什么

- **Windows 桌面构建**：Flutter 3.47.9 + Visual Studio 2022 Build Tools（C++ / Windows SDK / ATL / CMake）+ NuGet。
- **本地优先**：Windows 版隐藏登录/订阅入口，跳过首次启动问卷；社区合集、播客订阅等匿名公开数据可直接加入本地库，不再要求账号。
- **自定义 AI**：设置 → AI 服务，可配置任意 OpenAI 兼容服务（Base URL / API Key / 模型）。启用后翻译、句子解析、意群拆分、AI 查词、AI 助手直接请求你配置的服务，不需要登录，也不消耗 Echo Loop 云端额度。API Key 仅保存在本机安全存储中。
- **播放**：通过 `just_audio_media_kit` 在 Windows 上使用 media_kit/libmpv 实现 `just_audio` 播放。
- **录音与本地 ASR**：`record` + `record_windows` 录 16kHz/16bit WAV，`sherpa-onnx` 在本地转写，恢复跟读 / 复述录音；首次使用需在「我的 → 语音识别」下载模型。
- **通知提醒**：复习提醒与下载完成通知使用 Windows 原生 Toast；安装包快捷方式写入 `AppUserModelID`。未以 MSIX 打包时通知 `cancel` 不生效，重复调度可能残留。
- **本地转录**：ffmpeg-kit 将 m4a/mp3 解码为 16kHz WAV，sherpa-onnx 分段生成字幕，已在 Windows 实测通过。
- **桌面体验**：多尺寸应用图标与完整版本信息；窗口最小 960×640，记住上次位置 / 大小；单实例启动，重复双击只激活已有窗口，避免两个进程同时写数据库。
- **系统媒体控制（SMTC）**：通过 `audio_service_win` 接入 Windows「正在播放」卡片，显示标题 / 艺术家，支持硬件媒体键与系统播放 / 暂停 / 上一句 / 下一句。
- **托盘与开机自启**：设置 → 桌面，可开启「关闭窗口时最小化到托盘」和「开机自动启动」（默认关闭；自启写入 HKCU Run，安装包卸载时清理）。
- **更新检查**：Windows 分支从本仓库 Release 的 `version-windows.json` 检查新版本；发现新版本时提示并可打开安装包下载。当前不静默安装（尚未代码签名）。
- **构建修复**：`windows/CMakeLists.txt` 增加 `/utf-8`、可配置安装前缀 `ECHOLOOP_WINDOWS_BUNDLE_DIR`，并补装 `WebView2Loader.dll`。

完整的文件级修改说明见 [NOTICE](./NOTICE) 与 `TASKS.md`。

## 运行预构建包

预构建的便携包与安装程序发布在 [Releases](https://github.com/SeanStellar/echo-loop-windows/releases)。

便携版：

1. 解压 Releases 中的便携包（文件名通常为 `EchoLoop-Windows-p2.2.zip` 或使用 `dist/EchoLoop-Windows/` 目录）。
2. 双击 `echo_loop.exe`。
3. 整个文件夹必须保持完整，不能只复制 exe。

安装版：

1. 运行 Releases 中的安装程序（`EchoLoop-Windows-Setup-1.0.46-p2.2.exe`）。
2. 按向导完成安装（默认安装到当前用户目录，不需要管理员权限）。
3. 从开始菜单或桌面快捷方式启动。

Release 包内含 Flutter 的第三方许可清单：`data/flutter_assets/NOTICES.Z`。更多说明见 [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。

## 从源码构建

前置条件：

- Flutter 3.47.9（Dart 3.13.7）
- Visual Studio 2022 Build Tools：Desktop development with C++、Windows SDK 10.0.26100、C++ ATL、C++ CMake tools
- `nuget.exe` 在 PATH 中（`flutter_tts` / `flutter_inappwebview_windows` 的 Windows 构建需要）
- Windows 开发者模式已开启（Flutter 插件需要符号链接支持）

PowerShell 5.1 示例（逐行执行）：

```powershell
flutter pub get

# 指定最终产物目录；插件安装规则会在 CMake 配置阶段固化该路径
$env:ECHOLOOP_WINDOWS_BUNDLE_DIR = "$PWD\dist\EchoLoop-Windows"

flutter build windows --release
```

建议把源码放在**纯英文路径**下构建（例如 `D:\EchoLoop`）。中文路径可能导致 analyzer / build_runner 的 URI 或临时文件问题。

### 构建安装程序

安装 [Inno Setup 6](https://jrsoftware.org/isinfo.php) 后执行：

```powershell
& "C:\Users\<你>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" "installer\windows\EchoLoop.iss"
```

输出文件：`dist\installer\EchoLoop-Windows-Setup-1.0.46.exe`。安装脚本默认按当前用户安装（`PrivilegesRequired=lowest`），不会请求管理员权限。发布到 Releases 时会把产物重命名为带 `p2.2` 后缀的文件。

### 发布新版本

1. 更新 `pubspec.yaml` 的版本号（例如 1.0.47），重新构建 Release / 安装程序 / 便携包。
2. 更新根目录 `version-windows.json`：`latestVersion` 填新版本，`minimumVersion` 填仍兼容的最低版本，`downloadUrl.windows` 指向新安装包。
3. 把便携包、安装程序与 `version-windows.json` 一起上传到新的 GitHub Release；应用会通过 `releases/latest/download/version-windows.json` 读取更新。
4. 可用 `--dart-define=WINDOWS_UPDATE_MANIFEST_URL=...` 指向镜像或本地清单做测试。

### 代码签名（可选）

仓库提供 `scripts/sign_windows.ps1`，可用自己的受信任 CA 代码签名证书（PFX）为 exe 与安装包签名：

```powershell
.\scripts\sign_windows.ps1 -PfxPath D:\certs\echoloop.pfx -PfxPassword "你的证书密码"
```

脚本会对 `dist\EchoLoop-Windows\echo_loop.exe` 与 `dist\installer\EchoLoop-Windows-Setup-1.0.46.exe` 做 SHA-256 签名并添加 DigiCert 时间戳。仓库不包含证书；没有证书时跳过此步骤不影响运行，但 Windows SmartScreen 可能提示未知发布者。自签名证书不能消除 SmartScreen 提示。

## 已知限制

- 录音与本地 ASR 已支持，但不同麦克风设备、VAD 阈值、跟读 / 复述完整流程仍需人工验收；首次使用要在「我的 → 语音识别」下载模型。
- 登录、订阅、云端转录未接入；依赖云端的入口会提示「当前版本不提供账号登录」。
- 自定义 AI 暂不支持复述评估。
- Windows 通知已接入调度，但实际 Toast 展示 / 点击、社区合集下载 UI 端到端、最小化续播仍需人工验收。
- 应用未做代码签名（签名脚本已就绪，需要自备受信任证书）。
- 自动更新目前是「自动检查 + 提示 + 打开安装包下载」，不会静默下载安装；`version-windows.json` 需要在每个 Release 上传并更新版本。
- SMTC 已支持元数据与播放控制，但不提供进度条拖动（`audio_service_win` 未同步 timeline）。
- 托盘 / 开机自启已实现但需要人工回归托盘菜单、系统托盘溢出区与注销 / 重启后的自启行为；便携版移动目录后自启路径会失效，请关闭再重新开启。
- 关闭到托盘启用时，关闭按钮会隐藏窗口而不是退出；退出请用托盘菜单「退出 Echo Loop」。
- Windows Toast 实际展示 / 点击、社区合集下载 UI 端到端、最小化续播仍需人工验收。
- Web 词典 / WebView2 加载、PDF 生成与 `Printing.canPrint` 已通过 Windows 集成测试；系统打印对话框与真实打印机仍需人工验收。
- 系统代理等平台能力仍待回归验证。

后续计划、优先级与验收标准见 [docs/windows-roadmap.md](./docs/windows-roadmap.md)。

## 许可证

本仓库沿用上游的 **AGPL-3.0**，详见 [LICENSE](./LICENSE)。分发修改版或二进制时，请保留许可证、版权声明，并提供对应的完整源码。
