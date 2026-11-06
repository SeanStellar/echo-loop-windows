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
- **构建修复**：`windows/CMakeLists.txt` 增加 `/utf-8`、可配置安装前缀 `ECHOLOOP_WINDOWS_BUNDLE_DIR`，并补装 `WebView2Loader.dll`。

完整的文件级修改说明见 [NOTICE](./NOTICE) 与 `TASKS.md`。

## 运行预构建包

预构建的便携包与安装程序发布在 [Releases](https://github.com/SeanStellar/echo-loop-windows/releases)。

便携版：

1. 解压 `EchoLoop-Windows.zip`（或使用 `dist/EchoLoop-Windows/` 目录）。
2. 双击 `echo_loop.exe`。
3. 整个文件夹必须保持完整，不能只复制 exe。

安装版：

1. 运行 `EchoLoop-Windows-Setup-1.0.46.exe`。
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

输出文件：`dist\installer\EchoLoop-Windows-Setup-1.0.46.exe`。安装脚本默认按当前用户安装（`PrivilegesRequired=lowest`），不会请求管理员权限。

## 已知限制

- 录音与本地 ASR 已支持，但不同麦克风设备、VAD 阈值、跟读 / 复述完整流程仍需人工验收；首次使用要在「我的 → 语音识别」下载模型。
- 登录、订阅、云端转录未接入；依赖云端的入口会提示「当前版本不提供账号登录」。
- 自定义 AI 暂不支持复述评估。
- Windows 通知已接入调度，但实际 Toast 展示 / 点击、社区合集下载 UI 端到端、最小化续播仍需人工验收。
- 媒体键 / SMTC（系统“正在播放”卡片）尚未接入，计划放在 P2。
- 系统代理等平台能力仍待回归验证。

后续计划、优先级与验收标准见 [docs/windows-roadmap.md](./docs/windows-roadmap.md)。

## 许可证

本仓库沿用上游的 **AGPL-3.0**，详见 [LICENSE](./LICENSE)。分发修改版或二进制时，请保留许可证、版权声明，并提供对应的完整源码。
