/// 自定义 AI 使用的提示词与输出结构约束。
///
/// 自定义模式绕过 Echo Loop 后端，原本由后端承担的 prompt 在这里客户端实现。
/// 所有结构化功能都要求模型只输出一个 JSON 对象，解析端再做容错提取。
library;

import 'dart:convert';

class CustomAiPrompt {
  final String system;
  final String user;

  const CustomAiPrompt({required this.system, required this.user});
}

String customAiLanguageName(String? targetLanguage) {
  final normalized = (targetLanguage ?? '').trim().toLowerCase();
  if (normalized.isEmpty) return '简体中文';
  if (normalized.startsWith('zh')) return '简体中文';
  if (normalized == 'en' || normalized.startsWith('en-')) return 'English';
  return targetLanguage!;
}

CustomAiPrompt buildTranslationPrompt({
  required String text,
  required String? previousText,
  required String? nextText,
  required String targetLanguage,
}) {
  final language = customAiLanguageName(targetLanguage);
  final system =
      '你是一名专业的英语学习助手。请结合上下文，把用户给出的目标句翻译成$language。'
      '只输出一个 JSON 对象，不要输出 Markdown 代码块、解释或任何多余文字。'
      '输出格式严格为：{"translation":"译文"}';
  final buffer = StringBuffer();
  if (previousText != null && previousText.trim().isNotEmpty) {
    buffer.writeln('前一句：${previousText.trim()}');
  }
  buffer.writeln('目标句：${text.trim()}');
  if (nextText != null && nextText.trim().isNotEmpty) {
    buffer.writeln('后一句：${nextText.trim()}');
  }
  return CustomAiPrompt(system: system, user: buffer.toString().trim());
}

CustomAiPrompt buildAnalysisPrompt({
  required String text,
  required String targetLanguage,
}) {
  final language = customAiLanguageName(targetLanguage);
  final system =
      '你是一名英语精听解析助手。请解析用户给出的英文句子，所有说明使用$language。'
      '只输出一个 JSON 对象，不要输出 Markdown 代码块或多余文字。'
      '输出结构严格为：'
      '{"grammar":[{"point":"结构或句型标签","note":"通俗说明"}],'
      '"vocabulary":[{"term":"原句中的词或短语","note":"含义、搭配或用法"}],'
      '"listening":[{"phrase":"原句中的词或短语","note":"连读、弱读、缩读等听力难点"}]}'
      '。grammar 输出 1-3 条，vocabulary 输出 0-4 条，listening 输出 1-3 条。';
  return CustomAiPrompt(system: system, user: '请解析这个句子：${text.trim()}');
}

CustomAiPrompt buildSenseGroupsPrompt({required String text}) {
  final system =
      '你是一名英语意群切分助手。请把用户给出的英文句子切分为意群，只输出一个 JSON 对象：'
      '{"medium":["意群1","意群2"],"fine":["更细的意群1","更细的意群2"]}。'
      'medium 按自然口语节奏切分（每个意群约 3-8 个词），fine 切得更细。'
      '每个 chunk 必须保留原句中的前导空格，使 medium.join("") 与 fine.join("") '
      '都能逐字符还原原句；不得增删、改写或翻译任何字符。只输出 JSON。';
  return CustomAiPrompt(system: system, user: '原句：${text.trim()}');
}

CustomAiPrompt buildWordDictionaryPrompt({
  required String word,
  required String targetLanguage,
}) {
  final language = customAiLanguageName(targetLanguage);
  final system =
      '你是一名英语词典编纂助手。请解析用户给出的英文单词，解释使用$language。'
      '只输出一个 JSON 对象，不要输出 Markdown 代码块或多余文字。'
      '输出结构严格为：'
      '{"headword":"原形","pronunciation":{"uk":"英式 IPA","us":"美式 IPA"},'
      '"meanings":[{"partOfSpeech":"n.","translation":["中文对译"],'
      '"definition":"英文释义","usageNote":"用法说明",'
      '"examples":[{"sentence":"英文例句","translation":"译文"}],'
      '"synonyms":["同义词"],"antonyms":["反义词"]}],'
      '"commonExpressions":[{"expression":"搭配或习语","type":"collocation",'
      '"meaning":"含义","example":{"sentence":"英文例句","translation":"译文"}}],'
      '"wordFamily":[{"word":"派生词","partOfSpeech":"词性","meaning":"释义",'
      '"example":{"sentence":"英文例句","translation":"译文"}}],'
      '"forms":[{"form":"词形","label":"形式名称"}],'
      '"etymology":"词源简注","learnerTips":["学习者提示"]}'
      '。meanings 输出 1-3 条，每条 examples 输出 1 条；'
      'commonExpressions / wordFamily 各 0-3 条；learnerTips 输出 1-3 条。'
      '不确定或不适用的字段用空字符串或空数组。';
  return CustomAiPrompt(system: system, user: '请解析单词：${word.trim()}');
}

CustomAiPrompt buildPhraseDictionaryPrompt({
  required String phrase,
  required String targetLanguage,
}) {
  final language = customAiLanguageName(targetLanguage);
  final system =
      '你是一名英语表达分析助手。请解析用户给出的英文多词表达，解释使用$language。'
      '只输出一个 JSON 对象，不要输出 Markdown 代码块或多余文字。'
      '输出结构严格为：'
      '{"originalExpression":"原表达","naturalness":"不自然或受限时的纠正说明，自然则为空串",'
      '"category":"短语动词/搭配/习语/术语等",'
      '"pronunciationTips":["连读、弱读或重音提示"],'
      '"keyPoints":[{"point":"要点说明","sentence":"英文例句","translation":"译文"}],'
      '"meanings":[{"translation":["中文对译"],'
      '"examples":[{"sentence":"英文例句","translation":"译文"}]}],'
      '"similarExpressions":[{"expression":"相近表达","difference":"区别",'
      '"sentence":"英文例句","translation":"译文"}],'
      '"background":"补充背景"}'
      '。keyPoints 输出 1-3 条，meanings 输出 1-3 条，similarExpressions 输出 0-3 条；'
      '不适用的字段用空字符串或空数组。';
  return CustomAiPrompt(system: system, user: '请解析表达：${phrase.trim()}');
}

String buildChatSystemPrompt({
  required String? targetLanguage,
  required Map<String, Object?> context,
  required String followUpInstruction,
}) {
  final language = customAiLanguageName(targetLanguage);
  final buffer = StringBuffer()
    ..writeln('你是 Echo Loop 的英语学习助手。请使用$language回答。')
    ..writeln('回答要简洁、具体、可操作；解释语法或词汇时给出英文例句与译文。')
    ..writeln('不要回答与英语学习无关的内容。')
    ..writeln(followUpInstruction);
  if (context.isNotEmpty) {
    buffer
      ..writeln('当前学习上下文（JSON）：')
      ..writeln(jsonEncode(context));
  }
  return buffer.toString().trim();
}
