import 'package:args/args.dart';

class CliArguments {
  final bool clean;
  final bool verbose;
  final bool dryRun;
  final bool help;
  final bool renderOnly;
  final String? symbolCheck;

  CliArguments({
    required this.clean,
    required this.verbose,
    required this.dryRun,
    required this.help,
    required this.renderOnly,
    this.symbolCheck,
  });

  static CliArguments parse(List<String> args) {
    final parser = _getParser();
    final results = parser.parse(args);

    return CliArguments(
      clean: results['clean'] as bool,
      verbose: results['verbose'] as bool,
      dryRun: results['dry-run'] as bool,
      help: results['help'] as bool,
      renderOnly: results['render-only'] as bool,
      symbolCheck: results['symbol-check'] as String?,
    );
  }

  static ArgParser _getParser() {
    return ArgParser()
      ..addFlag('clean', help: 'Supprime le dossier build/flutter_launcher.')
      ..addFlag('verbose', abbr: 'v', help: 'Affiche plus de logs.')
      ..addFlag('dry-run', help: 'Affiche ce qui serait fait sans exécuter.')
      ..addFlag('render-only',
          help: 'Exécute uniquement le rendu des icônes de base.')
      ..addOption('symbol-check',
          help: 'Rendu d\'un symbole spécifique pour test (ex: settings).')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Affiche l\'aide.');
  }

  static String getUsage() {
    return _getParser().usage;
  }
}
