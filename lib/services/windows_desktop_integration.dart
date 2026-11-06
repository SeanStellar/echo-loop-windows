import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app_logger.dart';
import 'windows_app_identity.dart';

/// Windows 托盘与关闭行为。
///
/// 只在“关闭窗口时最小化到托盘”开启时创建托盘图标；关闭开关会移除图标
/// 并恢复正常关闭即退出。托盘菜单的文案由界面层按当前语言注入。
class WindowsDesktopIntegration with WindowListener {
  static const String _logTag = 'DesktopIntegration';
  static const String _trayIconAsset = 'assets/icon/app-icon-96.png';

  bool _initialized = false;
  bool _closeToTray = false;
  bool _quitting = false;
  TrayIcon? _trayIcon;
  Menu? _contextMenu;
  MenuItem? _showItem;
  MenuItem? _quitItem;
  String _showLabel = 'Show main window';
  String _quitLabel = 'Quit Echo Loop';

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> initialize({
    required bool closeToTray,
    required String showLabel,
    required String quitLabel,
  }) async {
    if (!_isWindows || _initialized) return;
    _initialized = true;
    _showLabel = showLabel;
    _quitLabel = quitLabel;
    windowManager.addListener(this);
    AppLogger.log(_logTag, 'initialized closeToTray=$closeToTray');
    await _applyCloseToTray(closeToTray);
  }

  Future<void> applyCloseToTray(bool enabled) async {
    if (!_initialized) {
      _closeToTray = enabled;
      return;
    }
    await _applyCloseToTray(enabled);
  }

  Future<void> updateLabels({
    required String showLabel,
    required String quitLabel,
  }) async {
    _showLabel = showLabel;
    _quitLabel = quitLabel;
    if (!_initialized) return;
    _showItem?.label = showLabel;
    _quitItem?.label = quitLabel;
    _trayIcon?.setTooltip(windowsAppDisplayName);
  }

  Future<void> _applyCloseToTray(bool enabled) async {
    _closeToTray = enabled;
    try {
      await windowManager.setPreventClose(enabled);
      var applied = enabled;
      if (enabled) {
        applied = await _ensureTrayIcon();
        if (!applied) {
          // 托盘创建失败时必须恢复关闭即退出，否则窗口会被拦截且无法找回。
          _closeToTray = false;
          await windowManager.setPreventClose(false);
        }
      } else {
        await _removeTrayIcon();
      }
      AppLogger.log(_logTag, 'close-to-tray applied enabled=$applied');
    } catch (error, stackTrace) {
      AppLogger.log(
        _logTag,
        'apply close-to-tray failed: enabled=$enabled error=$error\n$stackTrace',
      );
    }
  }

  Future<bool> _ensureTrayIcon() async {
    if (_trayIcon != null) return true;
    TrayIcon? tray;
    Menu? menu;
    try {
      tray = TrayIcon.create();
      if (tray == null) {
        AppLogger.log(_logTag, 'tray icon unavailable');
        return false;
      }
      final icon = ImageAsset.fromAsset(_trayIconAsset);
      if (icon == null) {
        AppLogger.log(_logTag, 'tray icon asset unavailable');
        tray.dispose();
        return false;
      }
      tray.icon = icon;
      tray.setTooltip(windowsAppDisplayName);

      menu = Menu.create();
      if (menu == null) {
        tray.dispose();
        AppLogger.log(_logTag, 'tray menu unavailable');
        return false;
      }
      final showItem = MenuItem.createWithLabelAndType(
        _showLabel,
        MenuItemType.normal,
      );
      final quitItem = MenuItem.createWithLabelAndType(
        _quitLabel,
        MenuItemType.normal,
      );
      showItem?.addListener((event) {
        if (event is MenuItemClickedEvent) unawaited(showWindow());
      });
      quitItem?.addListener((event) {
        if (event is MenuItemClickedEvent) unawaited(quitApp());
      });
      menu.addItem(showItem);
      menu.addSeparator();
      menu.addItem(quitItem);

      tray.setContextMenu(menu);
      tray.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
      tray.addListener((event) {
        if (event is TrayIconClickedEvent ||
            event is TrayIconDoubleClickedEvent) {
          unawaited(showWindow());
        }
      });
      tray.setVisible(true);

      _contextMenu = menu;
      _showItem = showItem;
      _quitItem = quitItem;
      _trayIcon = tray;
      AppLogger.log(_logTag, 'tray icon created');
      return true;
    } catch (error, stackTrace) {
      tray?.dispose();
      menu?.dispose();
      AppLogger.log(_logTag, 'create tray icon failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> _removeTrayIcon() async {
    _showItem = null;
    _quitItem = null;
    _contextMenu?.dispose();
    _contextMenu = null;
    _trayIcon?.dispose();
    _trayIcon = null;
  }

  /// 从托盘恢复主窗口。
  Future<void> showWindow() async {
    try {
      await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (error, stackTrace) {
      AppLogger.log(_logTag, 'show window failed: $error\n$stackTrace');
    }
  }

  /// 真正退出应用：解除关闭拦截、移除托盘并关闭窗口。
  Future<void> quitApp() async {
    _quitting = true;
    AppLogger.log(_logTag, 'quit requested from tray');
    try {
      await windowManager.setPreventClose(false);
      await _removeTrayIcon();
      await windowManager.close();
    } catch (error, stackTrace) {
      AppLogger.log(_logTag, 'quit failed: $error\n$stackTrace');
    }
  }

  @override
  void onWindowClose() {
    if (!_closeToTray || _quitting) return;
    AppLogger.log(_logTag, 'window close intercepted, hiding to tray');
    unawaited(windowManager.hide());
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    windowManager.removeListener(this);
    await _removeTrayIcon();
  }
}
