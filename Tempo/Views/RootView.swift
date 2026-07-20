import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) var viewModel

    var body: some View {
        content
            .frame(width: Metrics.panelWidth, height: Metrics.panelHeight)
            .animation(.tempoSpring, value: viewModel.state)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .onboarding:
            OnboardingView()
                .transition(.panelPush)
        case .idle, .running:
            TimerView()
                .transition(.panelPush)
        case .review:
            ReviewView()
                .transition(.panelPush)
        case .settings:
            SettingsView()
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}
