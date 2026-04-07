import Foundation

enum Route: Hashable {
    case chapitres(UUID)
    case editeur(texteID: UUID, chapitreID: UUID)
}
