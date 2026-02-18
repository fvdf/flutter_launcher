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

    // On cherche le SDK Flutter pour copier la font
    final flutterSdkPath = await _getFlutterSdkPath();
    final fontSource = p.join(flutterSdkPath, 'bin', 'cache', 'artifacts',
        'material_fonts', 'MaterialIcons-Regular.otf');
    final fontDestDir = Directory(p.join(rendererDir.path, 'assets', 'fonts'));
    if (!fontDestDir.existsSync()) fontDestDir.createSync(recursive: true);

    final fontFile = File(fontSource);
    if (fontFile.existsSync()) {
      Logger.debug('Copie de la police MaterialIcons depuis le SDK...');
      fontFile.copySync(p.join(fontDestDir.path, 'MaterialIcons-Regular.otf'));
    } else {
      Logger.warn(
          'Police MaterialIcons introuvable dans le SDK ($fontSource). Le rendu pourrait échouer.');
    }

    Logger.step('Préparation du projet de rendu temporaire');
    _prepareRendererProject(rendererDir.path);

    Logger.step(
        'Exécution du rendu Flutter (Premier lancement : téléchargement de l\'engine en cours...)');
    await _runRenderer(rendererDir.path);

    Logger.success('Images de base générées dans build/flutter_launcher');
  }

  Future<String> _getFlutterSdkPath() async {
    try {
      final res = await Process.run('which', ['flutter']);
      if (res.exitCode == 0) {
        final flutterBin = res.stdout.toString().trim();
        return p.dirname(p.dirname(flutterBin));
      }
    } catch (_) {}
    return ''; // Fallback empty
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
  image: ^4.0.0
flutter:
  uses-material-design: true
  fonts:
    - family: MaterialIcons
      fonts:
        - asset: assets/fonts/MaterialIcons-Regular.otf
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
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render icons', (WidgetTester tester) async {
    print('[RENDERER] Début du rendu...');
    
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
  print('  - Rendu de ' + name + '...');
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
              IconData(${_getSymbolCode(config.icon.symbol)}, fontFamily: 'MaterialIcons'),
              color: fgColor,
              size: 1024 * (1.0 - ${config.icon.padding} * 2),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();

  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  
  // Utilisation de runAsync pour toutes les opérations lourdes
  await tester.runAsync(() async {
    print('    * Capture de la surface...');
    final image = await boundary.toImage(pixelRatio: 1.0);
    
    print('    * Extraction des pixels (rawRgba)...');
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('byteData est null');

    print('    * Encodage PNG avec package:image...');
    final rawBytes = byteData.buffer.asUint8List();
    final imgImage = img.Image.fromBytes(
      width: 1024,
      height: 1024,
      bytes: rawBytes.buffer,
      order: img.ChannelOrder.rgba,
    );
    
    final pngBytes = img.encodePng(imgImage);
    
    print('    * Écriture du fichier...');
    final file = File('../' + name);
    await file.writeAsBytes(pngBytes);
  });
  
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
      throw Exception('Rendu échoué.');
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
