/// 把 [DownloadFailureKind] 映射为面向用户的本地化文案（各下载类设置页共用）。
library;

import '../l10n/app_localizations.dart';
import '../services/download/download_failure.dart';

/// 返回下载失败原因对应的本地化提示：原因确定的给明确指引，[DownloadFailureKind.unknown]
/// 或 null 回退通用「下载失败，请重试」（[AppLocalizations.speechModelDownloadFailed]）。
String downloadFailureMessage(
  AppLocalizations l10n,
  DownloadFailureKind? kind,
) {
  switch (kind) {
    case DownloadFailureKind.insufficientStorage:
      return l10n.downloadErrorStorage;
    case DownloadFailureKind.network:
      return l10n.downloadErrorNetwork;
    case DownloadFailureKind.verification:
      return l10n.downloadErrorCorrupted;
    case DownloadFailureKind.unknown:
    case null:
      return l10n.speechModelDownloadFailed;
  }
}
