Plan d'action — Portage Android de Feuille blanche
====================================================

Ce document sert de feuille de route pour porter l'application iOS native
« Feuille blanche » vers Android natif (Kotlin + Jetpack Compose). Il est
écrit pour être repris à froid par une instance Claude qui n'a pas le
contexte de la conversation d'origine — tout ce qui est nécessaire pour
comprendre le projet source et démarrer le travail est ici ou référencé.

Lire d'abord, dans ce dépôt :
- `SPECS.md` — fonctionnalités de l'app iOS, à reproduire à l'identique côté UX
- `ARCHITECTURE.md` — structure du code iOS, détail technique de chaque couche
- `PORTAGE_ANDROID.md` — outils à installer sur Mac (Android Studio, JDK,
  émulateur, options de test sur device réel)
- `CLAUDE.md` — conventions de travail sur le projet iOS (peuvent inspirer
  les conventions du projet Android, voir §Décisions à trancher)


Décisions tranchées
-----------------------------------------

Ces points ont été validés avec l'utilisateur/le client — ne pas revenir
dessus sans raison nouvelle et explicite.

1. **Remplacement d'iCloud → stockage local uniquement** (`Context.filesDir`),
   pas de sync multi-appareils dans un premier temps. Le Lot 5 (sync cloud,
   plus bas) est donc **hors scope pour l'instant** ; ne pas l'implémenter
   sans nouvelle demande explicite du client.

2. **`minSdk` = 26** (Android 8) — nécessaire pour la justification de texte
   native (`LineBreaker.JUSTIFICATION_MODE_INTER_WORD`, cf. Lot 3).
   `targetSdk`/`compileSdk` = dernière version stable au moment du build.

3. **Nom de package : `ch.yannickmauray.feuilleblanche`** — équivalent du
   bundle ID iOS `ch.yannickmauray.feuille-blanche` (Android n'accepte pas
   les tirets dans les noms de package).

4. **Conventions de code : reprise des conventions iOS**, adaptées à Kotlin.
   Voir `CLAUDE.md` (iOS) pour la référence :
   - Noms de variables/fonctions/commentaires en français.
   - Pas de force-unwrap : en Kotlin, éviter `!!`, préférer `?.`,
     `requireNotNull`, ou une valeur par défaut (équivalent du refus de `!`
     en Swift).
   - Commits en français, Conventional Commits (`feat:`, `fix:`, `docs:`,
     `refactor:`, `chore:`, `test:`).
   - **Action à faire en Lot 0** : écrire un `CLAUDE.md` dans le projet
     Android reprenant ces conventions, adapté au workflow Gradle (pas de
     xcodegen à relancer, mais probablement `./gradlew build`/`test` à
     lancer après modification, cf. `PORTAGE_ANDROID.md`).


Correspondance iOS → Android (vue d'ensemble)
------------------------------------------------

| Couche iOS | Fichier(s) source | Équivalent Android | Difficulté |
|---|---|---|---|
| Modèles (`Texte`, `Chapitre`) | `Sources/Models/*.swift` | `data class` Kotlin, `kotlinx.serialization` pour le JSON | Simple |
| Navigation (`Route` enum) | `Sources/Navigation/Route.swift` | `sealed class`/`sealed interface` + Navigation Compose | Simple |
| Store (CRUD + persistance) | `Sources/Store/Store.swift` | `ViewModel` + `StateFlow`, persistance JSON locale (pas de sync cloud, cf. décisions tranchées) | Simple |
| Liste des textes | `Sources/Views/TexteListView.swift`, `TexteCarteView.swift` | `LazyColumn` + `Card`, `SwipeToDismissBox` (Material 3) pour swipe gauche/droite | Simple |
| Liste des chapitres | `Sources/Views/ChapitreListView.swift` | Identique au-dessus | Simple |
| Partage | `Sources/Views/Components/PartageSheet.swift` | `Intent.ACTION_SEND` + `Intent.createChooser` | Simple |
| Éditeur plein écran | `Sources/Views/EditeurView.swift` + `EditeurTextView`/`EditeurContainerView`/`TextEditeurRepresentable` (décrits dans `ARCHITECTURE.md`) | `BasicTextField` (Compose) ou `AndroidView` enrobant un `EditText` custom | **Complexe — voir Lot 3** |
| Icône | `generate_icon.swift` (CoreGraphics) | Regénérer en adaptive icon Android (foreground/background layers), ou reprendre le PNG existant comme base et l'adapter au format Android (legacy + adaptive + monochrome pour Android 13+) | Simple à moyen |
| Tests (`FeuilleBlancheTests.swift`) | Swift Testing | JUnit 5 / Kotlin test pour la logique, tests instrumentés (Compose UI testing) pour l'UI | Simple pour la logique, moyen pour l'UI |
| CI (`.github/workflows/ios.yml`) | xcodegen + xcodebuild | Gradle + action `reactivecircus/android-emulator-runner` si tests instrumentés en CI | Simple |


Plan par lots
----------------

### Lot 0 — Setup du projet
- Installer les outils listés dans `PORTAGE_ANDROID.md` (Android Studio,
  JDK 17 + `JAVA_HOME`, AVD Pixel 8 + Pixel Tablet en ARM64).
- Créer le projet Android Studio : Kotlin + Jetpack Compose,
  `minSdk = 26`, package `ch.yannickmauray.feuilleblanche`.
- Écrire le `CLAUDE.md` du projet Android (conventions reprises de l'iOS,
  cf. décision 4 ci-dessus).
- Mettre en place la structure de dossiers en miroir du projet iOS
  (`models/`, `store/`, `navigation/`, `ui/`) pour garder la navigation entre
  les deux bases de code intuitive.
- Initialiser le dépôt git, premier commit de squelette.

### Lot 1 — Couche données (sans sync cloud)
- Porter `Texte` et `Chapitre` en `data class` Kotlin, avec les propriétés
  calculées (`nombreDeMots`, `nombreDeSignes`) — logique de comptage
  directement transposable depuis `Chapitre.swift`/`Texte.swift`.
- Implémenter le `Store` équivalent : persistance JSON locale
  (`Context.filesDir/textes.json`), CRUD complet, sauvegarde après chaque
  mutation. Reproduire la logique de `estPret` (état de chargement initial).
- Tests unitaires équivalents à `ChapitreTests`/`TexteTests`/`StoreTests` —
  mêmes cas limites (chapitre vide, espaces multiples, retours à la ligne).

### Lot 2 — Navigation et écrans liste
- `sealed class Route` (équivalent de l'enum Swift), Navigation Compose.
- `TexteListView` → écran liste des textes (carte : titre, nb chapitres,
  nb mots, nb signes), ajout via dialogue de saisie, swipe pour
  renommer/partager/supprimer, pull-to-refresh (pas de sync cloud pour
  l'instant : simple rechargement depuis le stockage local, ou suppression
  pure et simple du pull-to-refresh puisqu'il n'a plus d'utilité sans sync).
- `ChapitreListView` → même logique, niveau chapitre.
- Reproduire les confirmations de suppression (`AlertDialog`).

### Lot 3 — Éditeur (le plus gros morceau)
C'est la partie qui ne se « traduit » pas — elle doit être repensée avec les
idiomes Android. Détail des exigences (voir `SPECS.md` §Éditeur de texte et
`ARCHITECTURE.md` §Éditeur pour le comportement exact attendu) :
- Plein écran, sans barre de navigation ni décoration.
- Typographie : police serif, 18pt, **justifiée**, indentation première
  ligne de paragraphe (24pt), espacement inter-paragraphe (8pt).
  → Pas de support natif de la justification dans `BasicTextField`
    (Compose) à ce jour. Deux pistes :
    a) `AndroidView` enrobant un `EditText` classique configuré avec
       `justificationMode = LineBreaker.JUSTIFICATION_MODE_INTER_WORD`
       (API 26+) — le plus proche du comportement iOS actuel.
    b) Attendre/vérifier le support Compose au moment de l'implémentation
       (l'API évolue) et réévaluer.
  → Recommandation : partir sur (a), qui reproduit le plus fidèlement
    l'approche iOS (UITextView custom).
- Marges calculées depuis les insets système (`WindowInsets`), minimum 24dp
  sur chaque côté — équivalent de `safeAreaInsets` + `max(inset, 24)` côté iOS.
- Clavier : `imePadding()` / écoute de `WindowInsets.ime` pour garder le
  contenu visible au-dessus du clavier virtuel.
- Focus + clavier automatique à l'ouverture d'un chapitre.
- Geste de retour : swipe gauche→droite n'importe où sur l'écran → sauvegarde
  puis retour à la liste des chapitres (`GestureDetector`/`pointerInput` +
  détection de swipe horizontal, équivalent du `UISwipeGestureRecognizer`).
- Sauvegarde : au swipe retour, toutes les 60s (coroutine + `delay`), au
  passage en arrière-plan (`ON_STOP` du lifecycle).
- Masquer la status bar sur toute l'app (`WindowInsetsControllerCompat`,
  équivalent de `.statusBarHidden(true)`).

### Lot 4 — Partage
- `Intent.ACTION_SEND` (type `text/plain`) + `Intent.createChooser`.
- Reproduire le format d'export texte brut décrit dans `ARCHITECTURE.md`
  §Partage (titre + séparateurs `===`/`---` pour un texte complet, format
  court pour un chapitre seul).

### Lot 5 — Synchronisation cloud (hors scope actuel)
- **Non planifié** : la décision tranchée est le stockage local uniquement,
  pas de sync multi-appareils. Ce lot n'existe que comme référence si le
  client demande cette fonctionnalité plus tard.
- Si un jour demandé (ex. Google Drive API) : gérer l'auth (Google Sign-In),
  l'upload/download du fichier JSON dans l'App Data folder, la logique de
  migration premier lancement (équivalent de `configurerICloud()` dans
  `Store.swift`). Ne pas l'entamer sans nouvelle demande explicite.

### Lot 6 — Icône et assets
- Adapter `AppIcon.png` (1024×1024, déjà versionné dans
  `Sources/Assets.xcassets/AppIcon.appiconset/`) au format adaptive icon
  Android (foreground + background séparés, plus variante monochrome pour
  Android 13+ themed icons).

### Lot 7 — CI
- Workflow GitHub Actions équivalent à `.github/workflows/ios.yml` : build
  Gradle + tests unitaires à chaque push/PR sur `main`. Ajouter les tests
  instrumentés (émulateur en CI) seulement si le temps de build CI le
  justifie — sinon les garder en local uniquement.

### Lot 8 — Validation finale
- Repasser sur chaque écran avec la checklist `SPECS.md` point par point.
- Tester sur l'émulateur ARM64 (Pixel 8 + Pixel Tablet, cf.
  `PORTAGE_ANDROID.md`) puis, si doute sur le clavier/la frappe, sur
  Firebase Test Lab ou BrowserStack avant toute release.


Notes pour la prochaine instance Claude
-------------------------------------------

- Ne pas commencer le Lot 3 (éditeur) sans avoir lu en détail la section
  « Éditeur » de `ARCHITECTURE.md` — le comportement UIKit y est décrit
  précisément (marges, clavier, focus, geste) et sert de spec de référence,
  `SPECS.md` donne la vue fonctionnelle utilisateur.
- Ne pas implémenter le Lot 5 (sync cloud) : hors scope tant que
  l'utilisateur n'en fait pas la demande explicite.
- Conventions Android déjà tranchées (français, pas de `!!`, Conventional
  Commits en français) — les appliquer dès le Lot 0, ne pas re-proposer
  d'alternative.
- Ce plan suppose Jetpack Compose (approche déclarative, la plus proche de
  SwiftUI conceptuellement). Ne pas basculer vers les Views/XML classiques
  sans raison explicite — ce serait un aller-retour inutile.
