/// 学习相关埋点的音频参数构造工具
///
/// 统一在事件参数中携带 `audio_id` + `audio_name`，避免后台只看到 ID 不知道
/// 用户在练习哪个音频。`audioId` 为空或未匹配到本地音频时，仅返回已有的 ID。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_library_provider.dart';
import 'models/event_names.dart';

/// 构造仅包含 audio_id（必有）+ audio_name（可选）的参数 map。
/// 公共函数，给已经持有音频名的调用方直接使用，无需读 provider。
Map<String, Object> audioEventParams({
  required String? audioId,
  String? audioName,
}) {
  if (audioId == null || audioId.isEmpty) return const {};
  return {
    EventParams.audioId: audioId,
    if (audioName != null && audioName.isNotEmpty)
      EventParams.audioName: audioName,
  };
}

/// Notifier / 服务层在持有 [Ref] 时，通过此扩展从 audioLibraryProvider 解析名称。
extension AudioEventParamsRefX on Ref {
  /// 根据 audioId 从音频库读取名称并构造事件参数 map。
  Map<String, Object> audioEventParams(String? audioId) {
    if (audioId == null || audioId.isEmpty) return const {};
    final name = read(audioLibraryProvider.notifier).getItemById(audioId)?.name;
    return {
      EventParams.audioId: audioId,
      if (name != null && name.isNotEmpty) EventParams.audioName: name,
    };
  }
}

/// Widget 层使用 [WidgetRef] 时调用此扩展。
extension AudioEventParamsWidgetRefX on WidgetRef {
  /// 根据 audioId 从音频库读取名称并构造事件参数 map。
  Map<String, Object> audioEventParams(String? audioId) {
    if (audioId == null || audioId.isEmpty) return const {};
    final name = read(audioLibraryProvider.notifier).getItemById(audioId)?.name;
    return {
      EventParams.audioId: audioId,
      if (name != null && name.isNotEmpty) EventParams.audioName: name,
    };
  }
}
