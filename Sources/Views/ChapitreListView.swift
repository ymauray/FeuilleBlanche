import SwiftUI

struct ChapitreListView: View {
    let texteID: UUID

    @Environment(Store.self) private var store
    @State private var showAjouter = false
    @State private var nouveauTitre = ""
    @State private var chapitreARenommer: Chapitre?
    @State private var titrePourRenommer = ""
    @State private var chapitreASupprimer: Chapitre?
    @State private var chapitreAPartager: Chapitre?

    private var texte: Texte? { store.texte(id: texteID) }

    var body: some View {
        Group {
            if let texte {
                List {
                    ForEach(texte.chapitres) { chapitre in
                        NavigationLink(value: Route.editeur(texteID: texteID, chapitreID: chapitre.id)) {
                            ChapitreRowView(chapitre: chapitre)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                chapitreASupprimer = chapitre
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                chapitreARenommer = chapitre
                                titrePourRenommer = chapitre.titre
                            } label: {
                                Label("Renommer", systemImage: "pencil")
                            }
                            .tint(.blue)

                            Button {
                                chapitreAPartager = chapitre
                            } label: {
                                Label("Partager", systemImage: "square.and.arrow.up")
                            }
                            .tint(.green)
                        }
                    }
                }
                .navigationTitle(texte.titre)
            }
        }
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
        .alert("Nouveau chapitre", isPresented: $showAjouter) {
            TextField("Titre", text: $nouveauTitre)
            Button("Annuler", role: .cancel) {}
            Button("Créer") {
                let titre = nouveauTitre.trimmingCharacters(in: .whitespaces)
                guard !titre.isEmpty else { return }
                store.ajouterChapitre(dans: texteID, titre: titre)
            }
        }
        .alert("Renommer", isPresented: Binding(
            get: { chapitreARenommer != nil },
            set: { if !$0 { chapitreARenommer = nil } }
        )) {
            TextField("Titre", text: $titrePourRenommer)
            Button("Annuler", role: .cancel) { chapitreARenommer = nil }
            Button("OK") {
                guard let id = chapitreARenommer?.id else { return }
                let titre = titrePourRenommer.trimmingCharacters(in: .whitespaces)
                guard !titre.isEmpty else { return }
                store.renommerChapitre(id: id, dans: texteID, titre: titre)
                chapitreARenommer = nil
            }
        }
        .alert("Supprimer ce chapitre ?", isPresented: Binding(
            get: { chapitreASupprimer != nil },
            set: { if !$0 { chapitreASupprimer = nil } }
        )) {
            Button("Supprimer", role: .destructive) {
                if let chapitre = chapitreASupprimer, let texte { supprimer(chapitre: chapitre, dans: texte) }
                chapitreASupprimer = nil
            }
            Button("Annuler", role: .cancel) { chapitreASupprimer = nil }
        } message: {
            if let titre = chapitreASupprimer?.titre {
                Text("« \(titre) » et son contenu seront supprimés définitivement.")
            }
        }
        .sheet(item: $chapitreAPartager) { chapitre in
            PartageSheet(elements: [formaterChapitre(chapitre)])
        }
    }

    private func formaterChapitre(_ chapitre: Chapitre) -> String {
        let nomTexte = store.texte(id: texteID)?.titre ?? ""
        return "\(nomTexte) — \(chapitre.titre)\n\n\(chapitre.contenu)"
    }

    private func supprimer(chapitre: Chapitre, dans texte: Texte) {
        guard let i = texte.chapitres.firstIndex(where: { $0.id == chapitre.id }) else { return }
        store.supprimerChapitres(dans: texteID, at: IndexSet([i]))
    }
}

// MARK: - Row

private struct ChapitreRowView: View {
    let chapitre: Chapitre

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(chapitre.titre)
            HStack(spacing: 12) {
                Text("\(chapitre.nombreDeMots) mot\(chapitre.nombreDeMots == 1 ? "" : "s")")
                Text("\(chapitre.nombreDeSignes) signe\(chapitre.nombreDeSignes == 1 ? "" : "s")")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
