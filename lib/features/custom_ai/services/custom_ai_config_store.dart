/// 自定义 AI 配置持久化。
///
/// 非敏感字段（厂商、地址、模型、开关）放 SharedPreferences；API Key 放
/// [FlutterSecureStorage]，避免明文落盘。
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/app_logger.dart';
import '../models/custom_ai_config.dart';

const String _configPrefsKey = 'custom_ai_config_v1';
const String _apiKeySecureKey = 'echo_loop_custom_ai_api_key';

class CustomAiConfigStore {
  CustomAiConfigStore(
    this._prefs, {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _secureStorage = secureStorage;

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  CustomAiConfig loadSync() {
    final raw = _prefs.getString(_configPrefsKey);
    if (raw == null || raw.isEmpty) return const CustomAiConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CustomAiConfig.fromJson(decoded);
      }
    } catch (error) {
      AppLogger.log('CustomAI', '配置解析失败，回退默认值: $error');
    }
    return const CustomAiConfig();
  }

  /// 读取完整配置（含安全存储中的 API Key）。
  Future<CustomAiConfig> load() async {
    final config = loadSync();
    String apiKey = '';
    try {
      apiKey = await _secureStorage.read(key: _apiKeySecureKey) ?? '';
    } catch (error) {
      AppLogger.log('CustomAI', 'API Key 读取失败: $error');
    }
    return config.copyWith(apiKey: apiKey);
  }

  Future<void> save(CustomAiConfig config) async {
    await _prefs.setString(_configPrefsKey, jsonEncode(config.toJson()));
    try {
      final key = config.apiKey.trim();
      if (key.isEmpty) {
        await _secureStorage.delete(key: _apiKeySecureKey);
      } else {
        await _secureStorage.write(key: _apiKeySecureKey, value: key);
      }
    } catch (error) {
      AppLogger.log('CustomAI', 'API Key 保存失败: $error');
    }
  }
}
