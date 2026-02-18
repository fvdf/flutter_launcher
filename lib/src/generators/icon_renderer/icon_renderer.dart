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
    final testDir = Directory(p.join(path, 'test'));
    if (!testDir.existsSync()) testDir.createSync();

    File(p.join(path, 'test', 'render_test.dart'))
        .writeAsStringSync(_generateTestCode());
  }

  String _generateTestCode() {
    final styleSuffix = _getStyleSuffix(config.icon.style);

    return '''
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Cette fonction est nécessaire pour que les tests Flutter chargent les polices par défaut
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render icons', (WidgetTester tester) async {
    print('[RENDERER] Début du rendu...');
    
    // On doit forcer une taille de fenêtre pour le rendu
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;

    await _renderIcon(
      tester,
      name: 'app_icon_light.png',
      bgColor: _parseColor('${config.theme.light.primary}'),
      fgColor: _parseColor('${config.theme.light.secondary ?? "#FFFFFF"}'),
    );

    if ('${config.theme.dark?.primary ?? ""}'.isNotEmpty) {
      await _renderIcon(
        tester,
        name: 'app_icon_dark.png',
        bgColor: _parseColor('${config.theme.dark?.primary ?? "#000000"}'),
        fgColor: _parseColor('${config.theme.dark?.secondary ?? "#FFFFFF"}'),
      );
    }
    print('[RENDERER] Rendu terminé avec succès.');
  });
}

Future<void> _renderIcon(
  WidgetTester tester, {
  required String name,
  required Color bgColor,
  required Color fgColor,
}) async {
  print('  - Construction du widget pour ' + name + '...');
  final key = GlobalKey();
  
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: 1024,
          height: 1024,
          color: bgColor,
          child: Center(
            child: Icon(
              IconData(${_getSymbolCode(config.icon.symbol)}, fontFamily: 'MaterialIcons$styleSuffix'),
              color: fgColor,
              size: 1024 * (1.0 - ${config.icon.padding} * 2),
            ),
          ),
        ),
      ),
    ),
  );

  print('  - Attente du rendu (pump)...');
  await tester.pump(); 

  print('  - Capture de l image...');
  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  
  print('  - Encodage PNG (via runAsync)...');
  final byteData = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
  
  if (byteData == null) {
    print('  [ERREUR] byteData est null');
    throw Exception('Échec de l encodage PNG');
  }
  
  print('  - Écriture du fichier (via runAsync)...');
  final file = File('../' + name);
  await tester.runAsync(() => file.writeAsBytes(byteData.buffer.asUint8List()));
  
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
