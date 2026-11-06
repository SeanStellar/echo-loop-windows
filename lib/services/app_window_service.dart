import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app_logger.dart';

/// 提供应用窗口的跨桌面平台激活能力。
abstract interface class AppWindowActivator {
  /// 初始化桌面窗口控制插件。
  Future<void> initialize();

  /// 恢复、显示并聚焦应用主窗口。
  Future<void> activate();
}

/// 使用 [window_manager] 激活桌面应用窗口。
///
/// Windows 额外负责：
/// - 最小窗口尺寸；
/// - 记住上次窗口位置/大小，下次启动恢复。
class WindowManagerAppWindowActivator
    with WindowListener
    implements AppWindowActivator {
  static const String _windowsBoundsKey = 'windows_window_bounds_v1';
  static const Size _windowsMinimumSize = Size(960, 640);

  bool _initialized = false;
  SharedPreferences? _prefs;
  Timer? _saveBoundsTimer;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<void> initialize() async {
    if (!_isDesktop || _initialized) return;
    try {
      await windowManager.ensureInitialized();
      _initialized = true;
      if (_isWindows) {
        _prefs = await SharedPreferences.getInstance();
        await windowManager.setMinimumSize(_windowsMinimumSize);
        await _restoreWindowsBounds();
        windowManager.addListener(this);
      }
    } catch (error, stackTrace) {
      AppLogger.log(
        'AppWindow',
        'Window manager initialization failed: error=$error '
            'stack=$stackTrace',
      );
    }
  }

  @override
  Future<void> activate() async {
    if (!_isDesktop) return;
    await initialize();
    if (!_initialized) return;

    await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _restoreWindowsBounds() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_windowsBoundsKey);
    if (raw == null || raw.isEmpty) {
      await windowManager.center();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await windowManager.center();
        return;
      }
      final x = (decoded['x'] as num?)?.toDouble();
      final y = (decoded['y'] as num?)?.toDouble();
      final width = (decoded['width'] as num?)?.toDouble();
      final height = (decoded['height'] as num?)?.toDouble();
      if (x == null || y == null || width == null || height == null) {
        await windowManager.center();
        return;
      }
      if (width < _windowsMinimumSize.width ||
          height < _windowsMinimumSize.height ||
          x < -5000 ||
          y < -5000) {
        await windowManager.center();
        return;
      }
      await windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
    } catch (error) {
      AppLogger.log('AppWindow', 'restore windows bounds failed: $error');
      await windowManager.center();
    }
  }

  @override
  void onWindowMoved() => _scheduleSaveBounds();

  @override
  void onWindowResized() => _scheduleSaveBounds();

  // 贴边分屏、最大化等操作不一定触发 moved/resized 事件，
  // 失焦时补一次保存，避免用户调整后的位置丢失。
  @override
  void onWindowBlur() => _scheduleSaveBounds();

  void _scheduleSaveBounds() {
    if (!_isWindows || !_initialized) return;
    _saveBoundsTimer?.cancel();
    _saveBoundsTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_saveWindowsBounds());
    });
  }

  Future<void> _saveWindowsBounds() async {
    final prefs = _prefs;
    if (prefs == null || !_initialized) return;
    try {
      // 最大化/最小化时 getBounds 返回的不是正常窗口位置，跳过以免覆盖。
      if (await windowManager.isMaximized() ||
          await windowManager.isMinimized()) {
        return;
      }
      final bounds = await windowManager.getBounds();
      await prefs.setString(
        _windowsBoundsKey,
        jsonEncode({
          'x': bounds.left,
          'y': bounds.top,
          'width': bounds.width,
          'height': bounds.height,
        }),
      );
    } catch (error) {
      AppLogger.log('AppWindow', 'save windows bounds failed: $error');
    }
  }
}
