/// 自定义 AI 服务配置（OpenAI 兼容协议）。
///
/// 启用后，句子翻译、解析、意群、查词与 AI 助手直接请求用户配置的服务，
/// 不再经过 Echo Loop 后端，也不要求登录或消耗云端额度。
library;

/// 厂商预设：只负责填写默认 Base URL 与模型名，用户仍可自由修改。
class CustomAiVendorPreset {
  final String id;
  final String label;
  final String defaultBaseUrl;
  final String defaultModel;

  const CustomAiVendorPreset({
    required this.id,
    required this.label,
    required this.defaultBaseUrl,
    required this.defaultModel,
  });
}

/// 常见 OpenAI 兼容服务预设。
///
/// 本地服务（Ollama / LM Studio）不校验 API Key；其余服务仍需用户自行填写。
const List<CustomAiVendorPreset> kCustomAiVendorPresets = [
  CustomAiVendorPreset(
    id: 'openai',
    label: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
  ),
  CustomAiVendorPreset(
    id: 'deepseek',
    label: 'DeepSeek',
    defaultBaseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
  ),
  CustomAiVendorPreset(
    id: 'dashscope',
    label: 'Qwen (DashScope)',
    defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen-plus',
  ),
  CustomAiVendorPreset(
    id: 'moonshot',
    label: 'Kimi (Moonshot)',
    defaultBaseUrl: 'https://api.moonshot.cn/v1',
    defaultModel: 'moonshot-v1-8k',
  ),
  CustomAiVendorPreset(
    id: 'zhipu',
    label: 'Zhipu GLM',
    defaultBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    defaultModel: 'glm-4-flash',
  ),
  CustomAiVendorPreset(
    id: 'openrouter',
    label: 'OpenRouter',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: '',
  ),
  CustomAiVendorPreset(
    id: 'ollama',
    label: 'Ollama (local)',
    defaultBaseUrl: 'http://localhost:11434/v1',
    defaultModel: 'qwen2.5:7b',
  ),
  CustomAiVendorPreset(
    id: 'lmstudio',
    label: 'LM Studio (local)',
    defaultBaseUrl: 'http://localhost:1234/v1',
    defaultModel: '',
  ),
  CustomAiVendorPreset(
    id: 'custom',
    label: 'Custom',
    defaultBaseUrl: '',
    defaultModel: '',
  ),
];

/// 自定义 AI 配置。
///
/// [apiKey] 仅保存在本机 `flutter_secure_storage`，不会随偏好同步上传。
class CustomAiConfig {
  final bool enabled;
  final String vendorId;
  final String baseUrl;
  final String apiKey;
  final String model;

  const CustomAiConfig({
    this.enabled = false,
    this.vendorId = 'openai',
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
  });

  /// 是否已具备发起请求的最低条件。
  ///
  /// API Key 允许为空：Ollama / LM Studio 等本地服务通常不需要鉴权。
  bool get isConfigured =>
      enabled && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  CustomAiVendorPreset get vendorPreset => kCustomAiVendorPresets.firstWhere(
    (preset) => preset.id == vendorId,
    orElse: () => kCustomAiVendorPresets.last,
  );

  CustomAiConfig copyWith({
    bool? enabled,
    String? vendorId,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    return CustomAiConfig(
      enabled: enabled ?? this.enabled,
      vendorId: vendorId ?? this.vendorId,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  /// 可持久化到 SharedPreferences 的部分（不含 API Key）。
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'vendorId': vendorId,
    'baseUrl': baseUrl,
    'model': model,
  };

  factory CustomAiConfig.fromJson(Map<String, dynamic> json) {
    final vendorId = json['vendorId'];
    return CustomAiConfig(
      enabled: json['enabled'] == true,
      vendorId: vendorId is String && vendorId.isNotEmpty ? vendorId : 'openai',
      baseUrl: json['baseUrl'] is String ? json['baseUrl'] as String : '',
      model: json['model'] is String ? json['model'] as String : '',
    );
  }
}
