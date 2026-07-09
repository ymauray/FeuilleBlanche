Portage Android — Outils à installer sur Mac
=============================================

Ce document liste les outils nécessaires pour développer et tester un portage
Android natif de Feuille blanche depuis un Mac, sans disposer d'un téléphone
Android physique (tests via émulateur / cloud).


IDE et SDK
----------

- **Android Studio** (Meerkat ou plus récent) — IDE officiel, inclut :
  - Le SDK Android (plateformes, build-tools, platform-tools/`adb`)
  - L'émulateur Android (AVD Manager)
  - Kotlin (fourni avec l'IDE, pas d'install séparée)
  - Gradle (via le wrapper `gradlew` de chaque projet, pas d'install globale requise)

  Installation :
  ```bash
  brew install --cask android-studio
  ```

- **JDK 17+** — Android Studio embarque son propre JDK, mais celui-ci n'est
  utilisé que par l'IDE lui-même. **Pour un workflow piloté par un assistant IA
  en ligne de commande** (équivalent de `xcodegen generate` / `xcodebuild test`
  côté iOS), le JDK doit être installé séparément et accessible via `JAVA_HOME`,
  car l'agent appelle `./gradlew build` / `./gradlew test` directement dans le
  shell, sans passer par l'IDE :
  ```fish
  brew install openjdk@17
  set -Ux JAVA_HOME (/usr/libexec/java_home -v 17)
  ```


Émulateur (remplace le téléphone physique)
-------------------------------------------

Sur Apple Silicon, l'émulateur Android tourne nativement en ARM64 (pas
d'émulation x86 par-dessus une émulation ARM) — fluidité proche d'un device
réel, y compris pour tester la frappe clavier et le scroll.

Dans Android Studio → **Device Manager** → créer un AVD :
- Image système : **API 34 ou 35, Google APIs, ARM64**
- Profil : Pixel 8 ou équivalent récent, pour coller à un rendu Material 3 actuel
- Créer aussi un profil tablette (ex. Pixel Tablet) si l'app doit couvrir le
  même usage que l'iPad côté iOS

Points de vigilance spécifiques à ce projet (éditeur custom, clavier, insets) :
- Le comportement clavier/insets sur émulateur est fiable pour le développement,
  mais **certains soucis de clavier virtuel (IME) et de performance de saisie
  ne se reproduisent parfois qu'sur device réel** — cf. section suivante.


Test sur device réel sans posséder de téléphone Android
---------------------------------------------------------

Deux options si un test sur matériel physique s'avère nécessaire (rendu clavier,
performance de frappe, comportement multi-fabricants) :

- **Firebase Test Lab** — exécute l'app sur une flotte de vrais appareils Google
  Cloud, à la demande, facturé à l'usage. Bon choix pour valider ponctuellement
  avant une release.
- **BrowserStack App Live** — accès interactif à distance à de vrais appareils
  Android dans le navigateur, utile pour du test manuel exploratoire.

Aucun des deux ne nécessite d'acheter un appareil ; à réserver aux phases de
validation plutôt qu'au développement quotidien (l'émulateur suffit pour ça).


Ligne de commande / CI
-----------------------

- **Android command-line tools** (`sdkmanager`, `avdmanager`) — inclus dans
  Android Studio, utile si un pipeline CI (GitHub Actions) doit builder et
  tester sans interface graphique, par analogie avec `.github/workflows/ios.yml`
  côté iOS.
- **Gradle** — piloté via le wrapper versionné dans le projet, aucune install
  globale à faire.


Optionnel / à évaluer plus tard
---------------------------------

- **Google Cloud Console** (projet + identifiants OAuth) — uniquement si le
  remplacement de la synchro iCloud passe par Google Drive API (fichier
  d'app data). À mettre en place seulement une fois ce choix arrêté avec le
  client.
- **Genymotion** — émulateur tiers alternatif à celui d'Android Studio,
  utile pour simuler des configurations d'écran variées rapidement.


Résumé installation rapide
-----------------------------

```fish
brew install --cask android-studio
brew install openjdk@17   # requis pour un workflow piloté en CLI par un assistant IA
set -Ux JAVA_HOME (/usr/libexec/java_home -v 17)
```

Puis dans Android Studio : SDK Manager (API 34/35 + build-tools) et Device
Manager (créer un ou deux AVD, téléphone + tablette).
