import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/config_model.dart';
import '../utils/logger.dart';

class LauncherIconsRunner {
  final String workingDir;
  final LauncherConfig config;

  LauncherIconsRunner(this.workingDir, this.config);

  Future<void> run() async {
    Logger.step(
        'Génération des assets multi-plateformes (via flutter_launcher_icons)');

    final configFile = File(p.join(workingDir, 'flutter_launcher_icons.yaml'));
    configFile.writeAsStringSync(_generateConfig());

    final process = await Process.start(
      'dart',
      ['run', 'flutter_launcher_icons', '-f', configFile.path],
    );

    process.stdout.transform(utf8.decoder).listen(Logger.pipe);
    process.stderr.transform(utf8.decoder).listen(Logger.pipe);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
          'flutter_launcher_icons a échoué. Relancez avec --verbose.');
    }

    Logger.success('Icônes d\'application générées.');
  }

  String _generateConfig() {
    final Map<String, bool> pMap = {
      'android': config.platforms['android'] ?? false,
      'ios': config.platforms['ios'] ?? false,
      'web': config.platforms['web'] ?? false,
      'windows': config.platforms['windows'] ?? false,
      'macos': config.platforms['macos'] ?? false,
      'linux': config.platforms['linux'] ?? false,
    };

    String yaml = 'flutter_launcher_icons:\n';
    yaml += '  image_path: "build/flutter_launcher/app_icon_light.png"\n';

    if (config.theme.dark != null) {
      yaml += '  image_path_dark: "build/flutter_launcher/app_icon_dark.png"\n';
    }

    // Android
    if (pMap['android'] == true) {
      yaml += '  android: true\n';
      yaml += '  adaptive_icon_background: "${config.theme.light.primary}"\n';
      yaml +=
          '  adaptive_icon_foreground: "build/flutter_launcher/app_icon_light.png"\n';
    }

    // iOS
    if (pMap['ios'] == true) {
      yaml += '  ios: true\n';
      yaml += '  remove_alpha_ios: true\n';
    }

    // Web (Needs a Map)
    if (pMap['web'] == true) {
      yaml += '  web:\n';
      yaml += '    generate: true\n';
      yaml += '    image_path: "build/flutter_launcher/app_icon_light.png"\n';
    }

    // Desktop Platforms (Usually need Maps in newer versions)
    if (pMap['windows'] == true) {
      yaml += '  windows:\n';
      yaml += '    generate: true\n';
    }
    if (pMap['macos'] == true) {
      yaml += '  macos:\n';
      yaml += '    generate: true\n';
    }
    if (pMap['linux'] == true) {
      yaml += '  linux:\n';
      yaml += '    generate: true\n';
    }

    return yaml;
  }
}
