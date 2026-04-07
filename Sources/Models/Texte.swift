import Foundation

struct Texte: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titre: String
    var chapitres: [Chapitre] = []

    var nombreDeMots: Int {
        chapitres.reduce(0) { $0 + $1.nombreDeMots }
    }

    var nombreDeSignes: Int {
        chapitres.reduce(0) { $0 + $1.nombreDeSignes }
    }
}
