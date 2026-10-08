import SwiftUI

@main
struct LabelMatchApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            MainTabView(environment: environment)
        }
    }
}
