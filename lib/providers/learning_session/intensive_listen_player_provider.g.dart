// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intensive_listen_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IntensiveListenPlayer)
final intensiveListenPlayerProvider = IntensiveListenPlayerProvider._();

final class IntensiveListenPlayerProvider
    extends $NotifierProvider<IntensiveListenPlayer, IntensiveListenState> {
  IntensiveListenPlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intensiveListenPlayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intensiveListenPlayerHash();

  @$internal
  @override
  IntensiveListenPlayer create() => IntensiveListenPlayer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntensiveListenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntensiveListenState>(value),
    );
  }
}

String _$intensiveListenPlayerHash() =>
    r'daa4585f443fc72b44296e29f4b8215c3e7ed7d2';

abstract class _$IntensiveListenPlayer extends $Notifier<IntensiveListenState> {
  IntensiveListenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IntensiveListenState, IntensiveListenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IntensiveListenState, IntensiveListenState>,
              IntensiveListenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
