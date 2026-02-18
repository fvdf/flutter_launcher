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
    yaml += '  color: "${config.theme.light.background ?? "#FFFFFF"}"\n';
    yaml += '  image: "build/flutter_launcher/app_icon_light.png"\n';

    if (config.theme.dark != null) {
      yaml += '  color_dark: "${config.theme.dark!.background ?? "#000000"}"\n';
      yaml += '  image_dark: "build/flutter_launcher/app_icon_dark.png"\n';
    }

    if (config.splash.android12) {
      yaml += '  android_12:\n';
      yaml += '    color: "${config.theme.light.background ?? "#FFFFFF"}"\n';
      yaml += '    image: "build/flutter_launcher/app_icon_light.png"\n';
      if (config.theme.dark != null) {
        yaml +=
            '    color_dark: "${config.theme.dark!.background ?? "#000000"}"\n';
        yaml += '    image_dark: "build/flutter_launcher/app_icon_dark.png"\n';
      }
    }

    yaml += '  fullscreen: ${config.splash.fullscreen}\n';

    // Platforms (Filter only supported ones)
    final supportedSplashPlatforms = ['android', 'ios', 'web'];
    config.platforms.forEach((key, value) {
      if (value && supportedSplashPlatforms.contains(key)) {
        yaml += '  $key: true\n';
      }
    });

    return yaml;
  }
}
