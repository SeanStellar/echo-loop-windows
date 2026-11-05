/// 词级时间戳与句子边界的同步工具。
///
/// 仅处理「句子边界变动」这一编辑路径：当用户在字幕编辑器里拖动句子的
/// 起止边界、或合并/删除句子后，保存时用本工具把词级时间戳重新对齐到
/// 最终的句子边界上。
///
/// 注：未来若实现真正的词级编辑（用户增删/修改单词），需另写独立函数处理，
/// 不要复用本函数 —— 本函数假设词本身不变，只随句子边界做对齐。
library;

import '../models/sentence.dart';
import '../models/word_timestamp.dart';

/// 按最终句子边界同步词级时间戳（只对齐边界词）。
///
/// 规则：
/// 1. 每个词按其时间中点归属到包含该中点的句子（句子区间为半开 `[start, end)`，
///    互不重叠，故每个词至多归属一句）。
/// 2. 中点落在句间静音区（不属于任何句子）的词被丢弃。
/// 3. 每句首词的 `startTime` 对齐到句子 `startTime`，末词的 `endTime` 对齐到
///    句子 `endTime`；句中其余词的真实时间戳保持不变。
///
/// 返回按时间顺序排列的新词级时间戳列表（输入 [words] 假定已按时间升序）。
List<WordTimestamp> syncWordTimestampsToSentenceBounds(
  List<Sentence> sentences,
  List<WordTimestamp> words,
) {
  if (words.isEmpty || sentences.isEmpty) return const [];

  // 按句子归集词（保持原始时间顺序）。
  final buckets = List.generate(sentences.length, (_) => <WordTimestamp>[]);
  for (final word in words) {
    final midUs =
        (word.startTime.inMicroseconds + word.endTime.inMicroseconds) ~/ 2;
    for (var s = 0; s < sentences.length; s++) {
      final sentence = sentences[s];
      if (midUs >= sentence.startTime.inMicroseconds &&
          midUs < sentence.endTime.inMicroseconds) {
        buckets[s].add(word);
        break;
      }
    }
    // 中点落在句间静音区的词被丢弃。
  }

  // 逐句对齐边界词。
  final result = <WordTimestamp>[];
  for (var s = 0; s < sentences.length; s++) {
    final bucket = buckets[s];
    if (bucket.isEmpty) continue;
    final sentence = sentences[s];
    for (var i = 0; i < bucket.length; i++) {
      var word = bucket[i];
      if (i == 0) {
        word = word.copyWith(startTime: sentence.startTime);
      }
      if (i == bucket.length - 1) {
        word = word.copyWith(endTime: sentence.endTime);
      }
      result.add(word);
    }
  }
  return result;
}
