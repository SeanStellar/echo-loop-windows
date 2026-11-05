/// OpenAI 兼容的自定义 AI 后端。
///
/// 直接请求用户配置的 `{baseUrl}/chat/completions`，不经过 Echo Loop 后端，
/// 因此不需要登录、不消耗云端额度。结构化功能要求模型返回 JSON，本层负责
/// 容错提取；聊天使用 SSE 流式输出。
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:universal_io/io.dart';

import '../../features/custom_ai/models/custom_ai_config.dart';
import '../../models/dictionary/dictionary_entry.dart';
import '../../models/retell_review_evaluation.dart';
import '../../models/sense_group_result.dart';
import '../../models/sentence_ai_result.dart';
import '../app_logger.dart';
import '../sentence_ai_api_client.dart';
import 'custom_ai_prompts.dart';

/// 自定义 AI 的领域异常，[message] 会直接展示给用户。
class CustomAiException implements Exception {
  final String message;

  const CustomAiException(this.message);

  @override
  String toString() => message;
}

/// 把用户填写的 Base URL 规范化为 Chat Completions 端点。
///
/// - 已以 `/chat/completions` 结尾时原样返回；
/// - 去掉末尾多余斜杠后追加 `/chat/completions`。
String resolveCustomAiChatCompletionsUrl(String baseUrl) {
  final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (trimmed.endsWith('/chat/completions')) return trimmed;
  return '$trimmed/chat/completions';
}

/// 从模型输出中提取第一个完整 JSON 对象。
///
/// 兼容 Markdown 代码块与前后解释文字；用括号配对扫描，避免字符串中的花括号干扰。
Map<String, dynamic> extractJsonObjectFromText(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    throw const FormatException('模型返回空内容');
  }
  final start = text.indexOf('{');
  if (start < 0) {
    throw const FormatException('模型返回中没有 JSON 对象');
  }
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '{') {
      depth += 1;
    } else if (ch == '}') {
      depth -= 1;
      if (depth == 0) {
        final candidate = text.substring(start, i + 1);
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const FormatException('模型返回的 JSON 不是对象');
      }
    }
  }
  throw const FormatException('模型返回的 JSON 不完整');
}

class CustomAiSentenceBackend implements SentenceAiBackend {
  CustomAiSentenceBackend({required CustomAiConfig config})
    : _config = config,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(seconds: 60),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  final CustomAiConfig _config;
  final Dio _dio;

  @override
  bool get requiresAuth => false;

  String get _endpoint => resolveCustomAiChatCompletionsUrl(_config.baseUrl);

  Map<String, String> get _headers {
    final key = _config.apiKey.trim();
    return {
      Headers.contentTypeHeader: Headers.jsonContentType,
      if (key.isNotEmpty) 'Authorization': 'Bearer $key',
    };
  }

  /// 连通性测试：发一条极小请求，确认地址、Key 与模型名可用。
  Future<void> testConnection({CancelToken? cancelToken}) async {
    await _completeText(
      const CustomAiPrompt(system: '你是连通性测试助手。', user: '只回复 OK'),
      maxTokens: 16,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<SentenceTranslationStreamFrame> translateStream(
    String text, {
    required String accessToken,
    String? previousText,
    String? nextText,
    String? targetLanguage,
    CancelToken? cancelToken,
  }) async* {
    final json = await _completeJson(
      buildTranslationPrompt(
        text: text,
        previousText: previousText,
        nextText: nextText,
        targetLanguage: targetLanguage ?? 'zh-CN',
      ),
      cancelToken: cancelToken,
    );
    yield SentenceTranslationStreamFrame(
      translation: SentenceTranslation.fromJson(json),
      isFinal: true,
    );
  }

  @override
  Stream<SentenceAnalysisStreamFrame> analyzeStream(
    String text, {
    required String accessToken,
    String? targetLanguage,
    CancelToken? cancelToken,
  }) async* {
    final json = await _completeJson(
      buildAnalysisPrompt(
        text: text,
        targetLanguage: targetLanguage ?? 'zh-CN',
      ),
      cancelToken: cancelToken,
    );
    yield SentenceAnalysisStreamFrame(
      analysis: SentenceAnalysis.fromJson(json),
      isFinal: true,
    );
  }

  @override
  Stream<SenseGroupsStreamFrame> senseGroupsStream(
    String text, {
    required String accessToken,
    CancelToken? cancelToken,
  }) async* {
    final json = await _completeJson(
      buildSenseGroupsPrompt(text: text),
      cancelToken: cancelToken,
    );
    yield SenseGroupsStreamFrame(
      result: SenseGroupResult.fromJson(json),
      isFinal: true,
    );
  }

  @override
  Stream<AiDictionaryStreamFrame> lookupWordStreamFrames(
    String word, {
    required String accessToken,
    String? targetLanguage,
    CancelToken? cancelToken,
  }) async* {
    final json = await _completeJson(
      buildWordDictionaryPrompt(
        word: word,
        targetLanguage: targetLanguage ?? 'zh-CN',
      ),
      cancelToken: cancelToken,
    );
    yield AiDictionaryStreamFrame(
      entry: DictionaryEntry.fromJson(json),
      isFinal: true,
    );
  }

  @override
  Stream<AiDictionaryStreamFrame> lookupPhraseStreamFrames(
    String phrase, {
    required String accessToken,
    String? targetLanguage,
    CancelToken? cancelToken,
  }) async* {
    final json = await _completeJson(
      buildPhraseDictionaryPrompt(
        phrase: phrase,
        targetLanguage: targetLanguage ?? 'zh-CN',
      ),
      cancelToken: cancelToken,
    );
    yield AiDictionaryStreamFrame(
      entry: MultiWordDictionaryEntry.fromJson(json),
      isFinal: true,
    );
  }

  @override
  Stream<RetellReviewStreamFrame> evaluateReviewStream({
    required File audioFile,
    required String originalText,
    required String targetLanguage,
    required String accessToken,
    CancelToken? cancelToken,
  }) async* {
    throw const CustomAiException('自定义 AI 暂不支持复述评估，请使用其他评估方式');
  }

  Future<Map<String, dynamic>> _completeJson(
    CustomAiPrompt prompt, {
    CancelToken? cancelToken,
  }) async {
    final content = await _completeText(prompt, cancelToken: cancelToken);
    try {
      return extractJsonObjectFromText(content);
    } on FormatException catch (error) {
      AppLogger.log(
        'CustomAI',
        'JSON 解析失败: ${error.message}; 原始内容=${_truncate(content)}',
      );
      throw CustomAiException('模型返回内容无法解析：${error.message}');
    }
  }

  Future<String> _completeText(
    CustomAiPrompt prompt, {
    int? maxTokens,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'model': _config.model.trim(),
          'messages': [
            {'role': 'system', 'content': prompt.system},
            {'role': 'user', 'content': prompt.user},
          ],
          'temperature': 0.2,
          'stream': false,
          if (maxTokens != null) 'max_tokens': maxTokens,
        },
        options: Options(headers: _headers),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) {
        throw const CustomAiException('AI 服务返回空响应');
      }
      final choices = data['choices'];
      if (choices is! List || choices.isEmpty) {
        throw CustomAiException('AI 响应格式不正确：${_truncate(jsonEncode(data))}');
      }
      final first = choices.first;
      final message = first is Map ? first['message'] : null;
      final content = message is Map ? message['content'] : null;
      final text = _contentText(content);
      if (text.trim().isEmpty) {
        throw const CustomAiException('AI 返回了空内容');
      }
      return text;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) rethrow;
      throw _mapDioError(error);
    }
  }

  CustomAiException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final detail = _errorDetail(error.response?.data);
    final suffix = detail == null ? '' : '：$detail';
    if (status == 401 || status == 403) {
      return CustomAiException('认证失败，请检查 API Key$suffix');
    }
    if (status == 404) {
      return CustomAiException('接口或模型不存在，请检查 Base URL 与模型名$suffix');
    }
    if (status == 429) {
      return CustomAiException('请求过于频繁或额度不足，请稍后重试$suffix');
    }
    if (status != null && status >= 500) {
      return CustomAiException('AI 服务暂时不可用（$status）$suffix');
    }
    if (status != null) {
      return CustomAiException('请求失败（$status）$suffix');
    }
    return CustomAiException('无法连接 AI 服务：${error.message ?? error.type.name}');
  }

  String? _errorDetail(Object? data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    if (data is String && data.trim().isNotEmpty) return _truncate(data);
    return null;
  }

  String _contentText(Object? content) {
    if (content is String) return content;
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text']);
        }
      }
      return buffer.toString();
    }
    return '';
  }

  String _truncate(String text) {
    const maxLength = 500;
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
  }

  @override
  void dispose() => _dio.close();
}
