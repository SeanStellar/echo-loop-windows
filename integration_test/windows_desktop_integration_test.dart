import 'dart:io';

import 'package:echo_loop/providers/desktop_integration_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _runKey =
    r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'Echo Loop';

Future<ProcessResult> _queryRunValue() {
  return Process.run('reg', ['query', _runKey, '/v', _valueName]);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) return;

  testWidgets('开机自启写入 HKCU Run 并可移除', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(desktopIntegrationProvider.notifier);

    try {
      await notifier.setLaunchAtStartup(true);
      final enabled = await _queryRunValue();
      expect(enabled.exitCode, 0);
      expect(enabled.stdout.toString(), contains(Platform.resolvedExecutable));
      expect(
        container.read(desktopIntegrationProvider).launchAtStartup,
        isTrue,
      );
    } finally {
      await notifier.setLaunchAtStartup(false);
    }

    final disabled = await _queryRunValue();
    expect(disabled.exitCode, isNot(0));
    expect(
      container.read(desktopIntegrationProvider).launchAtStartup,
      isFalse,
    );
  });
}
