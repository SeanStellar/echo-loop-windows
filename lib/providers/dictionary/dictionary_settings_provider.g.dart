// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 词典设置 Notifier

@ProviderFor(DictionarySettingsNotifier)
final dictionarySettingsProvider = DictionarySettingsNotifierProvider._();

/// 词典设置 Notifier
final class DictionarySettingsNotifierProvider
    extends $NotifierProvider<DictionarySettingsNotifier, DictionarySettings> {
  /// 词典设置 Notifier
  DictionarySettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictionarySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictionarySettingsNotifierHash();

  @$internal
  @override
  DictionarySettingsNotifier create() => DictionarySettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictionarySettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictionarySettings>(value),
    );
  }
}

String _$dictionarySettingsNotifierHash() =>
    r'49aa7a10a5e5b53cf40eb917ad254978cfb01a14';

/// 词典设置 Notifier

abstract class _$DictionarySettingsNotifier
    extends $Notifier<DictionarySettings> {
  DictionarySettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DictionarySettings, DictionarySettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DictionarySettings, DictionarySettings>,
              DictionarySettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
