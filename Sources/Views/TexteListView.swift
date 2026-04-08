import SwiftUI

struct TexteListView: View {
    @Environment(Store.self) private var store
    @State private var showAjouter = false
    @State private var nouveauTitre = ""
    @State private var texteARenommer: Texte?
    @State private var titrePourRenommer = ""
    @State private var texteAPartager: Texte?
    @State private var texteASupprimer: Texte?

    var body: some View {
        NavigationStack {
            if !store.estPret {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
            List {
                ForEach(store.textes) { texte in
                    NavigationLink(value: Route.chapitres(texte.id)) {
                        TexteCarteView(texte: texte)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            texteASupprimer = texte
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            texteARenommer = texte
                            titrePourRenommer = texte.titre
                        } label: {
                            Label("Renommer", systemImage: "pencil")
                        }
                        .tint(.blue)

                        Button {
                            texteAPartager = texte
                        } label: {
                            Label("Partager", systemImage: "square.and.arrow.up")
                        }
                        .tint(.green)
                    }
                }
            }
            .refreshable { store.recharger() }
            .navigationTitle("Feuille blanche")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        nouveauTitre = ""
                        showAjouter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .chapitres(let texteID):
                    ChapitreListView(texteID: texteID)
                case .editeur(let texteID, let chapitreID):
                    EditeurView(texteID: texteID, chapitreID: chapitreID)
                }
            }
            }
        }
        .alert("Nouveau texte", isPresented: $showAjouter) {
            TextField("Titre", text: $nouveauTitre)
            Button("Annuler", role: .cancel) {}
            Button("Créer") {
                let titre = nouveauTitre.trimmingCharacters(in: .whitespaces)
                guard !titre.isEmpty else { return }
                store.ajouterTexte(titre: titre)
            }
        }
        .alert("Renommer", isPresented: Binding(
            get: { texteARenommer != nil },
            set: { if !$0 { texteARenommer = nil } }
        )) {
            TextField("Titre", text: $titrePourRenommer)
            Button("Annuler", role: .cancel) { texteARenommer = nil }
            Button("OK") {
                guard let id = texteARenommer?.id else { return }
                let titre = titrePourRenommer.trimmingCharacters(in: .whitespaces)
                guard !titre.isEmpty else { return }
                store.renommerTexte(id: id, titre: titre)
                texteARenommer = nil
            }
        }
        .alert("Supprimer ce texte ?", isPresented: Binding(
            get: { texteASupprimer != nil },
            set: { if !$0 { texteASupprimer = nil } }
        )) {
            Button("Supprimer", role: .destructive) {
                if let texte = texteASupprimer { supprimer(texte: texte) }
                texteASupprimer = nil
            }
            Button("Annuler", role: .cancel) { texteASupprimer = nil }
        } message: {
            if let titre = texteASupprimer?.titre {
                Text("« \(titre) » et tous ses chapitres seront supprimés définitivement.")
            }
        }
        .sheet(item: $texteAPartager) { texte in
            PartageSheet(elements: [formaterTexte(texte)])
        }
    }

    private func supprimer(texte: Texte) {
        guard let i = store.textes.firstIndex(where: { $0.id == texte.id }) else { return }
        store.supprimerTextes(at: IndexSet([i]))
    }

    private func formaterTexte(_ texte: Texte) -> String {
        var lignes = [texte.titre, String(repeating: "=", count: texte.titre.count), ""]
        for chapitre in texte.chapitres {
            lignes.append(chapitre.titre)
            lignes.append(String(repeating: "-", count: chapitre.titre.count))
            lignes.append(chapitre.contenu)
            lignes.append("")
        }
        return lignes.joined(separator: "\n")
    }
}
