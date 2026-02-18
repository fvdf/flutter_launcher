import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/config_parser.dart';
import '../cli/cli_arguments.dart';
import '../utils/logger.dart';
import 'icon_renderer/icon_renderer.dart';
import 'launcher_icons_runner.dart';
import 'native_splash_runner.dart';

class Launcher {
  final CliArguments args;
  final String projectPath;
  late final String workingDir;

  Launcher(this.args, this.projectPath) {
    workingDir = p.join(projectPath, 'build', 'flutter_launcher');
  }

  Future<void> execute() async {
    try {
      Logger.verbose = args.verbose;
      Logger.section('Flutter Launcher');

      if (args.clean) {
        _clean();
      }

      Logger.step('Chargement du pubspec.yaml');
      final config = ConfigParser.parsePubspec(projectPath);

      if (args.dryRun) {
        Logger.warn(
            'Mode DRY-RUN activé. Aucune modification ne sera effectuée.');
        return;
      }

      _prepareWorkingDir();

      // 1. Render base PNGs
      final renderer = IconRenderer(workingDir, config);
      await renderer.render();

      // 2. Run App Icons Generator
      final iconsRunner = LauncherIconsRunner(workingDir, config);
      await iconsRunner.run();

      // 3. Run Native Splash Generator
      final splashRunner = NativeSplashRunner(workingDir, config);
      await splashRunner.run();

      Logger.section('TERMINE AVEC SUCCÈS');
      print('Votre application a été mise à jour avec les nouveaux assets.');
    } catch (e) {
      Logger.error(e.toString());
      exit(1);
    }
  }

  void _clean() {
    final dir = Directory(workingDir);
    if (dir.existsSync()) {
      Logger.info('Nettoyage de $workingDir...');
      dir.deleteSync(recursive: true);
    }
  }

  void _prepareWorkingDir() {
    final dir = Directory(workingDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
}
