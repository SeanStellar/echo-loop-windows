import 'package:drift/drift.dart';

import 'audio_items.dart';

/// 播放断点表
/// 精简版：只存 position_ms，索引从位置计算
class PlaybackStates extends Table {
  /// 音频 ID，主键 + 外键关联 audio_items.id
  TextColumn get audioItemId =>
      text().references(AudioItems, #id, onDelete: KeyAction.cascade)();

  /// 播放位置（毫秒）
  IntColumn get positionMs => integer()();

  /// 播放模式枚举：0=full, 1=bookmarks
  IntColumn get playlistMode => integer().withDefault(const Constant(0))();

  /// 保存时间
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {audioItemId};
}
