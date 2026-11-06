// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_integration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 托盘 / 开机自启偏好。
///
/// 开机自启以注册表实际状态为准：启动时读一次并回写 SP，避免用户在
/// Windows 设置里手动关闭后，应用内仍显示开启。

@ProviderFor(DesktopIntegration)
final desktopIntegrationProvider = DesktopIntegrationProvider._();

/// 托盘 / 开机自启偏好。
///
/// 开机自启以注册表实际状态为准：启动时读一次并回写 SP，避免用户在
/// Windows 设置里手动关闭后，应用内仍显示开启。
final class DesktopIntegrationProvider
    extends $NotifierProvider<DesktopIntegration, DesktopIntegrationState> {
  /// 托盘 / 开机自启偏好。
  ///
  /// 开机自启以注册表实际状态为准：启动时读一次并回写 SP，避免用户在
  /// Windows 设置里手动关闭后，应用内仍显示开启。
  DesktopIntegrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopIntegrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopIntegrationHash();

  @$internal
  @override
  DesktopIntegration create() => DesktopIntegration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopIntegrationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopIntegrationState>(value),
    );
  }
}

String _$desktopIntegrationHash() =>
    r'b82ac2a22afd0f5752d80d12c79b8d60b0789935';

/// 托盘 / 开机自启偏好。
///
/// 开机自启以注册表实际状态为准：启动时读一次并回写 SP，避免用户在
/// Windows 设置里手动关闭后，应用内仍显示开启。

abstract class _$DesktopIntegration extends $Notifier<DesktopIntegrationState> {
  DesktopIntegrationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<DesktopIntegrationState, DesktopIntegrationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopIntegrationState, DesktopIntegrationState>,
              DesktopIntegrationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
