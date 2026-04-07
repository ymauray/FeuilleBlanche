import Foundation

struct Chapitre: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titre: String
    var contenu: String = ""

    var nombreDeMots: Int {
        contenu.components(separatedBy: .whitespacesAndNewlines)
               .filter { !$0.isEmpty }
               .count
    }

    var nombreDeSignes: Int {
        contenu.count
    }
}
