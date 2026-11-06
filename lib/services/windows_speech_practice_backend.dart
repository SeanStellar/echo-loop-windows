/// Windows 桌面录音后端。
///
/// 仅负责录音与事件（speechStarted / silenceProgress / finalTranscriptReady）；
/// 空 transcript 由 [OfflineAsrBackend] 交给 sherpa-onnx 离线引擎补转录。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/speech_practice_models.dart';
import 'app_logger.dart';
import 'speech_practice_platform.dart';

class WindowsSpeechPracticeBackend extends SpeechPracticePlatform {
  WindowsSpeechPracticeBackend();

  static const _tag = 'SpeechWin';

  /// 判定为“有人声”的 dBFS 阈值。录音环境底噪差异较大，先取较宽松的值。
  static const _speechThresholdDbfs = -35.0;

  AudioRecorder? _recorder;
  final StreamController<SpeechPracticeEvent> _eventController =
      StreamController<SpeechPracticeEvent>.broadcast();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _speechFallbackTimer;

  String? _promptId;
  String? _filePath;
  bool _isRecording = false;
  bool _speechDetected = false;
  DateTime? _lastVoicedAt;
  Duration _silenceDuration = Duration.zero;

  AudioRecorder get _ensureRecorder => _recorder ??= AudioRecorder();

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Stream<SpeechPracticeEvent> get events => _eventController.stream;

  @override
  Future<SpeechPracticePermissionState> getPermissionStatus() async {
    final granted = await _hasPermission(request: false);
    return SpeechPracticePermissionState(
      microphone: granted
          ? SpeechPracticePermissionStatus.granted
          : SpeechPracticePermissionStatus.notDetermined,
      // Windows 只使用离线 ASR，不需要平台语音识别权限。
      speech: SpeechPracticePermissionStatus.granted,
    );
  }

  @override
  Future<SpeechPracticePermissionState> requestPermissions({
    bool onlyMic = false,
  }) async {
    final granted = await _hasPermission(request: true);
    return SpeechPracticePermissionState(
      microphone: granted
          ? SpeechPracticePermissionStatus.granted
          : SpeechPracticePermissionStatus.denied,
      speech: granted
          ? SpeechPracticePermissionStatus.granted
          : SpeechPracticePermissionStatus.denied,
    );
  }

  Future<bool> _hasPermission({required bool request}) async {
    try {
      return await _ensureRecorder.hasPermission(request: request);
    } catch (error) {
      AppLogger.log(_tag, 'hasPermission failed: $error');
      return false;
    }
  }

  @override
  Future<int> getDeviceRamBytes() async {
    // 仅用于推荐 ASR 模型；Windows 版固定使用 whisper-base，给一个保守值即可。
    return 8 * 1024 * 1024 * 1024;
  }

  @override
  Future<void> setRecognitionEnabled(bool enabled) async {
    // Windows 使用离线 ASR；平台原生识别不参与，保留接口语义。
    AppLogger.log(_tag, 'setRecognitionEnabled=$enabled');
  }

  @override
  Future<void> warmup({String locale = 'en-US'}) async {
    // 录音器在 startSession 时惰性创建；warmup 不启动任何设备。
    AppLogger.log(_tag, 'warmup locale=$locale');
  }

  @override
  Future<String> startSession({
    required String promptId,
    String locale = 'en-US',
  }) async {
    if (!isSupported) {
      throw const SpeechPracticePlatformException(
        'notAvailable',
        'Speech practice is not supported on this platform',
      );
    }
    if (_isRecording) {
      throw const SpeechPracticePlatformException(
        'alreadyRecording',
        'A recording session is already active.',
      );
    }

    final granted = await _hasPermission(request: true);
    if (!granted) {
      throw const SpeechPracticePlatformException(
        'permissionDenied',
        'Microphone permission denied.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final recordingsDir = Directory(
      p.join(tempDir.path, 'echo_loop_recordings'),
    );
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final filePath = p.join(
      recordingsDir.path,
      'rec_${DateTime.now().microsecondsSinceEpoch}.wav',
    );

    try {
      await _ensureRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: filePath,
      );
    } catch (error) {
      throw SpeechPracticePlatformException('startFailed', '$error');
    }

    _promptId = promptId;
    _filePath = filePath;
    _isRecording = true;
    _speechDetected = false;
    _lastVoicedAt = null;
    _silenceDuration = Duration.zero;

    _startAmplitudeMonitor(promptId);
    AppLogger.log(_tag, 'startSession promptId=$promptId filePath=$filePath');
    return filePath;
  }

  void _startAmplitudeMonitor(String promptId) {
    _amplitudeSub?.cancel();
    try {
      _amplitudeSub = _ensureRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen(
            _onAmplitude,
            onError: (Object error) {
              AppLogger.log(_tag, 'amplitude stream error: $error');
            },
          );
    } catch (error) {
      AppLogger.log(_tag, 'amplitude monitor unavailable: $error');
    }

    // 部分设备/声卡不会产生稳定的 amplitude 事件；兜底让流程进入“说话中”，
    // 否则 UI 会一直停在等待开口。停止仍由用户或上层静音检测驱动。
    _speechFallbackTimer?.cancel();
    _speechFallbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (!_isRecording || _speechDetected || _promptId != promptId) return;
      _speechDetected = true;
      _lastVoicedAt = DateTime.now();
      _emit(
        SpeechPracticeEvent(
          type: SpeechPracticeEventType.speechStarted,
          promptId: promptId,
        ),
      );
    });
  }

  void _onAmplitude(Amplitude amplitude) {
    if (!_isRecording) return;
    final promptId = _promptId;
    if (promptId == null) return;

    final isVoiced = amplitude.current > _speechThresholdDbfs;
    final now = DateTime.now();

    if (isVoiced) {
      _lastVoicedAt = now;
      _silenceDuration = Duration.zero;
      if (!_speechDetected) {
        _speechDetected = true;
        _emit(
          SpeechPracticeEvent(
            type: SpeechPracticeEventType.speechStarted,
            promptId: promptId,
          ),
        );
      }
      _emit(
        SpeechPracticeEvent(
          type: SpeechPracticeEventType.silenceProgress,
          promptId: promptId,
          silenceDuration: Duration.zero,
        ),
      );
      return;
    }

    if (!_speechDetected) return;
    final lastVoicedAt = _lastVoicedAt ?? now;
    _silenceDuration = now.difference(lastVoicedAt);
    _emit(
      SpeechPracticeEvent(
        type: SpeechPracticeEventType.silenceProgress,
        promptId: promptId,
        silenceDuration: _silenceDuration,
      ),
    );
  }

  @override
  Future<SpeechPracticeStopResult> stopSession() async {
    final promptId = _promptId;
    final originalPath = _filePath;
    String? filePath = originalPath;

    try {
      filePath = await _ensureRecorder.stop() ?? originalPath;
    } catch (error) {
      AppLogger.log(_tag, 'stop failed: $error');
    }

    _isRecording = false;
    _speechFallbackTimer?.cancel();
    _speechFallbackTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _promptId = null;
    _filePath = null;
    _speechDetected = false;
    _silenceDuration = Duration.zero;

    if (promptId != null) {
      // 空 transcript：OfflineAsrBackend 会用当前录音文件做 sherpa 转录。
      _emit(
        SpeechPracticeEvent(
          type: SpeechPracticeEventType.finalTranscriptReady,
          promptId: promptId,
          transcript: '',
        ),
      );
    }

    AppLogger.log(_tag, 'stopSession filePath=${filePath ?? '(null)'}');
    return SpeechPracticeStopResult(filePath: filePath);
  }

  @override
  Future<void> cancelSession() async {
    _isRecording = false;
    _speechFallbackTimer?.cancel();
    _speechFallbackTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = _filePath;
    _promptId = null;
    _filePath = null;
    _speechDetected = false;
    _silenceDuration = Duration.zero;

    try {
      await _ensureRecorder.cancel();
    } catch (error) {
      AppLogger.log(_tag, 'cancel failed: $error');
    }
    if (path != null) {
      await deleteRecording(path);
    }
  }

  @override
  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.log(_tag, 'deleted recording $filePath');
      }
    } catch (error) {
      AppLogger.log(_tag, 'deleteRecording failed: $error');
    }
  }

  @override
  Future<void> shutdown() async {
    _isRecording = false;
    _speechFallbackTimer?.cancel();
    _speechFallbackTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _promptId = null;
    _filePath = null;
    _speechDetected = false;
    _silenceDuration = Duration.zero;
    try {
      await _recorder?.dispose();
    } catch (error) {
      AppLogger.log(_tag, 'dispose failed: $error');
    }
    _recorder = null;
  }

  void _emit(SpeechPracticeEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
}
