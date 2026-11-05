/// 备份操作进度信息
class BackupProgress {
  /// 当前阶段描述（如"正在导出数据库..."）
  final String stage;

  /// 当前进度 0.0 ~ 1.0，-1 表示不确定
  final double progress;

  const BackupProgress({required this.stage, this.progress = -1});
}
