# Feuille blanche

**Le texte. Rien de plus.**

Application iOS d'écriture sans distraction. Plein écran, aucune décoration, juste votre texte.

---

## Fonctionnalités

- **Éditeur plein écran** — pas de barre d'outils, pas de menus. Le curseur clignotant, et c'est tout.
- **Structure textes / chapitres** — organisez vos écrits en textes et chapitres, consultez le nombre de mots en temps réel.
- **Synchronisation iCloud** — vos textes sont disponibles sur tous vos appareils automatiquement.
- **Partage** — exportez un chapitre ou un texte complet en texte brut via l'interface système (mail, Telegram, WhatsApp…).
- **Typographie soignée** — police New York, justification, indentation de première ligne.

## Prérequis

- iOS / iPadOS 18.0 ou plus récent
- iPhone (toutes tailles) ou iPad (7e génération et plus récent)

## Compiler le projet

```bash
# Installer les dépendances
brew install xcodegen

# Générer le projet Xcode
xcodegen generate

# Ouvrir dans Xcode
open FeuilleBlanche.xcodeproj
```

Les tests se lancent avec `⌘U` dans Xcode, ou en ligne de commande :

```bash
xcodebuild test \
  -project FeuilleBlanche.xcodeproj \
  -scheme FeuilleBlanche \
  -destination "platform=iOS Simulator,name=Any iOS Simulator Device" \
  CODE_SIGNING_ALLOWED=NO
```

## Architecture

Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour une description détaillée de la structure du projet.

## Confidentialité

Feuille blanche ne collecte aucune donnée personnelle. Voir la [politique de confidentialité](https://ymauray.github.io/FeuilleBlanche).

## Auteur

Yannick Mauray — [@ymauray](https://github.com/ymauray)
