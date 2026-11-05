/// 学习材料导出 PDF 的内容选项
///
/// 预览页菜单的三个可勾选项（译文 / 单词释义 / 句子讲解），默认全选。
/// [applyStudyPdfOptions] 按选项对完整文档做纯过滤，被剔除的内容
/// 由 builder 现有逻辑自然收敛：无词汇笔记 → 单栏；无解析 → 无尾注/附录。
library;

import 'study_pdf_data.dart';

/// PDF 导出内容开关（不可变值对象）
class StudyPdfExportOptions {
  /// 是否包含译文（正文下方灰色翻译行）
  final bool includeTranslation;

  /// 是否包含单词释义（右栏词汇笔记 + 正文词条标号）
  final bool includeVocabNotes;

  /// 是否包含句子讲解（正文尾注标记 + 附录·句子解析）
  final bool includeAnalysis;

  const StudyPdfExportOptions({
    this.includeTranslation = true,
    this.includeVocabNotes = true,
    this.includeAnalysis = true,
  });

  /// 三个开关的位掩码（译文=1、释义=2、讲解=4），用作预览页字节缓存 key
  int get bitmask =>
      (includeTranslation ? 1 : 0) |
      (includeVocabNotes ? 2 : 0) |
      (includeAnalysis ? 4 : 0);

  /// 是否全部开启（此时过滤为恒等，直接复用原文档）
  bool get includesAll =>
      includeTranslation && includeVocabNotes && includeAnalysis;

  /// 复制并覆盖部分开关
  StudyPdfExportOptions copyWith({
    bool? includeTranslation,
    bool? includeVocabNotes,
    bool? includeAnalysis,
  }) => StudyPdfExportOptions(
    includeTranslation: includeTranslation ?? this.includeTranslation,
    includeVocabNotes: includeVocabNotes ?? this.includeVocabNotes,
    includeAnalysis: includeAnalysis ?? this.includeAnalysis,
  );

  @override
  bool operator ==(Object other) =>
      other is StudyPdfExportOptions && other.bitmask == bitmask;

  @override
  int get hashCode => bitmask;
}

/// 按选项对文档做纯过滤，返回新文档（不修改原文档）
///
/// - 关译文：每句 `translation` 置 null
/// - 关单词释义：每句词汇笔记与词条标号清空；收藏词橙色下划线
///   （[StudyPdfSentence.savedRanges]）保留，与 App 内正文语义一致
/// - 关句子讲解：每句 `grammar`/`vocabulary`/`listening` 置 null
///   （`hasAnalysis` 随之为 false，builder 不再渲染尾注与附录）
/// - 全开：直接返回原文档（引用相等，免拷贝）
StudyPdfDocument applyStudyPdfOptions(
  StudyPdfDocument document,
  StudyPdfExportOptions options,
) {
  if (options.includesAll) return document;

  return StudyPdfDocument(
    title: document.title,
    durationSeconds: document.durationSeconds,
    wordCount: document.wordCount,
    paragraphs: [
      for (final paragraph in document.paragraphs)
        [
          for (final sentence in paragraph)
            StudyPdfSentence(
              index: sentence.index,
              text: sentence.text,
              isBookmarked: sentence.isBookmarked,
              savedRanges: sentence.savedRanges,
              translation: options.includeTranslation
                  ? sentence.translation
                  : null,
              grammar: options.includeAnalysis ? sentence.grammar : null,
              vocabulary: options.includeAnalysis ? sentence.vocabulary : null,
              listening: options.includeAnalysis ? sentence.listening : null,
              vocabNotes: options.includeVocabNotes
                  ? sentence.vocabNotes
                  : const [],
              vocabMarkers: options.includeVocabNotes
                  ? sentence.vocabMarkers
                  : const [],
            ),
        ],
    ],
  );
}
