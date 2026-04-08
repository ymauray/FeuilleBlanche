# Feuille blanche — Guide pour Claude

## Contexte
Application iOS d'écriture sans distraction. Lire `SPECS.md` pour les fonctionnalités
et `ARCHITECTURE.md` pour la structure du code.

## Workflow obligatoire
- Après toute modification de fichiers Swift ou de `project.yml` :
  relancer `xcodegen generate` pour régénérer `FeuilleBlanche.xcodeproj`.
- Ne jamais modifier `.xcodeproj` à la main.
- Ne jamais committer ni pousser sans demande explicite de l'utilisateur.

## Tests
- Les tests unitaires se trouvent dans `Tests/FeuilleBlancheTests.swift`.
- Les lancer localement : `⌘U` dans Xcode, ou `xcodebuild test` en ligne de commande.
- Vérifier que les tests passent avant de committer.

## Erreurs LSP à ignorer
SourceKit analyse les fichiers Swift isolément, hors contexte projet. Les erreurs
du type "Cannot find type X in scope", "No such module UIKit" ou "No such module Testing"
sont des faux positifs systématiques — elles disparaissent à la compilation dans Xcode.

## Commits
Messages en français, norme Conventional Commits : `type: description` (ex: `feat:`,
`fix:`, `docs:`, `refactor:`, `chore:`, `test:`).

## Conventions
- Noms de variables, fonctions et commentaires en français.
- Pas de `!` (force unwrap) — utiliser `guard`, `if let` ou `??`.
- Pas de formatage riche dans l'éditeur : le contenu est et reste du texte brut.
- Toute mutation des données passe par le `Store`, jamais directement dans les vues.
