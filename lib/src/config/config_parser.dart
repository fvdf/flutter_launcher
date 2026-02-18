import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'config_model.dart';

class ConfigParser {
  static LauncherConfig parsePubspec(String projectPath) {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found at $projectPath');
    }

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);

    if (yaml == null || yaml['flutter_launcher'] == null) {
      throw Exception('flutter_launcher section missing in pubspec.yaml');
    }

    final config = yaml['flutter_launcher'];

    return LauncherConfig(
      platforms: _parsePlatforms(config['platforms']),
      theme: _parseTheme(config['theme']),
      icon: _parseIcon(config['icon']),
      splash: _parseSplash(config['splash']),
    );
  }

  static Map<String, bool> _parsePlatforms(dynamic yaml) {
    final Map<String, bool> platforms = {
      'android': true,
      'ios': true,
      'web': false,
      'windows': false,
      'macos': false,
      'linux': false,
    };

    if (yaml is YamlMap) {
      yaml.forEach((key, value) {
        if (value is bool) {
          platforms[key.toString()] = value;
        }
      });
    }
    return platforms;
  }

  static ThemeConfig _parseTheme(dynamic yaml) {
    if (yaml == null || yaml['light'] == null) {
      throw Exception('theme.light section is required');
    }

    final light = _parseColorSet(yaml['light']);
    final dark = yaml['dark'] != null ? _parseColorSet(yaml['dark']) : null;

    return ThemeConfig(light: light, dark: dark);
  }

  static ColorSet _parseColorSet(dynamic yaml) {
    if (yaml == null || yaml['primary'] == null) {
      throw Exception('primary color is required');
    }
    final primary = yaml['primary'].toString();
    final background = yaml['background']?.toString();

    _validateHex(primary);
    if (background != null) _validateHex(background);

    return ColorSet(primary: primary, background: background);
  }

  static IconConfig _parseIcon(dynamic yaml) {
    if (yaml == null || yaml['symbol'] == null) {
      throw Exception('icon.symbol is required');
    }

    return IconConfig(
      symbol: yaml['symbol'].toString(),
      style: yaml['style']?.toString() ?? 'outlined',
      fill: yaml['fill'] is int ? yaml['fill'] : 1,
      weight: yaml['weight'] is int ? yaml['weight'] : 700,
      grade: (yaml['grade'] is num ? yaml['grade'] as num : 0.0).toDouble(),
      opticalSize: yaml['opticalSize'] is int ? yaml['opticalSize'] : 48,
      padding:
          (yaml['padding'] is num ? yaml['padding'] as num : 0.18).toDouble(),
      shadow: _parseShadow(yaml['shadow']),
    );
  }

  static ShadowConfig? _parseShadow(dynamic yaml) {
    if (yaml == null) return null;
    if (yaml is! YamlMap) return null;

    final enabled = yaml['enabled'] is bool ? yaml['enabled'] : false;
    if (!enabled) return null;

    final color = yaml['color']?.toString() ?? '#000000';
    _validateHex(color);

    return ShadowConfig(
      enabled: true,
      color: color,
      blur: (yaml['blur'] is num ? yaml['blur'] as num : 10.0).toDouble(),
      offsetX:
          (yaml['offset_x'] is num ? yaml['offset_x'] as num : 0.0).toDouble(),
      offsetY:
          (yaml['offset_y'] is num ? yaml['offset_y'] as num : 0.0).toDouble(),
    );
  }

  static SplashConfig _parseSplash(dynamic yaml) {
    if (yaml == null) return SplashConfig();
    return SplashConfig(
      enabled: yaml['enabled'] is bool ? yaml['enabled'] : true,
      android12: yaml['android12'] is bool ? yaml['android12'] : true,
      fullscreen: yaml['fullscreen'] is bool ? yaml['fullscreen'] : false,
      iconPadding:
          (yaml['icon_padding'] is num ? yaml['icon_padding'] as num : 0.35)
              .toDouble(),
      branding: _parseBranding(yaml['branding']),
    );
  }

  static BrandingConfig? _parseBranding(dynamic yaml) {
    if (yaml == null || yaml['text'] == null) return null;

    final text = yaml['text'].toString();
    final color = yaml['color']?.toString() ?? '#FFFFFF';
    _validateHex(color);

    return BrandingConfig(
      text: text,
      color: color,
      fontSize: (yaml['font_size'] is num ? yaml['font_size'] as num : 24.0)
          .toDouble(),
      position: yaml['position']?.toString() ?? 'bottom',
      fontFamily: yaml['font_family']?.toString(),
    );
  }

  static void _validateHex(String hex) {
    final regExp = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})$');
    if (!regExp.hasMatch(hex)) {
      throw Exception('Invalid color hex code: $hex');
    }
  }
}
