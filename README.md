# Flutter Launcher

Une solution tout-en-un pour générer les icônes et splash screens de votre application Flutter à partir d'une configuration unique dans le `pubspec.yaml`.

## Caractéristiques

- 🚀 **Commande unique** : `dart run flutter_launcher`
- 🎨 **Rendu automatique** : Génère des icônes à partir de Material Symbols (via Flutter rendering).
- 📱 **Multi-plateformes** : Supporte Android, iOS, Web, Windows, macOS et Linux.
- 🌓 **Support Dark Mode** : Génère automatiquement des assets pour le mode sombre.
- 💦 **Splash Screens** : Intégration transparente avec `flutter_native_splash`.

## Installation

Ajoutez le package à vos `dev_dependencies` :

```yaml
dev_dependencies:
  flutter_launcher: ^0.1.0
```

## Configuration

### Exemple Complet

```yaml
flutter_launcher:
  # Plateformes cibles (true/false)
  platforms:
    android: true
    ios: true
    web: true
    macos: true

  # Thème de l'application
  theme:
    light:
      primary: "#FFFFFF"   # Couleur de l'icône (Foreground)
      background: "#E91E63" # Couleur de fond (Background)
    dark:
      primary: "#E1E1E1"
      background: "#AD1457"

  # Configuration de l'icône (Material Symbol)
  icon:
    symbol: "search"       # Nom ou code hexa (0xe8b6)
    style: "outlined"      # baseline, outlined, rounded, sharp
    padding: 0.18          # Espace (0.0 à 0.5)
    fill: 1
    weight: 700
    grade: 0.0
    optical_size: 48
    # Ombre sur l'icône :
    shadow:
      enabled: true        # Activer l'ombre
      color: "#000000"     # Couleur avec opacité possible (ex: #80000000)
      blur: 20.0           # Rayon de flou
      offset_x: 5.0        # Décalage horizontal
      offset_y: 5.0        # Décalage vertical

  # Splash Screen
  splash:
    enabled: true
    android12: true
    fullscreen: false
    icon_padding: 0.35      # Padding de l'icône sur le Splash (plus grand = icône plus petite)
    branding:
      text: "Ma Super App\nBy Rudy" # Texte sur 1 ou 2 lignes
      color: "#FFFFFF"     # Couleur du texte
      font_size: 24.0      # Taille de la police
      position: "bottom"   # top ou bottom
```

## Utilisation

Exécutez la commande suivante à la racine de votre projet :

```bash
dart run flutter_launcher
```

### Options CLI

- `--clean` : Supprime les fichiers temporaires dans `build/flutter_launcher` avant de commencer.
- `--verbose` : Affiche les logs détaillés des outils sous-jacents.
- `--dry-run` : Simule l'exécution sans modifier les fichiers du projet.

## Comment ça marche ?

1. **Parsing** : Le tool lit votre `pubspec.yaml` et valide la configuration.
2. **Rendering** : Il crée un projet Flutter temporaire pour rendre l'icône choisie (Material Symbol) en haute résolution (1024x1024) via le moteur de rendu de Flutter (`dart:ui`).
3. **Icons** : Il utilise `flutter_launcher_icons` pour générer toutes les tailles d'icônes pour chaque plateforme.
4. **Splash** : Il utilise `flutter_native_splash` pour intégrer l'écran de démarrage.

## Limitations

- **Dark Icons** : Le switch automatique de l'icône d'application en fonction du thème système n'est pas supporté nativement par toutes les plateformes (ex: iOS limite cela). Les assets sont générés, mais l'intégration dépend des capacités de l'OS.
- **Symboles** : Pour le moment, une liste restreinte de symboles est supportée par défaut. Vous pouvez étendre le mapping dans `lib/src/generators/icon_renderer/icon_renderer.dart`.

## Licence

MIT - Rudy Dubos
