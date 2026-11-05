/// 自定义 AI 服务设置页。
///
/// 配置 OpenAI 兼容的 Base URL、API Key 与模型名；启用后 AI 讲解类功能
/// 直接请求该服务，不再依赖登录或云端额度。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/custom_ai/models/custom_ai_config.dart';
import '../features/custom_ai/providers/custom_ai_config_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/custom_ai/custom_ai_sentence_backend.dart';
import '../theme/app_theme.dart';

class CustomAiSettingsScreen extends ConsumerStatefulWidget {
  const CustomAiSettingsScreen({super.key});

  @override
  ConsumerState<CustomAiSettingsScreen> createState() =>
      _CustomAiSettingsScreenState();
}

class _CustomAiSettingsScreenState
    extends ConsumerState<CustomAiSettingsScreen> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late String _vendorId;
  late bool _enabled;
  bool _obscureApiKey = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(customAiConfigProvider);
    _enabled = config.enabled;
    _vendorId = config.vendorId;
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  CustomAiConfig _draftConfig() {
    return CustomAiConfig(
      enabled: _enabled,
      vendorId: _vendorId,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );
  }

  void _applyVendor(String? id) {
    if (id == null) return;
    final preset = kCustomAiVendorPresets.firstWhere(
      (item) => item.id == id,
      orElse: () => kCustomAiVendorPresets.last,
    );
    setState(() {
      _vendorId = id;
      if (preset.defaultBaseUrl.isNotEmpty) {
        _baseUrlController.text = preset.defaultBaseUrl;
      }
      if (preset.defaultModel.isNotEmpty) {
        _modelController.text = preset.defaultModel;
      }
    });
  }

  bool _validate(AppLocalizations l10n) {
    final rawUrl = _baseUrlController.text.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      _showSnackBar(l10n.aiServiceValidationUrl);
      return false;
    }
    if (_modelController.text.trim().isEmpty) {
      _showSnackBar(l10n.aiServiceValidationModel);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_enabled && !_validate(l10n)) return;
    await ref.read(customAiConfigProvider.notifier).save(_draftConfig());
    if (!mounted) return;
    _showSnackBar(l10n.aiServiceSaved);
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validate(l10n)) return;
    setState(() => _testing = true);
    final backend = CustomAiSentenceBackend(config: _draftConfig());
    try {
      await backend.testConnection().timeout(const Duration(seconds: 60));
      if (!mounted) return;
      _showSnackBar(l10n.aiServiceTestSuccess);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(l10n.aiServiceTestFailed(error.toString()));
    } finally {
      backend.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiService)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text(
                l10n.aiServiceDescription,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SwitchListTile(
            title: Text(l10n.aiServiceEnabled),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<String>(
            key: ValueKey(_vendorId),
            initialValue: _vendorId,
            decoration: InputDecoration(labelText: l10n.aiServiceVendor),
            items: [
              for (final preset in kCustomAiVendorPresets)
                DropdownMenuItem(value: preset.id, child: Text(preset.label)),
            ],
            onChanged: _applyVendor,
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.aiServiceBaseUrl,
              hintText: l10n.aiServiceBaseUrlHint,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.aiServiceApiKey,
              hintText: l10n.aiServiceApiKeyHint,
              suffixIcon: IconButton(
                tooltip: _obscureApiKey ? 'Show' : 'Hide',
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _modelController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.aiServiceModel,
              hintText: l10n.aiServiceModelHint,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: Text(
                    _testing ? l10n.aiServiceTesting : l10n.aiServiceTest,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l10n.aiServiceSave),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            l10n.aiServiceSecurityNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
