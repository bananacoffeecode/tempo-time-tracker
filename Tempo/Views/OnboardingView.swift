import SwiftUI

struct OnboardingView: View {
    @Environment(AppViewModel.self) var viewModel

    private var step: OnboardingStep {
        if case let .onboarding(step) = viewModel.state { return step }
        return .email
    }

    private var isEmailValid: Bool {
        let email = viewModel.authManager.userEmail.trimmingCharacters(in: .whitespaces)
        return email.contains("@")
            && email.contains(".")
            && !email.hasSuffix("@")
            && !email.hasSuffix(".")
            && email.count >= 5
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.6)

            Group {
                switch step {
                case .email: emailStep.transition(.panelPush)
                case .auth:  authStep.transition(.panelPush)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.tempoSpring, value: step)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Tempo")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            stepDots
            PanelCloseButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach([OnboardingStep.email, .auth], id: \.self) { dot in
                Capsule()
                    .fill(dot == step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: dot == step ? 16 : 6, height: 6)
            }
        }
        .animation(.tempoSpring, value: step)
    }

    // MARK: - Step 1: Email

    @MainActor
    private var emailStep: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 22) {
            iconBadge("envelope.fill")

            VStack(spacing: 8) {
                Text("Welcome to Tempo")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Track work sessions and log them directly to Google Calendar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Your email")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("name@example.com", text: $viewModel.authManager.userEmail)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .onSubmit { if isEmailValid { viewModel.advanceToAuthStep() } }
            }

            Button {
                viewModel.advanceToAuthStep()
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .labelStyle(.titleOnly)
            }
            .buttonStyle(TempoPrimaryButtonStyle())
            .disabled(!isEmailValid)
        }
        .padding(24)
    }

    // MARK: - Step 2: Google Auth

    private var authStep: some View {
        VStack(spacing: 22) {
            iconBadge("calendar")

            VStack(spacing: 8) {
                Text("Connect Google Calendar")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Tempo needs permission to create events in your calendar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = viewModel.authManager.error {
                ErrorBanner(text: error)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }

            VStack(spacing: 10) {
                Button {
                    Task { await viewModel.startGoogleAuth() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.authManager.isLoading {
                            ProgressView().controlSize(.small).tint(.white)
                        }
                        Text(viewModel.authManager.isLoading ? "Authorizing…" : "Authorize with Google")
                    }
                }
                .buttonStyle(TempoPrimaryButtonStyle())
                .disabled(viewModel.authManager.isLoading)

                Button("Back") {
                    viewModel.state = .onboarding(.email)
                }
                .buttonStyle(TempoLinkButtonStyle())
                .disabled(viewModel.authManager.isLoading)
            }
        }
        .padding(24)
        .animation(.tempoSpring, value: viewModel.authManager.error)
    }

    // MARK: - Pieces

    private func iconBadge(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(.tint)
            .frame(width: 56, height: 56)
            .background {
                Circle().fill(.tint.opacity(0.12))
            }
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.orange.opacity(0.12))
        }
    }
}
