/// 自定义 AI 后端实例 Provider。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/custom_ai/custom_ai_sentence_backend.dart';
import '../../../services/sentence_ai_api_client.dart';
import 'custom_ai_config_provider.dart';

final customAiSentenceBackendProvider = Provider<SentenceAiBackend>((ref) {
  final config = ref.watch(customAiConfigProvider);
  if (!config.isConfigured) {
    throw StateError('Custom AI is not configured');
  }
  final backend = CustomAiSentenceBackend(config: config);
  ref.onDispose(backend.dispose);
  return backend;
});
