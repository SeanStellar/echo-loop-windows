import 'dart:io';

import 'package:echo_loop/features/audio_import/audio_transcode_service.dart';
import 'package:echo_loop/services/asr/offline_asr_engine.dart';
import 'package:echo_loop/services/asr/sherpa_onnx_engine.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Windows 本地转录：m4a → 16kHz WAV → sherpa 分段转录',
    (tester) async {
      final temp = await getTemporaryDirectory();
      final appSupport = await getApplicationSupportDirectory();
      final source = File(p.join(temp.path, 'windows_local_asr_a1.m4a'));
      final wav = File(p.join(temp.path, 'windows_local_asr_a1_16k.wav'));

      final data = await rootBundle.load(
        'assets/demo/A1 - Class Information.m4a',
      );
      await source.writeAsBytes(data.buffer.asUint8List(), flush: true);

      final transcoded = await AudioTranscodeService().transcodeToPcmWav16k(
        source: source,
        output: wav,
      );
      expect(transcoded, isTrue, reason: 'ffmpeg 应能在 Windows 解码 m4a');
      expect(await wav.length(), greaterThan(16000));

      final modelDir = Directory(
        p.join(
          appSupport.path,
          'asr-models',
          'whisper-base-en-int8',
        ),
      );
      expect(modelDir.existsSync(), isTrue, reason: '本地应已安装 base 模型');

      final engine = SherpaOnnxEngine();
      try {
        await engine.initialize(
          AsrModelConfig(
            model: const AsrModelInfo(
              id: 'whisper-base-en-int8',
              displayName: 'Whisper Base.en',
              type: AsrModelType.whisper,
            ),
            modelDir: modelDir.path,
          ),
        );
        expect(engine.isReady, isTrue);
        final segments = await engine.transcribeSegments(wav.path);
        expect(segments, isNotEmpty);
        final text = segments
            .map((segment) => segment.text)
            .join(' ')
            .toLowerCase();
        expect(text, contains('information'));
      } finally {
        await engine.dispose();
        if (await source.exists()) await source.delete();
        if (await wav.exists()) await wav.delete();
      }
    },
    skip: !Platform.isWindows,
  );
}
