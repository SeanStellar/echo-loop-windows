import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Windows 背景下载器可下载本地 HTTP 文件',
    (tester) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.binary;
        request.response.add(List<int>.generate(64 * 1024, (i) => i % 256));
        await request.response.close();
      });

      const filename = 'bd_windows_smoke.bin';
      const directory = 'echo_loop_download_smoke';
      final temp = await getTemporaryDirectory();
      final task = DownloadTask(
        taskId: 'bd_windows_smoke',
        url: 'http://127.0.0.1:${server.port}/$filename',
        filename: filename,
        directory: directory,
        baseDirectory: BaseDirectory.temporary,
        updates: Updates.status,
      );

      try {
        final status = await FileDownloader().download(task);
        expect(status.status, TaskStatus.complete);
        final file = File(p.join(temp.path, directory, filename));
        expect(await file.exists(), isTrue);
        expect(await file.length(), 64 * 1024);
        await file.delete();
      } finally {
        await server.close(force: true);
      }
    },
    skip: !Platform.isWindows,
  );
}
