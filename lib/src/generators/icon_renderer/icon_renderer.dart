import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../config/config_model.dart';
import '../../utils/logger.dart';

class IconRenderer {
  final String workingDir;
  final LauncherConfig config;
  String _cachedSdkPath = '';

  IconRenderer(this.workingDir, this.config);

  Future<void> render() async {
    Logger.step('Initialisation du moteur de rendu');

    final rendererDir = Directory(p.join(workingDir, 'renderer'));
    if (!rendererDir.existsSync()) {
      rendererDir.createSync(recursive: true);
    }

    final flutterSdkPath = await _getFlutterSdkPath();
    final fontSource = p.join(flutterSdkPath, 'bin', 'cache', 'artifacts',
        'material_fonts', 'MaterialIcons-Regular.otf');
    final robotoSource = p.join(flutterSdkPath, 'bin', 'cache', 'artifacts',
        'material_fonts', 'Roboto-Regular.ttf');

    final fontDestDir = Directory(p.join(rendererDir.path, 'assets', 'fonts'));
    if (!fontDestDir.existsSync()) fontDestDir.createSync(recursive: true);

    _copyFont(
        fontSource, p.join(fontDestDir.path, 'MaterialIcons-Regular.otf'));
    _copyFont(robotoSource, p.join(fontDestDir.path, 'Roboto-Regular.ttf'));

    final symbolCode =
        await _getSymbolCode(config.icon.symbol, config.icon.style);

    Logger.step('Préparation du projet de rendu temporaire');
    _prepareRendererProject(rendererDir.path, symbolCode);

    Logger.step('Exécution du rendu Flutter');
    await _runRenderer(rendererDir.path);

    Logger.success('Images de base générées dans build/flutter_launcher');
  }

  void _copyFont(String source, String dest) {
    final file = File(source);
    if (file.existsSync()) {
      Logger.debug('Copie de \${p.basename(source)}...');
      file.copySync(dest);
    } else {
      Logger.warn('Police \${p.basename(source)} introuvable ($source).');
    }
  }

  Future<String> _getFlutterSdkPath() async {
    if (_cachedSdkPath.isNotEmpty) return _cachedSdkPath;
    try {
      final res = await Process.run('which', ['flutter']);
      if (res.exitCode == 0) {
        final flutterBin = res.stdout.toString().trim();
        _cachedSdkPath = p.dirname(p.dirname(flutterBin));
        return _cachedSdkPath;
      }
    } catch (_) {}
    return '';
  }

  void _prepareRendererProject(String path, int symbolCode) {
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
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

    final testDir = Directory(p.join(path, 'test'));
    if (!testDir.existsSync()) testDir.createSync();

    File(p.join(path, 'test', 'render_test.dart'))
        .writeAsStringSync(_generateTestCode(symbolCode));
  }

  String _generateTestCode(int symbolCode) {
    Logger.info('Configuration de l\'icône :');
    Logger.info('  - Symbole : ${config.icon.symbol}');
    Logger.info('  - Style : ${config.icon.style}');
    Logger.info('  - Code résolu : 0x${symbolCode.toRadixString(16)}');

    return '''
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render icons', (WidgetTester tester) async {
    print('[RENDERER] Démarrage du test');
    
    print('[RENDERER] Chargement des polices...');
    try {
      // MaterialIcons
      final iconFont = File('assets/fonts/MaterialIcons-Regular.otf').readAsBytesSync();
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(Future.value(ByteData.view(iconFont.buffer)));
      await iconLoader.load();

      // Roboto (pour le texte)
      final robotoFont = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
      final robotoLoader = FontLoader('Roboto');
      robotoLoader.addFont(Future.value(ByteData.view(robotoFont.buffer)));
      await robotoLoader.load();

      print('[RENDERER] Polices chargées avec succès.');
    } catch (e) {
      print('[RENDERER] ERREUR chargement polices: ' + e.toString());
    }

    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;

    await _renderIcon(
      tester,
      name: 'app_icon_light.png',
      bgColor: _parseColor('${config.theme.light.background ?? "#FFFFFF"}'),
      fgColor: _parseColor('${config.theme.light.primary}'),
      symbolCode: $symbolCode,
      padding: ${config.icon.padding},
    );

    if (${config.splash.enabled}) {
      await _renderIcon(
        tester,
        name: 'splash_light.png',
        bgColor: _parseColor('${config.theme.light.background ?? "#FFFFFF"}'),
        fgColor: _parseColor('${config.theme.light.primary}'),
        symbolCode: $symbolCode,
        padding: ${config.splash.iconPadding},
        branding: ${config.splash.branding != null ? "BrandingConfig(text: r'''${config.splash.branding!.text}''', color: '${config.splash.branding!.color}', fontSize: ${config.splash.branding!.fontSize}, position: '${config.splash.branding!.position}')" : "null"},
      );
    }

    if ('${config.theme.dark?.background ?? ""}'.isNotEmpty) {
      await _renderIcon(
        tester,
        name: 'app_icon_dark.png',
        bgColor: _parseColor('${config.theme.dark?.background ?? "#000000"}'),
        fgColor: _parseColor('${config.theme.dark?.primary ?? "#FFFFFF"}'),
        symbolCode: $symbolCode,
        padding: ${config.icon.padding},
      );

      if (${config.splash.enabled}) {
        await _renderIcon(
          tester,
          name: 'splash_dark.png',
          bgColor: _parseColor('${config.theme.dark?.background ?? "#000000"}'),
          fgColor: _parseColor('${config.theme.dark?.primary ?? "#FFFFFF"}'),
          symbolCode: $symbolCode,
          padding: ${config.splash.iconPadding},
          branding: ${config.splash.branding != null ? "BrandingConfig(text: r'''${config.splash.branding!.text}''', color: '${config.splash.branding!.color}', fontSize: ${config.splash.branding!.fontSize}, position: '${config.splash.branding!.position}')" : "null"},
        );
      }
    }
    print('[RENDERER] Tous les tests terminés.');
  });
}

class BrandingConfig {
  final String text;
  final String color;
  final double fontSize;
  final String position;
  BrandingConfig({required this.text, required this.color, required this.fontSize, required this.position});
}

Future<void> _renderIcon(
  WidgetTester tester, {
  required String name,
  required Color bgColor,
  required Color fgColor,
  required int symbolCode,
  required double padding,
  BrandingConfig? branding,
}) async {
  print('  [RENDERER] Début du rendu de ' + name);
  final key = GlobalKey();
  
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: 1024,
            height: 1024,
            color: bgColor,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (branding != null && branding.position == 'top') ...[
                        Text(
                          branding.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _parseColor(branding.color),
                            fontSize: branding.fontSize * 2.5, // Scale up for 1024x1024
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                      Icon(
                        IconData(symbolCode, fontFamily: 'MaterialIcons'),
                        color: fgColor,
                        size: 1024 * (1.0 - padding * 2),
                        shadows: [
                          if (${config.icon.shadow?.enabled ?? false})
                            Shadow(
                              color: _parseColor('${config.icon.shadow?.color ?? "#000000"}'),
                              blurRadius: ${config.icon.shadow?.blur ?? 10.0},
                              offset: const Offset(
                                ${config.icon.shadow?.offsetX ?? 0.0},
                                ${config.icon.shadow?.offsetY ?? 0.0},
                              ),
                            ),
                        ],
                      ),
                      if (branding != null && branding.position == 'bottom') ...[
                        const SizedBox(height: 60),
                        Text(
                          branding.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _parseColor(branding.color),
                            fontSize: branding.fontSize * 2.5,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  print('  [RENDERER] Attente du rendu (pump)...');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  
  print('  [RENDERER] Récupération du RenderObject...');
  final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  
  print('  [RENDERER] Conversion en image (runAsync)...');
  await tester.runAsync(() async {
    try {
      print('    [STEP] toImage...');
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      
      print('    [STEP] toByteData...');
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('byteData is null');

      print('    [STEP] Encodage PNG avec package:image...');
      final Uint8List rawBytes = byteData.buffer.asUint8List();
      final img.Image? decoded = img.Image.fromBytes(
        width: 1024,
        height: 1024,
        bytes: rawBytes.buffer,
        order: img.ChannelOrder.rgba,
      );
      
      if (decoded == null) throw Exception('Failed to decode raw bytes');
      
      final List<int> pngBytes = img.encodePng(decoded);
      
      print('    [STEP] Écriture du fichier ' + name);
      final file = File('../' + name);
      await file.writeAsBytes(pngBytes);
      print('    [SUCCESS] ' + name + ' généré.');
    } catch (e, stack) {
      print('    [ERROR] Erreur pendant le rendu : ' + e.toString());
      print(stack);
    }
  });
}

Color _parseColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF' + hex;
  return Color(int.parse(hex, radix: 16));
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
    if (exitCode != 0) throw Exception('Rendu échoué avec le code $exitCode.');
  }

  Future<int> _getSymbolCode(String name, String style) async {
    if (name.startsWith('0x')) {
      return int.tryParse(name.substring(2), radix: 16) ?? 0xe8b8;
    }

    final query = name.toLowerCase();
    final styleName = style.toLowerCase();

    try {
      final flutterSdk = await _getFlutterSdkPath();
      if (flutterSdk.isNotEmpty) {
        final codepointsFile = p.join(flutterSdk, 'bin', 'cache', 'artifacts',
            'material_fonts', 'codepoints');
        if (File(codepointsFile).existsSync()) {
          final lines = await File(codepointsFile).readAsLines();

          final candidates = [
            '${query}_$styleName',
            '${query}_baseline',
            query,
          ];

          for (final cand in candidates) {
            for (final line in lines) {
              final parts = line.split(' ');
              if (parts.length == 2 && parts[0] == cand) {
                return int.parse(parts[1], radix: 16);
              }
            }
          }
        }
      }
    } catch (_) {}

    final fallback = {
      'settings': 0xe8b8,
      'home': 0xe88a,
      'search': 0xe8b6,
    };
    return fallback[query] ?? 0xe8b8;
  }
}
