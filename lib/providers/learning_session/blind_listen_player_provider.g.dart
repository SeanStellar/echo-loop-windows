// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_listen_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 盲听专用播放器 Provider

@ProviderFor(BlindListenPlayer)
final blindListenPlayerProvider = BlindListenPlayerProvider._();

/// 盲听专用播放器 Provider
final class BlindListenPlayerProvider
    extends $NotifierProvider<BlindListenPlayer, BlindListenPlayerState> {
  /// 盲听专用播放器 Provider
  BlindListenPlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blindListenPlayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blindListenPlayerHash();

  @$internal
  @override
  BlindListenPlayer create() => BlindListenPlayer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlindListenPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlindListenPlayerState>(value),
    );
  }
}

String _$blindListenPlayerHash() => r'80427865af40b25effb32b00d2d55b8ab4c3f292';

/// 盲听专用播放器 Provider

abstract class _$BlindListenPlayer extends $Notifier<BlindListenPlayerState> {
  BlindListenPlayerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<BlindListenPlayerState, BlindListenPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BlindListenPlayerState, BlindListenPlayerState>,
              BlindListenPlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
