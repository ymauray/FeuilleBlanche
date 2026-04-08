import Testing
@testable import FeuilleBlanche

// MARK: - Chapitre

struct ChapitreTests {

    @Test func contenuVide() {
        let chapitre = Chapitre(titre: "Vide")
        #expect(chapitre.nombreDeMots == 0)
        #expect(chapitre.nombreDeSignes == 0)
    }

    @Test func comptageMotsSimple() {
        let chapitre = Chapitre(titre: "Test", contenu: "Bonjour le monde")
        #expect(chapitre.nombreDeMots == 3)
    }

    @Test func comptageMotsEspacesMultiples() {
        let chapitre = Chapitre(titre: "Test", contenu: "Bonjour  le   monde")
        #expect(chapitre.nombreDeMots == 3)
    }

    @Test func comptageMotsRetourLigne() {
        let chapitre = Chapitre(titre: "Test", contenu: "Bonjour\nle monde")
        #expect(chapitre.nombreDeMots == 3)
    }

    @Test func comptageSignesSansEspaces() {
        let chapitre = Chapitre(titre: "Test", contenu: "Bonjour")
        #expect(chapitre.nombreDeSignes == 7)
    }

    @Test func comptageSignesAvecEspaces() {
        let chapitre = Chapitre(titre: "Test", contenu: "Bonjour le monde")
        #expect(chapitre.nombreDeSignes == 16)
    }
}

// MARK: - Texte

struct TexteTests {

    @Test func texteVideSansChapitres() {
        let texte = Texte(titre: "Vide")
        #expect(texte.nombreDeMots == 0)
        #expect(texte.nombreDeSignes == 0)
    }

    @Test func aggregationPlusieursChapitres() {
        var texte = Texte(titre: "Roman")
        texte.chapitres = [
            Chapitre(titre: "Ch. 1", contenu: "Bonjour le monde"),
            Chapitre(titre: "Ch. 2", contenu: "Il fait beau")
        ]
        #expect(texte.nombreDeMots == 6)
        #expect(texte.nombreDeSignes == 29)
    }

    @Test func chapitreVideNInfluencePasLesStats() {
        var texte = Texte(titre: "Roman")
        texte.chapitres = [
            Chapitre(titre: "Ch. 1", contenu: "Bonjour"),
            Chapitre(titre: "Ch. 2", contenu: "")
        ]
        #expect(texte.nombreDeMots == 1)
        #expect(texte.nombreDeSignes == 7)
    }
}

// MARK: - Store

@MainActor
struct StoreTests {

    @Test func ajouterTexte() {
        let store = Store()
        let comptageInitial = store.textes.count
        store.ajouterTexte(titre: "Mon roman")
        #expect(store.textes.count == comptageInitial + 1)
        #expect(store.textes.last?.titre == "Mon roman")
        nettoyerDernier(store)
    }

    @Test func supprimerTexte() {
        let store = Store()
        store.ajouterTexte(titre: "À supprimer")
        let comptageAvant = store.textes.count
        store.supprimerTextes(at: IndexSet([comptageAvant - 1]))
        #expect(store.textes.count == comptageAvant - 1)
    }

    @Test func renommerTexte() {
        let store = Store()
        store.ajouterTexte(titre: "Ancien titre")
        let id = store.textes.last!.id
        store.renommerTexte(id: id, titre: "Nouveau titre")
        #expect(store.texte(id: id)?.titre == "Nouveau titre")
        nettoyerDernier(store)
    }

    @Test func ajouterChapitre() {
        let store = Store()
        store.ajouterTexte(titre: "Texte de test")
        let texteID = store.textes.last!.id
        store.ajouterChapitre(dans: texteID, titre: "Chapitre 1")
        #expect(store.texte(id: texteID)?.chapitres.count == 1)
        #expect(store.texte(id: texteID)?.chapitres.first?.titre == "Chapitre 1")
        nettoyerDernier(store)
    }

    @Test func mettreAJourContenu() {
        let store = Store()
        store.ajouterTexte(titre: "Texte de test")
        let texteID = store.textes.last!.id
        store.ajouterChapitre(dans: texteID, titre: "Chapitre 1")
        let chapitreID = store.texte(id: texteID)!.chapitres.first!.id
        store.mettreAJourContenu(chapitreID: chapitreID, dans: texteID, contenu: "Il était une fois…")
        #expect(store.chapitre(id: chapitreID, dans: texteID)?.contenu == "Il était une fois…")
        nettoyerDernier(store)
    }

    @Test func persistanceJSONAllerRetour() throws {
        let texte = Texte(titre: "Persistance")
        var chapitre = Chapitre(titre: "Ch. 1")
        chapitre.contenu = "Contenu de test"
        var texteAvecChapitre = texte
        texteAvecChapitre.chapitres = [chapitre]

        let data = try JSONEncoder().encode([texteAvecChapitre])
        let decoded = try JSONDecoder().decode([Texte].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded[0].titre == "Persistance")
        #expect(decoded[0].chapitres.first?.contenu == "Contenu de test")
    }

    // Supprime le dernier texte ajouté pour ne pas polluer le fichier de données
    private func nettoyerDernier(_ store: Store) {
        store.supprimerTextes(at: IndexSet([store.textes.count - 1]))
    }
}
