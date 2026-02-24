import SwiftUI

@main
struct MyApp: App {
    @State private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .preferredColorScheme(.light)
        }
    }
}
