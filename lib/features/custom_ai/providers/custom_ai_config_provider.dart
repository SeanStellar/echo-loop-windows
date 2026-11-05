/// 自定义 AI 配置 Provider。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding_survey/providers/onboarding_survey_provider.dart'
    show sharedPreferencesProvider;
import '../models/custom_ai_config.dart';
import '../services/custom_ai_config_store.dart';

/// 启动时由 main() 注入的初始配置（含安全存储中的 API Key）。
final initialCustomAiConfigProvider = Provider<CustomAiConfig>(
  (ref) => const CustomAiConfig(),
);

final customAiConfigStoreProvider = Provider<CustomAiConfigStore>((ref) {
  return CustomAiConfigStore(ref.read(sharedPreferencesProvider));
});

class CustomAiConfigNotifier extends Notifier<CustomAiConfig> {
  @override
  CustomAiConfig build() => ref.watch(initialCustomAiConfigProvider);

  Future<void> save(CustomAiConfig config) async {
    await ref.read(customAiConfigStoreProvider).save(config);
    state = config;
  }

  Future<void> setEnabled(bool enabled) async {
    final next = state.copyWith(enabled: enabled);
    await save(next);
  }
}

final customAiConfigProvider =
    NotifierProvider<CustomAiConfigNotifier, CustomAiConfig>(
      CustomAiConfigNotifier.new,
    );

/// 同步判断：当前是否已启用并配置完整的自定义 AI。
final customAiConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(customAiConfigProvider).isConfigured;
});
