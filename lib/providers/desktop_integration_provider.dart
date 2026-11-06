import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_logger.dart';
import '../services/windows_app_identity.dart';
import '../services/windows_desktop_integration.dart';

part 'desktop_integration_provider.g.dart';

/// 当前运行环境是否为 Windows 桌面。
bool get isWindowsDesktop =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

const String _closeToTrayKey = 'windows_close_to_tray_v1';
const String _launchAtStartupKey = 'windows_launch_at_startup_v1';
const String _logTag = 'DesktopIntegration';

/// Windows 桌面集成偏好。
class DesktopIntegrationState {
  const DesktopIntegrationState({
    this.closeToTray = false,
    this.launchAtStartup = false,
  });

  /// 关闭窗口时隐藏到托盘，而不是退出进程。
  final bool closeToTray;

  /// 登录 Windows 后自动启动 Echo Loop。
  final bool launchAtStartup;

  DesktopIntegrationState copyWith({bool? closeToTray, bool? launchAtStartup}) {
    return DesktopIntegrationState(
      closeToTray: closeToTray ?? this.closeToTray,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    );
  }
}

/// 托盘 / 开机自启偏好。
///
/// 开机自启以注册表实际状态为准：启动时读一次并回写 SP，避免用户在
/// Windows 设置里手动关闭后，应用内仍显示开启。
@Riverpod(keepAlive: true)
class DesktopIntegration extends _$DesktopIntegration {
  SharedPreferences? _prefs;
  bool _launchAtStartupConfigured = false;

  @override
  DesktopIntegrationState build() {
    if (isWindowsDesktop) {
      unawaited(_load());
    }
    return const DesktopIntegrationState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final closeToTray = prefs.getBool(_closeToTrayKey) ?? false;
    var launchAtStartup = prefs.getBool(_launchAtStartupKey) ?? false;

    try {
      _configureLaunchAtStartup();
      final actual = await LaunchAtStartup.instance.isEnabled();
      if (actual != launchAtStartup) {
        launchAtStartup = actual;
        await prefs.setBool(_launchAtStartupKey, actual);
      }
    } catch (error, stackTrace) {
      AppLogger.log(
        _logTag,
        'read launch-at-startup failed: $error\n$stackTrace',
      );
    }

    state = DesktopIntegrationState(
      closeToTray: closeToTray,
      launchAtStartup: launchAtStartup,
    );
  }

  Future<void> setCloseToTray(bool enabled) async {
    if (!isWindowsDesktop) return;
    await _prefs?.setBool(_closeToTrayKey, enabled);
    state = state.copyWith(closeToTray: enabled);
  }

  /// 写入 / 移除 HKCU Run 启动项。失败时抛出，由设置页提示。
  Future<void> setLaunchAtStartup(bool enabled) async {
    if (!isWindowsDesktop) return;
    _configureLaunchAtStartup();
    final changed = enabled
        ? await LaunchAtStartup.instance.enable()
        : await LaunchAtStartup.instance.disable();
    if (!changed) {
      throw StateError('launch_at_startup did not apply');
    }
    await _prefs?.setBool(_launchAtStartupKey, enabled);
    state = state.copyWith(launchAtStartup: enabled);
  }

  void _configureLaunchAtStartup() {
    if (_launchAtStartupConfigured) return;
    LaunchAtStartup.instance.setup(
      appName: windowsAppDisplayName,
      appPath: Platform.resolvedExecutable,
    );
    _launchAtStartupConfigured = true;
  }
}

/// 单例托盘 / 关闭行为服务。
final windowsDesktopIntegrationProvider = Provider<WindowsDesktopIntegration>((
  ref,
) {
  final service = WindowsDesktopIntegration();
  ref.onDispose(service.dispose);
  return service;
});
