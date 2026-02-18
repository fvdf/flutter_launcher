import 'package:args/args.dart';

class CliArguments {
  final bool clean;
  final bool verbose;
  final bool dryRun;
  final bool help;

  CliArguments({
    required this.clean,
    required this.verbose,
    required this.dryRun,
    required this.help,
  });

  static CliArguments parse(List<String> args) {
    final parser = ArgParser()
      ..addFlag(
        'clean',
        help: 'Supprime le dossier build/flutter_launcher avant de commencer.',
      )
      ..addFlag('verbose', abbr: 'v', help: 'Affiche plus de logs.')
      ..addFlag(
        'dry-run',
        help: 'Affiche ce qui serait fait sans exécuter les générateurs.',
      )
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Affiche l\'aide.');

    final results = parser.parse(args);

    return CliArguments(
      clean: results['clean'] as bool,
      verbose: results['verbose'] as bool,
      dryRun: results['dry-run'] as bool,
      help: results['help'] as bool,
    );
  }

  static String getUsage() {
    final parser = ArgParser()
      ..addFlag(
        'clean',
        help: 'Supprime le dossier build/flutter_launcher avant de commencer.',
      )
      ..addFlag('verbose', abbr: 'v', help: 'Affiche plus de logs.')
      ..addFlag(
        'dry-run',
        help: 'Affiche ce qui serait fait sans exécuter les générateurs.',
      )
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Affiche l\'aide.');
    return parser.usage;
  }
}
