import SwiftUI

/// The tab bar. More tabs are added in later commits.
struct MainTabView: View {
    @StateObject private var goalViewModel: GoalSetupViewModel
    @StateObject private var checkViewModel: LabelCheckViewModel

    init(environment: AppEnvironment) {
        _goalViewModel = StateObject(wrappedValue: environment.makeGoalSetupViewModel())
        _checkViewModel = StateObject(wrappedValue: environment.makeLabelCheckViewModel())
    }

    var body: some View {
        TabView {
            LabelCheckFlowView(viewModel: checkViewModel)
                .tabItem {
                    Label("Check", systemImage: "camera.viewfinder")
                }

            GoalSetupView(viewModel: goalViewModel)
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
        }
    }
}

/// Shows the right screen for the stage of a label check.
private struct LabelCheckFlowView: View {
    @ObservedObject var viewModel: LabelCheckViewModel

    var body: some View {
        NavigationStack {
            switch viewModel.stage {
            case .choosePhoto:
                ImportLabelView(viewModel: viewModel)
            case .review:
                ReviewLabelView(viewModel: viewModel)
            case .verdict:
                VerdictView(viewModel: viewModel)
            }
        }
    }
}
