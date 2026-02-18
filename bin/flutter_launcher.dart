import 'dart:io';
import 'package:flutter_launcher/src/cli/cli_arguments.dart';
import 'package:flutter_launcher/src/generators/launcher.dart';

Future<void> main(List<String> args) async {
  final cliArgs = CliArguments.parse(args);

  if (cliArgs.help) {
    print('Usage: dart run flutter_launcher [options]');
    print(CliArguments.getUsage());
    return;
  }

  final projectPath = Directory.current.path;
  final launcher = Launcher(cliArgs, projectPath);
  await launcher.execute();
}
