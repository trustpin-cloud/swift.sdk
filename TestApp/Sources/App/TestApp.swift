import SwiftUI

@main
struct TestApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
                .accentColor(Color("AccentColor"))
        }
    }
}
