import 'package:drift/drift.dart';

/// TTS 合成结果缓存表
///
/// 统一 TTS 管线（合成→文件→缓存→播放）的索引层。音频文件落本地目录，
/// 本表只存元数据与过期/容量规则——过期判定靠 [expiresAt]、淘汰靠
/// [lastAccessedAt]（LRU），不依赖文件名或目录（业界标准做法）。
///
/// 凡可按参数复现的合成结果都可入表，由 [cacheKey] 唯一标识。平台 TTS 与
/// 未来 Kokoro 共用此表，靠 [engine] 区分。
class TtsCache extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 缓存键（唯一），由 `sha256(textHash|engine|voice|speed|format)` 派生。
  /// 同一文本在不同引擎/音色/语速/格式下生成不同条目，互不串音。
  TextColumn get cacheKey => text()();

  /// 被合成文本的 SHA-256 哈希（归一化后），用于去重与统计。
  TextColumn get textHash => text()();

  /// 被合成的原始文本（可读），用于调试时识别每条缓存对应的内容。
  /// 缓存对象为单词/例句/示范句等短文本，存储成本可忽略。
  TextColumn get sourceText => text()();

  /// 合成引擎标识（`platform` / 未来 `kokoro`）。
  TextColumn get engine => text()();

  /// 音色/口音标识（如 `en-US` / `en-GB`，或未来具体 voice name）。
  TextColumn get voice => text()();

  /// 语言标签（`en-US` / `en-GB`）。
  TextColumn get languageCode => text()();

  /// 语速（归一化值）。
  RealColumn get speed => real()();

  /// 音频格式（平台 TTS：Android `wav` / iOS·macOS `caf`）。
  TextColumn get format => text()();

  /// 本地音频文件绝对路径。
  TextColumn get filePath => text()();

  /// 文件字节数（用于容量统计与 LRU 淘汰）。
  IntColumn get fileSize => integer()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 最后访问时间（LRU 淘汰依据）。
  DateTimeColumn get lastAccessedAt => dateTime()();

  /// 过期时间（可空）。null 表示不按时间过期（永久缓存）。
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// 是否永久保留（不自动清理）。本期恒 false，为未来长文音频预留。
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {cacheKey},
  ];
}
