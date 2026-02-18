import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/config_model.dart';
import '../utils/logger.dart';

class NativeSplashRunner {
  final String workingDir;
  final LauncherConfig config;

  NativeSplashRunner(this.workingDir, this.config);

  Future<void> run() async {
    if (!config.splash.enabled) {
      Logger.warn('Splash screen désactivé dans la config.');
      return;
    }

    Logger.step(
        'Configuration native du Splash Screen (via flutter_native_splash)');

    final configFile = File(p.join(workingDir, 'flutter_native_splash.yaml'));
    configFile.writeAsStringSync(_generateConfig());

    final process = await Process.start(
      'dart',
      ['run', 'flutter_native_splash:create', '--path=${configFile.path}'],
    );

    process.stdout.transform(utf8.decoder).listen(Logger.pipe);
    process.stderr.transform(utf8.decoder).listen(Logger.pipe);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
          'flutter_native_splash a échoué. Relancez avec --verbose.');
    }

    Logger.success('Splash screen intégré.');
  }

  String _generateConfig() {
    String yaml = 'flutter_native_splash:\n';
    yaml += '  color: "${config.theme.light.primary}"\n';
    yaml += '  image: "build/flutter_launcher/app_icon_light.png"\n';

    if (config.theme.dark != null) {
      yaml += '  color_dark: "${config.theme.dark!.primary}"\n';
      yaml += '  image_dark: "build/flutter_launcher/app_icon_dark.png"\n';
    }

    yaml += '  android_12: ${config.splash.android12}\n';
    yaml += '  fullscreen: ${config.splash.fullscreen}\n';

    // Platforms
    config.platforms.forEach((key, value) {
      if (value) {
        yaml += '  $key: true\n';
      }
    });

    return yaml;
  }
}
