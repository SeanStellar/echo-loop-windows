import 'package:echo_loop/features/custom_ai/models/custom_ai_config.dart';
import 'package:echo_loop/services/custom_ai/custom_ai_prompts.dart';
import 'package:echo_loop/services/custom_ai/custom_ai_sentence_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomAiConfig', () {
    test('启用且地址与模型完整时视为已配置，API Key 可为空', () {
      const config = CustomAiConfig(
        enabled: true,
        baseUrl: 'http://localhost:11434/v1',
        model: 'qwen2.5:7b',
      );
      expect(config.isConfigured, isTrue);
    });

    test('未启用或缺少模型时不视为已配置', () {
      expect(
        const CustomAiConfig(
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
        ).isConfigured,
        isFalse,
      );
      expect(
        const CustomAiConfig(
          enabled: true,
          baseUrl: 'https://api.openai.com/v1',
        ).isConfigured,
        isFalse,
      );
    });

    test('toJson 不包含 API Key', () {
      const config = CustomAiConfig(
        enabled: true,
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'secret',
        model: 'deepseek-chat',
      );
      expect(config.toJson().containsKey('apiKey'), isFalse);
    });
  });

  group('resolveCustomAiChatCompletionsUrl', () {
    test('追加 /chat/completions 并去掉末尾斜杠', () {
      expect(
        resolveCustomAiChatCompletionsUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1/chat/completions',
      );
      expect(
        resolveCustomAiChatCompletionsUrl('  http://localhost:1234/v1  '),
        'http://localhost:1234/v1/chat/completions',
      );
    });

    test('已经是完整端点时保持不变', () {
      const endpoint = 'https://example.com/v1/chat/completions';
      expect(resolveCustomAiChatCompletionsUrl(endpoint), endpoint);
    });
  });

  group('extractJsonObjectFromText', () {
    test('解析纯 JSON', () {
      expect(extractJsonObjectFromText('{"translation":"你好"}'), {
        'translation': '你好',
      });
    });

    test('解析 Markdown 代码块包裹的 JSON', () {
      expect(extractJsonObjectFromText('```json\n{"translation":"你好"}\n```'), {
        'translation': '你好',
      });
    });

    test('忽略前后说明文字，并正确处理字符串中的花括号', () {
      expect(
        extractJsonObjectFromText(
          '结果如下：{"translation":"保留 {花括号} 与 \\"引号\\""} 希望有帮助',
        ),
        {'translation': '保留 {花括号} 与 "引号"'},
      );
    });

    test('没有 JSON 或 JSON 不完整时抛出 FormatException', () {
      expect(
        () => extractJsonObjectFromText('抱歉，我无法回答'),
        throwsFormatException,
      );
      expect(
        () => extractJsonObjectFromText('{"translation":"未闭合"'),
        throwsFormatException,
      );
    });
  });

  group('customAiLanguageName', () {
    test('常见目标语言映射', () {
      expect(customAiLanguageName('zh-CN'), '简体中文');
      expect(customAiLanguageName('en'), 'English');
      expect(customAiLanguageName('ja-JP'), 'ja-JP');
    });
  });
}
