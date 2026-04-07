Feuille blanche
===============

Application iOS d'écriture sans distraction.


Écran principal — liste des textes
-----------------------------------

1. L'écran principal présente une liste des textes disponibles sous forme de carte :
    - Titre
    - Nombre de chapitres
    - Nombre de mots
    - Nombre de signes (espaces comprises)

2. Gestion de la liste :
    - Appui sur « + » : ajouter un nouveau texte (saisie du titre via une alerte)
    - Swipe gauche : Renommer (alerte) / Partager (voir §Partage)
    - Swipe droit : Supprimer (avec confirmation)

3. Un appui sur une carte ouvre la liste des chapitres.


Écran chapitres
---------------

4. Liste des chapitres d'un texte, avec pour chaque chapitre :
    - Titre
    - Nombre de mots
    - Nombre de signes

5. Gestion de la liste :
    - Appui sur « + » : ajouter un nouveau chapitre (saisie du titre via une alerte)
    - Swipe gauche : Renommer (alerte) / Partager (voir §Partage)
    - Swipe droit : Supprimer (avec confirmation)

6. Un appui sur un chapitre ouvre l'éditeur de texte.


Éditeur de texte
----------------

7. Plein écran, sans aucune décoration ni menu. La barre de statut (heure, signal, batterie)
   est masquée. Seul le curseur clignotant est visible.

8. Typographie :
    - Police : New York (serif Apple, taille 18pt)
    - Alignement : justifié
    - Indentation de la première ligne de chaque paragraphe : 24pt
    - Espace entre les paragraphes : 8pt

9. Marges : calculées automatiquement à partir des safe area insets de l'appareil
   (Dynamic Island, encoche, iPhone avec bouton home), avec un minimum de 24pt sur
   chaque côté. S'adaptent à la rotation de l'écran.

10. Le clavier et le focus apparaissent automatiquement à l'ouverture d'un chapitre.

11. Gestion native de la sélection : déplacer le curseur, sélectionner un mot,
    étendre la sélection, copier, coller, etc.

12. Navigation retour : un double-tap dans la marge gauche ou droite revient
    à la liste des chapitres.

13. Les modifications sont enregistrées en temps réel.


Partage
-------

14. Le contenu peut être partagé via l'interface système (mail, Telegram, WhatsApp, etc.)
    à deux niveaux :
    - Au niveau du texte (swipe gauche sur une carte) : exporte tous les chapitres
      avec titres, séparateurs et contenu.
    - Au niveau du chapitre (swipe gauche sur un chapitre) : exporte le chapitre seul.
    - Le contenu est exporté en texte brut.


Persistance
-----------

15. Les textes sont enregistrés localement dans le bac à sable de l'application
    (Documents/textes.json), en JSON, en texte brut (sans formatage).


Informations techniques
-----------------------

- Plateforme : iOS 26.0 minimum
- Langage : Swift 6, SwiftUI + UIKit (UITextView pour l'éditeur)
- Bundle ID : ch.yannickmauray.feuille-blanche
- Équipe : WFMP87LTRX
- Génération du projet : xcodegen (project.yml)
