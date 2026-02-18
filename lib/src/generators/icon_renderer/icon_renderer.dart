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
flutter:
  uses-material-design: true
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
    final styleSuffix = _getStyleSuffix(config.icon.style);

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
        fontFamily: 'MaterialIcons$styleSuffix',
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
''';
  }

  String _getStyleSuffix(String style) {
    switch (style.toLowerCase()) {
      case 'rounded':
        return '_Rounded';
      case 'sharp':
        return '_Sharp';
      case 'outlined':
        return '_Outlined';
      default:
        return '';
    }
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

  int _getSymbolCode(String name) {
    final map = {
      'settings': 0xe8b8,
      'home': 0xe88a,
      'person': 0xe7fd,
      'favorite': 0xe87d,
      'search': 0xe8b6,
      'star': 0xe838,
      'add': 0xe145,
      'menu': 0xe5d2,
      'close': 0xe5cd,
      'check': 0xe5ca,
      'notifications': 0xe7f4,
      'mail': 0xe158,
      'camera': 0xe3af,
      'image': 0xe3f4,
      'play_arrow': 0xe037,
      'pause': 0xe034,
      'stop': 0xe047,
      'shopping_cart': 0xe8cc,
      'info': 0xe88e,
      'help': 0xe887,
      'warning': 0xe002,
      'error': 0xe000,
      'account_circle': 0xe853,
      'arrow_forward': 0xe5c8,
      'arrow_back': 0xe5c4,
      'refresh': 0xe5d5,
      'share': 0xe80d,
      'thumb_up': 0xe8dc,
      'thumb_down': 0xe8db,
      'visibility': 0xe8f4,
      'visibility_off': 0xe8f5,
      'lock': 0xe897,
      'unlock': 0xe898,
      'map': 0xe55b,
      'place': 0xe55f,
      'phone': 0xe0cd,
      'email': 0xe0be,
      'event': 0xe878,
      'schedule': 0xe8b5,
      'cloud': 0xe2bd,
      'download': 0xf090,
      'upload': 0xf09b,
      'delete': 0xe872,
      'edit': 0xe3c9,
      'save': 0xe161,
      'rocket': 0xeba5,
      'bolt': 0xea0b,
      'eco': 0xea35,
      'pets': 0xe91d,
      'flight': 0xe539,
      'directions_car': 0xe531,
    };

    if (name.startsWith('0x')) {
      return int.tryParse(name.substring(2), radix: 16) ?? 0xe8b8;
    }

    return map[name.toLowerCase()] ?? 0xe8b8;
  }
}
