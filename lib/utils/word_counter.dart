import '../models/sentence.dart';

/// 计算英文文本中的单词数（按空格分词）
///
/// "don't" 算 1 个词，标点附着在词上不影响计数。
int countWords(String text) {
  if (text.isEmpty) return 0;
  return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

/// 计算句子列表的总词数
int countWordsInSentences(List<Sentence> sentences) {
  return sentences.fold(0, (sum, s) => sum + countWords(s.text));
}
