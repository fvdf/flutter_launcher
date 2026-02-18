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

    Logger.info('Génération du splash screen...');

    final configFile = File(p.join(workingDir, 'flutter_native_splash.yaml'));
    configFile.writeAsStringSync(_generateConfig());

    final result = await Process.run('dart', [
      'run',
      'flutter_native_splash:create',
      '--path=${configFile.path}',
    ]);

    if (result.exitCode != 0) {
      Logger.debug(result.stdout);
      Logger.error(result.stderr);
      throw Exception('flutter_native_splash a échoué.');
    }

    Logger.info('Splash screen généré avec succès.');
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
