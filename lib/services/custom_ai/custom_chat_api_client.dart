/// 自定义 AI 的聊天流式客户端（OpenAI 兼容 SSE）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../features/chatbot/models/chat_message.dart';
import '../../features/chatbot/services/chat_api_client.dart';
import '../../features/chatbot/services/ndjson_text_stream.dart';
import '../../features/custom_ai/models/custom_ai_config.dart';
import 'custom_ai_prompts.dart';
import 'custom_ai_sentence_backend.dart';

class CustomChatApiClient implements ChatApi {
  CustomChatApiClient({required CustomAiConfig config})
    : _config = config,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(seconds: 60),
          responseType: ResponseType.stream,
        ),
      );

  final CustomAiConfig _config;
  final Dio _dio;

  String get _endpoint => resolveCustomAiChatCompletionsUrl(_config.baseUrl);

  Map<String, String> get _headers {
    final key = _config.apiKey.trim();
    return {
      Headers.contentTypeHeader: Headers.jsonContentType,
      if (key.isNotEmpty) 'Authorization': 'Bearer $key',
    };
  }

  @override
  Stream<ChatTextFrame> streamChat({
    required String endpoint,
    required List<ChatMessage> history,
    required Map<String, Object?> context,
    required String followUpInstruction,
    String? targetLanguage,
    required String accessToken,
    CancelToken? cancelToken,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      _endpoint,
      data: {
        'model': _config.model.trim(),
        'messages': [
          {
            'role': 'system',
            'content': buildChatSystemPrompt(
              targetLanguage: targetLanguage,
              context: context,
              followUpInstruction: followUpInstruction,
            ),
          },
          for (final message in history)
            message.toWire(instruction: followUpInstruction),
        ],
        'temperature': 0.4,
        'stream': true,
      },
      options: Options(
        responseType: ResponseType.stream,
        validateStatus: (_) => true,
        headers: _headers,
      ),
      cancelToken: cancelToken,
    );

    final body = response.data;
    final status = response.statusCode ?? 0;
    if (body == null) {
      throw const CustomAiException('AI 服务返回空响应');
    }
    if (status != 200) {
      final text = await utf8.decodeStream(body.stream);
      throw CustomAiException(_statusError(status, text));
    }

    final buffer = StringBuffer();
    await for (final line
        in body.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload == '[DONE]') {
        yield ChatTextFrame(
          text: buffer.toString(),
          isFinal: true,
          messageId: null,
        );
        return;
      }
      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        continue;
      }
      if (json == null) continue;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final first = choices.first;
      final delta = first is Map ? first['delta'] : null;
      final content = delta is Map ? delta['content'] : null;
      final text = _contentText(content);
      if (text.isEmpty) continue;
      buffer.write(text);
      yield ChatTextFrame(
        text: buffer.toString(),
        isFinal: false,
        messageId: null,
      );
    }

    // 部分 OpenAI 兼容服务结束时不发 [DONE]；有内容则按完成处理，避免误报断流。
    if (buffer.isNotEmpty) {
      yield ChatTextFrame(
        text: buffer.toString(),
        isFinal: true,
        messageId: null,
      );
      return;
    }
    throw const CustomAiException('AI 服务未返回内容');
  }

  String _statusError(int status, String body) {
    String? detail;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          detail = error['message'] as String;
        } else if (decoded['message'] is String) {
          detail = decoded['message'] as String;
        }
      }
    } catch (_) {
      if (body.trim().isNotEmpty) detail = body.trim();
    }
    final suffix = detail == null || detail.isEmpty ? '' : '：$detail';
    if (status == 401 || status == 403) {
      return '认证失败，请检查 API Key$suffix';
    }
    if (status == 404) {
      return '接口或模型不存在，请检查 Base URL 与模型名$suffix';
    }
    if (status == 429) {
      return '请求过于频繁或额度不足，请稍后重试$suffix';
    }
    if (status >= 500) {
      return 'AI 服务暂时不可用（$status）$suffix';
    }
    return '请求失败（$status）$suffix';
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

  @override
  void dispose() => _dio.close();
}
