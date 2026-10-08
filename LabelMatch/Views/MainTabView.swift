import SwiftUI

/// The tab bar. More tabs are added in later commits.
struct MainTabView: View {
    @StateObject private var goalViewModel: GoalSetupViewModel

    init(environment: AppEnvironment) {
        _goalViewModel = StateObject(wrappedValue: environment.makeGoalSetupViewModel())
    }

    var body: some View {
        TabView {
            GoalSetupView(viewModel: goalViewModel)
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
        }
    }
}
