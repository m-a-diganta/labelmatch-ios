import SwiftUI

/// The tab bar that holds the screens.
struct MainTabView: View {
    @StateObject private var goalViewModel: GoalSetupViewModel
    @StateObject private var checkViewModel: LabelCheckViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var compareViewModel: CompareViewModel

    init(environment: AppEnvironment) {
        _goalViewModel = StateObject(wrappedValue: environment.makeGoalSetupViewModel())
        _checkViewModel = StateObject(wrappedValue: environment.makeLabelCheckViewModel())
        _historyViewModel = StateObject(wrappedValue: environment.makeHistoryViewModel())
        _compareViewModel = StateObject(wrappedValue: environment.makeCompareViewModel())
    }

    var body: some View {
        TabView {
            LabelCheckFlowView(viewModel: checkViewModel)
                .tabItem {
                    Label("Check", systemImage: "camera.viewfinder")
                }

            CompareView(viewModel: compareViewModel)
                .tabItem {
                    Label("Compare", systemImage: "arrow.left.arrow.right")
                }

            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Label("History", systemImage: "clock")
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
