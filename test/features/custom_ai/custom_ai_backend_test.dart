import 'dart:convert';
import 'dart:io';

import 'package:echo_loop/features/custom_ai/models/custom_ai_config.dart';
import 'package:echo_loop/services/custom_ai/custom_ai_sentence_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late List<Map<String, dynamic>> requests;

  setUp(() async {
    // Flutter 测试默认把 HttpClient 替换为返回 400 的假实现；本测试需要真实本地 HTTP。
    HttpOverrides.global = null;
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decodeStream(request);
      requests.add(jsonDecode(body) as Map<String, dynamic>);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '{"translation":"你好"}'},
            },
          ],
        }),
      );
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('translateStream 调用 OpenAI 兼容端点并解析 JSON', () async {
    final backend = CustomAiSentenceBackend(
      config: CustomAiConfig(
        enabled: true,
        baseUrl: 'http://127.0.0.1:${server.port}/v1',
        apiKey: 'test-key',
        model: 'test-model',
      ),
    );

    final frames = await backend
        .translateStream('hello', accessToken: '')
        .toList();

    expect(frames, hasLength(1));
    expect(frames.single.translation.translation, '你好');
    expect(frames.single.isFinal, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single['model'], 'test-model');
    final messages = requests.single['messages'] as List<dynamic>;
    expect((messages.first as Map<String, dynamic>)['role'], 'system');
    backend.dispose();
  });

  test('认证失败时返回可读的 CustomAiException', () async {
    await server.close(force: true);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {'message': 'invalid api key'},
        }),
      );
      await request.response.close();
    });

    final backend = CustomAiSentenceBackend(
      config: CustomAiConfig(
        enabled: true,
        baseUrl: 'http://127.0.0.1:${server.port}/v1',
        apiKey: 'bad-key',
        model: 'test-model',
      ),
    );

    await expectLater(
      backend.translateStream('hello', accessToken: '').toList(),
      throwsA(
        isA<CustomAiException>().having(
          (error) => error.message,
          'message',
          contains('invalid api key'),
        ),
      ),
    );
    backend.dispose();
  });
}
