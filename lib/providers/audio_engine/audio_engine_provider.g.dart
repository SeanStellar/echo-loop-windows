// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AudioEngine)
final audioEngineProvider = AudioEngineProvider._();

final class AudioEngineProvider
    extends $NotifierProvider<AudioEngine, AudioEngineState> {
  AudioEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioEngineHash();

  @$internal
  @override
  AudioEngine create() => AudioEngine();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioEngineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioEngineState>(value),
    );
  }
}

String _$audioEngineHash() => r'9d37e8d986506f923c25e8f56f866bded04be141';

abstract class _$AudioEngine extends $Notifier<AudioEngineState> {
  AudioEngineState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AudioEngineState, AudioEngineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AudioEngineState, AudioEngineState>,
              AudioEngineState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
