class LauncherConfig {
  final Map<String, bool> platforms;
  final ThemeConfig theme;
  final IconConfig icon;
  final SplashConfig splash;

  LauncherConfig({
    required this.platforms,
    required this.theme,
    required this.icon,
    required this.splash,
  });
}

class ThemeConfig {
  final ColorSet light;
  final ColorSet? dark;

  ThemeConfig({required this.light, this.dark});
}

class ColorSet {
  final String primary;
  final String? secondary;

  ColorSet({required this.primary, this.secondary});
}

class IconConfig {
  final String symbol;
  final String style;
  final int fill;
  final int weight;
  final double grade;
  final int opticalSize;
  final double padding;

  IconConfig({
    required this.symbol,
    this.style = 'outlined',
    this.fill = 1,
    this.weight = 700,
    this.grade = 0.0,
    this.opticalSize = 48,
    this.padding = 0.18,
  });
}

class SplashConfig {
  final bool enabled;
  final bool android12;
  final bool fullscreen;

  SplashConfig({
    this.enabled = true,
    this.android12 = true,
    this.fullscreen = false,
  });
}
