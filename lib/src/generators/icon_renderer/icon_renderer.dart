import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../config/config_model.dart';
import '../../utils/logger.dart';

class IconRenderer {
  final String workingDir;
  final LauncherConfig config;

  IconRenderer(this.workingDir, this.config);

  Future<void> render() async {
    Logger.step('Initialisation du moteur de rendu');

    final rendererDir = Directory(p.join(workingDir, 'renderer'));
    if (!rendererDir.existsSync()) {
      rendererDir.createSync(recursive: true);
    }

    Logger.step('Préparation du projet de rendu temporaire');
    _prepareRendererProject(rendererDir.path);

    Logger.step(
        'Exécution du rendu Flutter (Premier lancement : téléchargement de l\'engine en cours...)');
    await _runRenderer(rendererDir.path);

    Logger.success('Images de base générées dans build/flutter_launcher');
  }

  void _prepareRendererProject(String path) {
    Logger.debug('Création du fichier pubspec.yaml du renderer...');
    // 1. pubspec.yaml
    File(p.join(path, 'pubspec.yaml')).writeAsStringSync('''
name: launcher_icon_renderer
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

    Logger.debug('Création du code de test de rendu...');
    // 2. test/render_test.dart
    final testDir = Directory(p.join(path, 'test'));
    if (!testDir.existsSync()) testDir.createSync();

    File(
      p.join(path, 'test', 'render_test.dart'),
    ).writeAsStringSync(_generateTestCode());
  }

  String _generateTestCode() {
    return '''
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Render icons', () async {
    print('[RENDERER] Début du rendu...');
    
    print('[RENDERER] Rendu de app_icon_light.png...');
    await _renderIcon(
      name: 'app_icon_light.png',
      bgColor: _parseColor('${config.theme.light.primary}'),
      fgColor: _parseColor('${config.theme.light.secondary ?? "#FFFFFF"}'),
    );

    if ('${config.theme.dark?.primary ?? ""}'.isNotEmpty) {
      print('[RENDERER] Rendu de app_icon_dark.png...');
      await _renderIcon(
        name: 'app_icon_dark.png',
        bgColor: _parseColor('${config.theme.dark?.primary ?? "#000000"}'),
        fgColor: _parseColor('${config.theme.dark?.secondary ?? "#FFFFFF"}'),
      );
    }
    print('[RENDERER] Rendu terminé avec succès.');
  });
}

Future<void> _renderIcon({
  required String name,
  required Color bgColor,
  required Color fgColor,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 1024, 1024));
  
  // Background
  final paint = Paint()..color = bgColor;
  canvas.drawRect(Rect.fromLTWH(0, 0, 1024, 1024), paint);

  // Symbol
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(${_getSymbolCode(config.icon.symbol)}),
      style: TextStyle(
        color: fgColor,
        fontSize: 1024 * (1.0 - ${config.icon.padding} * 2),
        // On n'utilise pas de font spécifique pour éviter les hangs de chargement
        // Flutter utilisera la font système ou fallback.
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  final offset = Offset(
    (1024 - textPainter.width) / 2,
    (1024 - textPainter.height) / 2,
  );
  textPainter.paint(canvas, offset);

  final picture = recorder.endRecording();
  
  print('  - Encodage en PNG (1024x1024)...');
  final img = await picture.toImage(1024, 1024);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('../' + name);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  print('  - Fichier écrit : ' + name);
}

Color _parseColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF' + hex;
  return Color(int.parse(hex, radix: 16));
}

int _getSymbolCode(String name) {
  final map = {
    'settings': 0xe8b8,
    'home': 0xe88a,
    'person': 0xe7fd,
    'favorite': 0xe87d,
    'search': 0xe8b6,
    'star': 0xe838,
  };
  return map[name] ?? 0xe8b8;
}
''';
  }

  Future<void> _runRenderer(String path) async {
    final process = await Process.start(
      'flutter',
      ['test', 'test/render_test.dart'],
      workingDirectory: path,
    );

    process.stdout.transform(utf8.decoder).listen(Logger.pipe);
    process.stderr.transform(utf8.decoder).listen(Logger.pipe);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
          'Flutter test failed to render icons. Execute with --verbose for more info.');
    }
  }

  // Helper for symbol mapping (simplified)
  int _getSymbolCode(String name) {
    // Ideally we would have a full map, but for the sake of the exercise
    // we'll use a few common ones or a default.
    final map = {
      'settings': 0xe8b8,
      'home': 0xe88a,
      'person': 0xe7fd,
      'favorite': 0xe87d,
      'search': 0xe8b6,
      'star': 0xe838,
    };
    return map[name] ?? 0xe8b8;
  }
}
