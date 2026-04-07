Architecture — Feuille blanche
==============================

Structure des fichiers
----------------------

```
generate_icon.swift                   Script de génération de l'icône (CoreGraphics)
project.yml                           Configuration xcodegen
Sources/
├── Assets.xcassets/                  Asset catalog (icône)
├── App/
│   └── FeuilleBlancheApp.swift       Point d'entrée (@main), injection du Store
├── Models/
│   ├── Texte.swift                   Modèle texte (titre, chapitres, stats calculées)
│   └── Chapitre.swift                Modèle chapitre (titre, contenu, stats calculées)
├── Navigation/
│   └── Route.swift                   Enum de navigation (chapitres / editeur)
├── Store/
│   └── Store.swift                   Source de vérité unique, persistance JSON
└── Views/
    ├── TexteListView.swift            Écran principal — liste des textes
    ├── ChapitreListView.swift         Liste des chapitres d'un texte
    ├── EditeurView.swift              Éditeur plein écran
    └── Components/
        ├── TexteCarteView.swift       Carte d'un texte (titre + stats)
        └── PartageSheet.swift         Wrapper UIActivityViewController
```


Configuration projet (project.yml)
----------------------------------

Quelques réglages notables au-delà du standard xcodegen :

- `developmentLanguage: fr` — indique à iOS que la langue principale de l'app
  est le français. Sans ça, les menus système fournis par UIKit (couper, copier,
  coller, sélectionner…) apparaissent en anglais même sur un appareil en français.

- `GENERATE_INFOPLIST_FILE: YES` — Info.plist entièrement généré par Xcode à
  partir des build settings, pas de fichier .plist à maintenir manuellement.

- `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` — lie le build setting à
  l'asset catalog pour que Xcode trouve l'icône automatiquement.


Modèles
-------

`Texte` et `Chapitre` sont des structs Swift value types, `Codable` et `Hashable`.
Les statistiques (nombre de mots, nombre de signes) sont des propriétés calculées,
non stockées.

```
Texte
├── id: UUID
├── titre: String
├── chapitres: [Chapitre]
├── nombreDeMots: Int       (calculé — somme des chapitres)
└── nombreDeSignes: Int     (calculé — somme des chapitres)

Chapitre
├── id: UUID
├── titre: String
├── contenu: String         (texte brut)
├── nombreDeMots: Int       (calculé — séparation sur whitespace)
└── nombreDeSignes: Int     (calculé — String.count)
```


Store
-----

Classe `@Observable @MainActor`. Injectée via `@Environment` depuis `FeuilleBlancheApp`
et lue dans les vues avec `@Environment(Store.self)`.

Responsabilités :
- CRUD sur les textes et les chapitres (les mutations passent toutes par le Store)
- Sérialisation/désérialisation JSON dans `Documents/textes.json`
- Sauvegarde systématique après chaque mutation (`.atomic`)

Les vues ne mutent jamais les modèles directement — elles appellent les méthodes
du Store, qui met à jour son tableau `textes` (ce qui déclenche les rafraîchissements
SwiftUI via `@Observable`).


Navigation
----------

Un seul `NavigationStack` dans `TexteListView`, avec un `navigationDestination(for: Route.self)`
qui gère les deux destinations :

```
enum Route: Hashable {
    case chapitres(UUID)                    → ChapitreListView(texteID:)
    case editeur(texteID: UUID,
                 chapitreID: UUID)          → EditeurView(texteID:chapitreID:)
}
```

Les vues enfants poussent des valeurs `Route` via `NavigationLink(value:)`.
L'éditeur masque la navigation bar et intercepte le retour arrière — la navigation
retour se fait par double-tap dans la marge (appel de `dismiss()`).


Éditeur
-------

L'éditeur est composé de trois couches UIKit encapsulées dans SwiftUI :

```
EditeurView (SwiftUI View)
└── TextEditeurRepresentable (UIViewRepresentable)
    └── EditeurContainerView (UIView wrapper)
        └── EditeurTextView (UITextView sous-classe)
```

**EditeurTextView** est la pièce centrale. Elle gère :

- *Marges* : surcharge de `safeAreaInsetsDidChange()` → `actualiserMarges()`.
  Formule : `max(safeAreaInsets.côté, 24)` sur les 4 côtés.
  `contentInsetAdjustmentBehavior = .never` pour éviter le double comptage
  avec les ajustements automatiques de UIScrollView.

- *Typographie* : appliquée via `definirTexte(_:)` qui construit un
  `NSAttributedString` avec un `NSMutableParagraphStyle` (justification,
  indentation première ligne 24pt, espacement paragraphe 8pt) et le pose
  dans `typingAttributes` + `attributedText`. Les nouvelles saisies héritent
  automatiquement du style via `typingAttributes`.

- *Focus* : `becomeFirstResponder()` appelé dans `didMoveToWindow()` (une seule
  fois grâce au drapeau `aDejaFocus`), quand la vue est intégrée dans la fenêtre.

- *Geste de retour* : `UITapGestureRecognizer` (double-tap, `numberOfTapsRequired = 2`).
  `gestureRecognizerShouldBegin` retourne `true` uniquement si le tap se trouve
  dans la marge gauche ou droite (`point.x < textContainerInset.left` ou
  `point.x > bounds.width - textContainerInset.right`). Cela préserve le
  double-tap natif sur le texte (sélection de mot). Reconnaissance simultanée
  autorisée via `UIGestureRecognizerDelegate`.

**EditeurContainerView** est un `UIView` wrapper transparent. Il existe pour
permettre d'ajouter facilement des overlays (debug ou futurs) sans modifier
`EditeurTextView`.

**TextEditeurRepresentable** fait le pont SwiftUI ↔ UIKit :
- `makeUIView` : construit et configure `EditeurContainerView`
- `updateUIView` : synchronise le contenu si modifié depuis l'extérieur
- `Coordinator` : implémente `UITextViewDelegate.textViewDidChange` pour
  remonter les modifications dans le binding SwiftUI `$contenu`

**EditeurView** (SwiftUI) :
- Charge le contenu depuis le Store dans `onAppear`
- Sauvegarde dans le Store à chaque `onChange(of: contenu)`
- Gère `statusBarHidden(true)` et la suppression de la nav bar


Partage
-------

`PartageSheet` est un `UIViewControllerRepresentable` minimaliste qui présente
un `UIActivityViewController`. Il est déclenché :
- Dans `TexteListView` : swipe gauche → partage le texte complet formaté
- Dans `ChapitreListView` : swipe gauche → partage le chapitre seul

Format d'export (texte brut) :
```
Titre du texte — Titre du chapitre

Contenu du chapitre...
```

Pour un texte complet :
```
Titre du texte
==============

Titre chapitre 1
----------------
Contenu...

Titre chapitre 2
----------------
Contenu...
```


Icône
-----

L'icône est générée programmatiquement via `generate_icon.swift` (CoreGraphics/AppKit),
à la racine du projet. Pour la régénérer après modification :

```bash
swift generate_icon.swift
xcodegen generate
```

**Design :** page blanche portrait avec ombre portée sur fond crème, curseur noir
fin en haut à gauche — le seul élément visible dans l'éditeur.

**Paramètres ajustables dans `generate_icon.swift` :**
- `marginH` — largeur des marges horizontales (proportion portrait de la page)
- `marginTop` / `marginBottom` — marges verticales
- Curseur : `width` et `height` dans `cursorRect`
- Couleurs : fond crème `NSColor(red: 0.957, green: 0.941, blue: 0.910)`
- Ombre : offset, blur et opacité dans `ctx.setShadow(...)`

Le PNG généré (`Sources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024×1024)
est versionné dans git. `generate_icon.swift` l'est aussi pour garder la source
de vérité du design.


Points d'extension
------------------

Quelques endroits prévus pour de futures évolutions :

- **Menu contextuel de l'éditeur** : le double-tap dans la marge appelle
  `menuHandler` sur `EditeurTextView`. Il suffit de changer le comportement
  dans `EditeurView` (actuellement : `dismiss()`).

- **Overlays debug** : `EditeurContainerView` est prévu pour accueillir des
  sous-vues non-interactives au-dessus de l'éditeur.

- **Formatage riche** : actuellement en texte brut. Pour supporter gras/italique,
  il faudrait remplacer `contenu: String` par `contenu: Data` (RTF) dans
  `Chapitre`, adapter le Store, et gérer la rétrocompatibilité.

- **Taille de police réglable** : `definirTexte(_:)` dans `EditeurTextView`
  est le seul endroit à modifier. La taille 18pt est codée en dur.
