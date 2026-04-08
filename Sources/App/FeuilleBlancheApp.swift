import SwiftUI

@main
struct FeuilleBlancheApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            TexteListView()
                .environment(store)
                .statusBarHidden(true)
        }
    }
}
