import Foundation
import Observation

@MainActor
@Observable
final class Store {
    var textes: [Texte] = []

    private var fileURL: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("textes.json")

    init() {
        load()
        Task {
            await configurerICloud()
        }
    }

    // MARK: - iCloud

    private func configurerICloud() async {
        let containerURL = await Task.detached(priority: .userInitiated) {
            FileManager.default.url(
                forUbiquityContainerIdentifier: "iCloud.ch.yannickmauray.feuille-blanche"
            )
        }.value

        guard let containerURL else { return }

        let documentsURL = containerURL.appendingPathComponent("Documents")
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)

        let iCloudURL = documentsURL.appendingPathComponent("textes.json")

        // Migration : si des données locales existent mais pas encore sur iCloud, on les copie
        if !FileManager.default.fileExists(atPath: iCloudURL.path),
           FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.copyItem(at: fileURL, to: iCloudURL)
        }

        fileURL = iCloudURL
        load()
    }

    // MARK: - Persistance

    func recharger() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Texte].self, from: data)
        else { return }
        textes = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(textes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Textes

    func ajouterTexte(titre: String) {
        textes.append(Texte(titre: titre))
        save()
    }

    func supprimerTextes(at offsets: IndexSet) {
        textes.remove(atOffsets: offsets)
        save()
    }

    func renommerTexte(id: UUID, titre: String) {
        guard let i = textes.firstIndex(where: { $0.id == id }) else { return }
        textes[i].titre = titre
        save()
    }

    // MARK: - Chapitres

    func ajouterChapitre(dans texteID: UUID, titre: String) {
        guard let i = textes.firstIndex(where: { $0.id == texteID }) else { return }
        textes[i].chapitres.append(Chapitre(titre: titre))
        save()
    }

    func supprimerChapitres(dans texteID: UUID, at offsets: IndexSet) {
        guard let i = textes.firstIndex(where: { $0.id == texteID }) else { return }
        textes[i].chapitres.remove(atOffsets: offsets)
        save()
    }

    func renommerChapitre(id: UUID, dans texteID: UUID, titre: String) {
        guard let ti = textes.firstIndex(where: { $0.id == texteID }),
              let ci = textes[ti].chapitres.firstIndex(where: { $0.id == id })
        else { return }
        textes[ti].chapitres[ci].titre = titre
        save()
    }

    func mettreAJourContenu(chapitreID: UUID, dans texteID: UUID, contenu: String) {
        guard let ti = textes.firstIndex(where: { $0.id == texteID }),
              let ci = textes[ti].chapitres.firstIndex(where: { $0.id == chapitreID })
        else { return }
        textes[ti].chapitres[ci].contenu = contenu
        save()
    }

    // MARK: - Accesseurs

    func texte(id: UUID) -> Texte? {
        textes.first { $0.id == id }
    }

    func chapitre(id: UUID, dans texteID: UUID) -> Chapitre? {
        textes.first { $0.id == texteID }?.chapitres.first { $0.id == id }
    }
}
