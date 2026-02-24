import SwiftUI

@main
struct MyApp: App {
    @State private var gameState = GameState()
    @State private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(appSettings)
                .preferredColorScheme(.light)
        }
    }
}
