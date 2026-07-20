import SwiftUI

struct TimerView: View {
    @Environment(AppViewModel.self) var viewModel

    private var isRunning: Bool { viewModel.state == .running }
    private var accentColor: Color {
        CalendarColor(rawValue: viewModel.session.colorId)?.color ?? .accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.6)

            ZStack {
                if isRunning {
                    runningState.transition(.blurReplace)
                } else {
                    idleState.transition(.blurReplace)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .animation(.tempoSpring, value: isRunning)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: isRunning ? "clock.fill" : "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isRunning ? accentColor : .secondary)
                .contentTransition(.symbolEffect(.replace))

            Text("Tempo")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if !isRunning {
                Button {
                    viewModel.showSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(TempoIconButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }

            PanelCloseButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Idle

    private var idleState: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            HeroBadge(symbol: "timer", color: .accentColor)

            VStack(spacing: 6) {
                Text("Ready to track")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Start a session, or log time you've\nalready spent.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                }
                .buttonStyle(TempoPrimaryButtonStyle())

                Button("Log a past event") {
                    viewModel.openManualLog()
                }
                .buttonStyle(TempoLinkButtonStyle())
            }
        }
    }

    // MARK: - Running

    private var runningState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack {
                BreathingRing(color: accentColor)
                    .frame(width: 200, height: 200)

                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        RecordingPulse(color: accentColor)
                        Text("Recording")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    Text(viewModel.elapsedFormatted)
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.3), value: viewModel.elapsedSeconds)
                }
            }

            Spacer(minLength: 0)

            Button {
                viewModel.stopSession()
            } label: {
                Label("Stop Session", systemImage: "stop.fill")
            }
            .buttonStyle(TempoPrimaryButtonStyle(tint: .red))
        }
    }
}

// MARK: - Hero Badge

/// A large rounded app-glyph used as the hero on the idle screen, with a
/// gentle continuous breathing so the screen never feels static.
struct HeroBadge: View {
    let symbol: String
    var color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 30, weight: .medium))
            .foregroundStyle(color.gradient)
            .frame(width: 76, height: 76)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(color.opacity(0.18), lineWidth: 1)
            }
            .phaseAnimator([false, true]) { view, up in
                view.scaleEffect(up ? 1.04 : 1.0)
            } animation: { _ in .easeInOut(duration: 1.8) }
    }
}
