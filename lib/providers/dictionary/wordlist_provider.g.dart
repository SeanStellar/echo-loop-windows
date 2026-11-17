// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wordlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 加载并解析本地词表。读取在主 isolate（rootBundle 仅主 isolate 可用），
/// 解析在后台 isolate 完成，不阻塞 UI 与用户输入。

@ProviderFor(wordlist)
final wordlistProvider = WordlistProvider._();

/// 加载并解析本地词表。读取在主 isolate（rootBundle 仅主 isolate 可用），
/// 解析在后台 isolate 完成，不阻塞 UI 与用户输入。

final class WordlistProvider
    extends
        $FunctionalProvider<
          AsyncValue<WordlistIndex>,
          WordlistIndex,
          FutureOr<WordlistIndex>
        >
    with $FutureModifier<WordlistIndex>, $FutureProvider<WordlistIndex> {
  /// 加载并解析本地词表。读取在主 isolate（rootBundle 仅主 isolate 可用），
  /// 解析在后台 isolate 完成，不阻塞 UI 与用户输入。
  WordlistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordlistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordlistHash();

  @$internal
  @override
  $FutureProviderElement<WordlistIndex> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WordlistIndex> create(Ref ref) {
    return wordlist(ref);
  }
}

String _$wordlistHash() => r'b51f6161e44991f9b965158e8da8d8af9f7f9593';
