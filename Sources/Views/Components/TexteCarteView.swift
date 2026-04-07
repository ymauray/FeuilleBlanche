import SwiftUI

struct TexteCarteView: View {
    let texte: Texte

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(texte.titre)
                .font(.headline)

            HStack(spacing: 16) {
                stat("\(texte.chapitres.count)", suffix: texte.chapitres.count == 1 ? "chapitre" : "chapitres")
                stat("\(texte.nombreDeMots)", suffix: texte.nombreDeMots == 1 ? "mot" : "mots")
                stat("\(texte.nombreDeSignes)", suffix: texte.nombreDeSignes == 1 ? "signe" : "signes")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func stat(_ valeur: String, suffix: String) -> some View {
        HStack(spacing: 2) {
            Text(valeur).bold()
            Text(suffix)
        }
    }
}
