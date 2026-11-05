/// 评分阈值配置
///
/// 定义各场景的评分等级阈值，供评级 Badge、倒计时算法等共用。
library;

/// 评分阈值配置
class RatingThresholds {
  /// Perfect 阈值。
  final double perfect;

  /// Excellent 阈值。
  final double excellent;

  /// Good 阈值。
  final double good;

  /// Fair 阈值。
  final double fair;

  const RatingThresholds({
    required this.perfect,
    required this.excellent,
    required this.good,
    required this.fair,
  });

  /// 跟读场景默认阈值。
  static const listenAndRepeat = RatingThresholds(
    perfect: 0.95,
    excellent: 0.80,
    good: 0.60,
    fair: 0.40,
  );

  /// 复述场景阈值（比跟读宽松）。
  static const retell = RatingThresholds(
    perfect: 0.90,
    excellent: 0.75,
    good: 0.50,
    fair: 0.20,
  );
}
