import 'dart:io';
import 'dart:typed_data';

import 'package:echo_loop/services/windows_speech_practice_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Windows 录音后端能生成 16kHz/16bit PCM WAV',
    (tester) async {
      final backend = WindowsSpeechPracticeBackend();
      try {
        final startedPath = await backend.startSession(promptId: 'smoke');
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        final stopResult = await backend.stopSession();
        final filePath = stopResult.filePath ?? startedPath;
        final file = File(filePath);
        expect(await file.exists(), isTrue, reason: '录音文件应存在');
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(44), reason: 'WAV 应有音频数据');
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

        final byteData = ByteData.sublistView(bytes);
        var offset = 12;
        int? sampleRate;
        int? bitsPerSample;
        while (offset + 8 <= bytes.length) {
          final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          final size = byteData.getUint32(offset + 4, Endian.little);
          if (id == 'fmt ') {
            sampleRate = byteData.getUint32(offset + 12, Endian.little);
            bitsPerSample = byteData.getUint16(offset + 22, Endian.little);
            break;
          }
          offset += 8 + size + (size.isOdd ? 1 : 0);
        }
        expect(sampleRate, 16000);
        expect(bitsPerSample, 16);
        await backend.deleteRecording(filePath);
      } finally {
        await backend.shutdown();
      }
    },
    skip: !Platform.isWindows,
  );
}
