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
  final String? background;

  ColorSet({required this.primary, this.background});
}

class IconConfig {
  final String symbol;
  final String style;
  final int fill;
  final int weight;
  final double grade;
  final int opticalSize;
  final double padding;
  final ShadowConfig? shadow;

  IconConfig({
    required this.symbol,
    this.style = 'outlined',
    this.fill = 1,
    this.weight = 700,
    this.grade = 0.0,
    this.opticalSize = 48,
    this.padding = 0.18,
    this.shadow,
  });
}

class ShadowConfig {
  final bool enabled;
  final String color;
  final double blur;
  final double offsetX;
  final double offsetY;

  ShadowConfig({
    this.enabled = false,
    this.color = '#000000',
    this.blur = 10.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });
}

class SplashConfig {
  final bool enabled;
  final bool android12;
  final bool fullscreen;
  final double iconPadding;
  final BrandingConfig? branding;

  SplashConfig({
    this.enabled = true,
    this.android12 = true,
    this.fullscreen = false,
    this.iconPadding = 0.35,
    this.branding,
  });
}

class BrandingConfig {
  final String text;
  final String color;
  final double fontSize;
  final String position; // 'top' or 'bottom'
  final String? fontFamily;

  BrandingConfig({
    required this.text,
    this.color = '#FFFFFF',
    this.fontSize = 24.0,
    this.position = 'bottom',
    this.fontFamily,
  });
}
