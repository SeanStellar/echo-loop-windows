import 'package:drift/drift.dart';

import 'audio_items.dart';
import 'collections.dart';

/// 合集-音频关联表（Junction 表）
class CollectionAudioItems extends Table {
  /// 合集 ID，外键关联 collections.id
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();

  /// 音频 ID，外键关联 audio_items.id
  TextColumn get audioItemId =>
      text().references(AudioItems, #id, onDelete: KeyAction.cascade)();

  /// 在合集内的排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 加入合集的时间
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {collectionId, audioItemId};
}
