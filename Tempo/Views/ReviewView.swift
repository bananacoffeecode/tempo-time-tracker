import SwiftUI

struct ReviewView: View {
    @Environment(AppViewModel.self) var viewModel

    private var accentColor: Color {
        CalendarColor(rawValue: viewModel.session.colorId)?.color ?? .accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.6)
            form
        }
        .overlay {
            if viewModel.logSuccess {
                SuccessOverlay(color: accentColor)
                    .transition(.opacity)
            }
        }
        .animation(.tempoSpring, value: viewModel.logSuccess)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.discardSession()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(TempoIconButtonStyle())
            .disabled(viewModel.isLoggingEvent || viewModel.logSuccess)
            .help("Back")

            Text("Log session")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()

            Text(viewModel.sessionDurationSeconds.asDurationLabel)
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(viewModel.isSessionRangeValid ? .secondary : Color.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule().fill(.secondary.opacity(0.12))
                }
                .contentTransition(.numericText())
                .animation(.tempoSnappy, value: viewModel.sessionDurationSeconds)

            PanelCloseButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Form

    @MainActor
    private var form: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                field(label: "Session name") {
                    TextField("What did you work on?", text: $viewModel.session.name)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    field(label: "Start") {
                        TimePickerView(date: $viewModel.session.startTime)
                    }
                    field(label: "End") {
                        TimePickerView(date: $viewModel.session.endTime)
                    }
                }

                if !viewModel.isSessionRangeValid {
                    ErrorBanner(text: "End time must be after the start time.")
                        .transition(.opacity.combined(with: .offset(y: -4)))
                }

                field(label: "Color") {
                    ColorPickerView(selectedColorId: $viewModel.session.colorId)
                }

                if let error = viewModel.logError {
                    ErrorBanner(text: error)
                        .transition(.opacity.combined(with: .offset(y: -4)))
                }

                VStack(spacing: 10) {
                    Button {
                        Task { await viewModel.logSession() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoggingEvent {
                                ProgressView().controlSize(.small).tint(.white)
                            }
                            Text(viewModel.isLoggingEvent ? "Logging…" : "Log to Calendar")
                        }
                    }
                    .buttonStyle(TempoPrimaryButtonStyle(tint: accentColor))
                    .disabled(viewModel.isLoggingEvent || !viewModel.isSessionRangeValid)

                    Button("Discard") {
                        viewModel.discardSession()
                    }
                    .buttonStyle(TempoLinkButtonStyle(color: .red))
                    .disabled(viewModel.isLoggingEvent)
                }
            }
            .padding(24)
            .animation(.tempoSpring, value: viewModel.isSessionRangeValid)
            .animation(.tempoSpring, value: viewModel.logError)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Success Overlay

struct SuccessOverlay: View {
    let color: Color

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text("Logged to Calendar")
                    .font(.headline)
            }
        }
    }
}
