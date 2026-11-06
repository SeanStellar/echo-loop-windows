import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

/// 通过 Windows Runtime 查询 / 控制当前 SMTC 会话。
const String _smtcPowerShellScript = r'''
param([string]$Action = 'query')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime] | Out-Null

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
})[0]

function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

$manager = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
$session = $manager.GetCurrentSession()
if ($null -eq $session) {
    Write-Output 'NO_SESSION'
    exit 0
}

if ($Action -eq 'pause') {
    [void](Await ($session.TryPauseAsync()) ([bool]))
    Write-Output 'ACTION_OK'
    exit 0
}
if ($Action -eq 'play') {
    [void](Await ($session.TryPlayAsync()) ([bool]))
    Write-Output 'ACTION_OK'
    exit 0
}

$props = Await ($session.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
$info = $session.GetPlaybackInfo()
Write-Output ("APP=" + $session.SourceAppUserModelId)
Write-Output ("TITLE=" + $props.Title)
Write-Output ("ARTIST=" + $props.Artist)
Write-Output ("ALBUM=" + $props.AlbumTitle)
Write-Output ("STATUS=" + $info.PlaybackStatus)
''';

class _SmtcTestHandler extends BaseAudioHandler {
  final pauseReceived = Completer<void>();
  final playReceived = Completer<void>();

  @override
  Future<void> play() async {
    if (!playReceived.isCompleted) playReceived.complete();
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> pause() async {
    if (!pauseReceived.isCompleted) pauseReceived.complete();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) return;

  late File scriptFile;

  Future<String> runSmtc(String action) async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptFile.path,
      '-Action',
      action,
    ]);
    expect(result.exitCode, 0, reason: 'PowerShell failed: ${result.stderr}');
    return result.stdout.toString().trim();
  }

  testWidgets('Windows SMTC 发布元数据并响应系统暂停/播放', (tester) async {
    scriptFile = File(
      p.join(Directory.systemTemp.path, 'echo_loop_smtc_probe.ps1'),
    );
    await scriptFile.writeAsString(_smtcPowerShellScript);

    final handler = _SmtcTestHandler();
    await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'top.valuespot.EchoLoop',
        androidNotificationChannelName: 'Echo Loop SMTC Smoke',
      ),
    );
    handler.mediaItem.add(
      const MediaItem(
        id: 'smtc-smoke',
        title: 'Echo Loop SMTC Smoke',
        artist: 'Echo Loop',
        album: 'Smoke Test',
      ),
    );
    handler.playbackState.add(
      PlaybackState(
        controls: const [MediaControl.pause],
        systemActions: const {MediaAction.pause},
        processingState: AudioProcessingState.ready,
        playing: true,
      ),
    );

    String? snapshot;
    for (var attempt = 0; attempt < 15; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
      snapshot = await runSmtc('query');
      if (snapshot.contains('TITLE=Echo Loop SMTC Smoke') &&
          snapshot.contains('STATUS=Playing')) {
        break;
      }
    }
    expect(snapshot, contains('TITLE=Echo Loop SMTC Smoke'));
    expect(snapshot, contains('ARTIST=Echo Loop'));
    expect(snapshot, contains('STATUS=Playing'));

    expect(await runSmtc('pause'), 'ACTION_OK');
    await handler.pauseReceived.future.timeout(const Duration(seconds: 5));
    String? paused;
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.pump(const Duration(milliseconds: 300));
      paused = await runSmtc('query');
      if (paused.contains('STATUS=Paused')) break;
    }
    expect(paused, contains('STATUS=Paused'));

    expect(await runSmtc('play'), 'ACTION_OK');
    await handler.playReceived.future.timeout(const Duration(seconds: 5));
  });
}
