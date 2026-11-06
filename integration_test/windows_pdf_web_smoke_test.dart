import 'dart:io';

import 'package:echo_loop/l10n/app_localizations.dart';
import 'package:echo_loop/models/pdf_export/study_pdf_data.dart';
import 'package:echo_loop/services/pdf_export/study_pdf_export_service.dart';
import 'package:echo_loop/widgets/dictionary/web_dictionary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) return;

  testWidgets('Windows 生成 PDF 字节并可查询打印服务', (tester) async {
    final bytes = await StudyPdfExportService().buildBytes(
      const StudyPdfDocument(
        title: 'Echo Loop PDF Smoke',
        durationSeconds: 12,
        wordCount: 3,
        paragraphs: [
          [
            StudyPdfSentence(
              index: 0,
              text: 'Hello world, this is a Windows PDF smoke test.',
              grammar: '主系表结构。',
              vocabulary: 'smoke 冒烟测试。',
            ),
          ],
        ],
      ),
      labels: const StudyPdfLabels(
        metaDuration: '时长 00:12',
        metaSentences: '3 句',
        metaWords: '3 词',
        appendixTitle: '附录 · 句子解析',
        grammar: '语法',
        vocabulary: '词汇',
        listening: '听力',
      ),
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    final file = File(
      p.join(Directory.systemTemp.path, 'echo_loop_pdf_smoke.pdf'),
    );
    await file.writeAsBytes(bytes);
    expect(await file.length(), bytes.length);

    final info = await Printing.info();
    expect(info.canPrint, isTrue);
  });

  testWidgets('Windows WebView2 可加载网页词典页面', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!doctype html>
<html><head><meta charset="utf-8"><title>Smoke</title></head>
<body><h1>Echo Loop Web Dictionary Smoke</h1><p>WebView2 is working.</p></body></html>
''');
      await request.response.close();
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: WebDictionaryView(
                sourceId: 'smoke',
                url: Uri.parse('http://127.0.0.1:${server.port}/'),
                adFilteringEnabled: false,
              ),
            ),
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(WebDictionaryView)),
      )!;
      var loaded = false;
      for (var attempt = 0; attempt < 40; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        final loading = find.byType(CircularProgressIndicator).evaluate();
        final failed = find.text(l10n.aiLoadFailed).evaluate();
        if (loading.isEmpty && failed.isEmpty) {
          loaded = true;
          break;
        }
      }
      expect(loaded, isTrue, reason: 'WebView2 应在超时前完成内容渲染，且不应显示加载失败');
      expect(find.text(l10n.aiLoadFailed), findsNothing);
    } finally {
      await server.close(force: true);
    }
  });
}
