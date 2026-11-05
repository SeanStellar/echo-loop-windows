# 第三方组件与许可说明

本仓库是 Echo Loop 的非官方 fork，代码与资源沿用上游的 **AGPL-3.0**（见 `LICENSE`）。项目同时依赖大量第三方 Dart / Flutter 包与 Windows 原生库；它们分别受各自许可证约束。

## 源码依赖

Flutter / Dart 依赖通过 `pubspec.yaml` 声明，具体版本与许可证记录在 `pubspec.lock` 及各包的 `LICENSE` 中。运行 Flutter 构建时，Flutter 会把参与构建的 Dart/Flutter 包许可证汇总到：

```
<构建产物>/data/flutter_assets/NOTICES.Z
```

发布二进制时请保留该文件，或在 Release 页面附上等价的第三方许可清单。

主要依赖类别：

| 组件 | 用途 | 许可证（以组件上游为准） |
|---|---|---|
| Flutter / Dart SDK | UI 与运行时 | BSD-3-Clause |
| just_audio / just_audio_media_kit / media_kit | 音频播放 | MIT / LGPL-2.1+（libmpv 构建可能包含 GPL 组件，请核对上游构建） |
| ffmpeg-kit-flutter | 音频/视频处理 | LGPL-2.1+ / GPL（取决于 ffmpeg-kit 构建选项） |
| flutter_inappwebview / Microsoft WebView2 | 网页词典 | Apache-2.0 / Microsoft 软件许可条款 |
| Firebase C++ SDK / firebase_core | 可选上报 | Apache-2.0 / Google 服务条款 |
| sherpa_onnx | 离线语音识别 | Apache-2.0 |
| Edge TTS（在线服务） | 在线语音合成 | 由 Microsoft 服务条款约束，不随仓库分发 |

## 分发二进制时

如果你在 GitHub Releases 或其他渠道分发 `EchoLoop-Windows.zip`：

1. 附带本仓库的 `LICENSE`（AGPL-3.0）与源码获取方式（本仓库地址）。
2. 保留构建产物中的 `data/flutter_assets/NOTICES.Z`。
3. 核对 ffmpeg、libmpv、WebView2 等原生库的许可证与再分发要求；不同构建选项可能对应不同许可证。
4. 不要移除或替换第三方版权声明。

以上仅为一般性说明，不构成法律意见；正式发布前建议核对各上游项目的 LICENSE。
