import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sentence_ai_cache.dart';

part 'sentence_ai_cache_dao.g.dart';

/// 通用 AI 结果缓存 DAO
///
/// 按 (textHash, type) 读写各类 AI 结果 JSON（句子翻译/解析、AI 词典等）。
/// 读取时自动更新 lastAccessedAt，支持按时间清理过期缓存。
@DriftAccessor(tables: [SentenceAiCache])
class SentenceAiCacheDao extends DatabaseAccessor<AppDatabase>
    with _$SentenceAiCacheDaoMixin {
  SentenceAiCacheDao(super.db);

  /// 根据哈希和类型查找缓存
  ///
  /// 命中时自动更新 [lastAccessedAt]，返回 JSON 字符串；未命中返回 null。
  Future<String?> getByHash(String hash, String type) async {
    final query = select(sentenceAiCache)
      ..where((t) => t.textHash.equals(hash) & t.type.equals(type));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    // 更新最后访问时间
    (update(sentenceAiCache)..where((t) => t.id.equals(row.id))).write(
      SentenceAiCacheCompanion(lastAccessedAt: Value(DateTime.now())),
    );

    return row.result;
  }

  /// 批量按哈希读取同类型缓存（只读，不更新 [lastAccessedAt]）
  ///
  /// 用于 PDF 导出等一次性聚合读取：把逐句 [getByHash]（每读一次还附带一条
  /// UPDATE 写放大 + 一次串行往返）合并为单条 `WHERE textHash IN (...)` 查询。
  /// 返回命中的 `哈希 → JSON` 映射，未命中的哈希不在结果中。
  ///
  /// 批量读取刻意**不**刷新访问时间：导出属于旁路读取，不应把整篇文档的
  /// 缓存 TTL 全部重置。
  Future<Map<String, String>> getManyByHash(
    Iterable<String> hashes,
    String type,
  ) async {
    final hashList = hashes.toSet().toList();
    if (hashList.isEmpty) return const {};
    final query = select(sentenceAiCache)
      ..where((t) => t.textHash.isIn(hashList) & t.type.equals(type));
    final rows = await query.get();
    return {for (final row in rows) row.textHash: row.result};
  }

  /// 插入或更新缓存
  ///
  /// 以 (textHash, type) 为唯一键，冲突时更新 result 和时间戳。
  Future<void> upsert(String hash, String type, String resultJson) {
    final now = DateTime.now();
    return into(sentenceAiCache).insert(
      SentenceAiCacheCompanion.insert(
        textHash: hash,
        type: type,
        result: resultJson,
        createdAt: now,
        lastAccessedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => SentenceAiCacheCompanion(
          result: Value(resultJson),
          lastAccessedAt: Value(now),
        ),
        target: [sentenceAiCache.textHash, sentenceAiCache.type],
      ),
    );
  }

  /// 根据哈希和类型删除单条缓存
  ///
  /// 用于缓存格式不兼容时清除旧数据。
  Future<int> deleteByHash(String hash, String type) {
    return (delete(
      sentenceAiCache,
    )..where((t) => t.textHash.equals(hash) & t.type.equals(type))).go();
  }

  /// 删除超过指定时间未访问的缓存
  ///
  /// 用于定期清理，避免数据库无限增长。
  Future<int> deleteOlderThan(Duration age) {
    final threshold = DateTime.now().subtract(age);
    return (delete(
      sentenceAiCache,
    )..where((t) => t.lastAccessedAt.isSmallerThanValue(threshold))).go();
  }

  /// 清空所有 AI 缓存
  ///
  /// 用于用户手动清理缓存，不影响其他用户数据。
  Future<int> deleteAll() {
    return delete(sentenceAiCache).go();
  }
}
