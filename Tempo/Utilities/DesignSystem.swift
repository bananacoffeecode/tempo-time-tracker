import SwiftUI

// MARK: - Metrics

enum Metrics {
    static let panelWidth: CGFloat = 320
    static let panelHeight: CGFloat = 420
    static let corner: CGFloat = 10
    static let cardCorner: CGFloat = 14
}

// MARK: - Animations

extension Animation {
    /// Primary spring for view changes and layout.
    static let tempoSpring = Animation.spring(response: 0.42, dampingFraction: 0.82)
    /// Snappy spring for taps and small state flips.
    static let tempoSnappy = Animation.snappy(duration: 0.26, extraBounce: 0.06)
    /// Gentle fade for hover / secondary changes.
    static let tempoGentle = Animation.easeInOut(duration: 0.18)
}

// MARK: - Transitions

extension AnyTransition {
    /// A soft push used when moving between top-level panels.
    static var panelPush: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)).combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity.combined(with: .offset(y: -8)).combined(with: .scale(scale: 0.98, anchor: .top))
        )
    }
}

// MARK: - Primary Button

struct TempoPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, tint: tint)
    }

    private struct StyleBody: View {
        let configuration: Configuration
        let tint: Color
        @Environment(\.isEnabled) private var isEnabled
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                        .fill(tint.gradient)
                        .brightness(configuration.isPressed ? -0.06 : (hovering ? 0.05 : 0))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                }
                .shadow(color: tint.opacity(isEnabled ? 0.32 : 0),
                        radius: configuration.isPressed ? 2 : 7,
                        y: configuration.isPressed ? 1 : 3)
                .opacity(isEnabled ? 1 : 0.45)
                .saturation(isEnabled ? 1 : 0.6)
                .scaleEffect(configuration.isPressed ? 0.975 : 1)
                .contentShape(RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous))
                .onHover { hovering = $0 }
                .animation(.tempoSnappy, value: configuration.isPressed)
                .animation(.tempoGentle, value: hovering)
        }
    }
}

// MARK: - Link / Text Button

struct TempoLinkButtonStyle: ButtonStyle {
    var color: Color = .secondary

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, color: color)
    }

    private struct StyleBody: View {
        let configuration: Configuration
        let color: Color
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.footnote.weight(.medium))
                .foregroundStyle(color)
                .opacity(configuration.isPressed ? 0.5 : (hovering ? 0.85 : 1))
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
                .animation(.tempoGentle, value: hovering)
                .animation(.tempoSnappy, value: configuration.isPressed)
        }
    }
}

// MARK: - Icon Button (toolbar)

struct TempoIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration)
    }

    private struct StyleBody: View {
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(hovering ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.primary.opacity(hovering ? 0.08 : 0))
                }
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
                .animation(.tempoGentle, value: hovering)
                .animation(.tempoSnappy, value: configuration.isPressed)
        }
    }
}

// MARK: - Close Button

/// Top-right close control shared by every panel's toolbar.
struct PanelCloseButton: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        Button {
            viewModel.requestClose()
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(TempoIconButtonStyle())
        .help("Close")
    }
}

// MARK: - Recording Pulse

/// A live, softly pulsing dot used to signal an active session.
struct RecordingPulse: View {
    var color: Color = .red

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .phaseAnimator([false, true]) { dot, expanded in
                dot
                    .scaleEffect(expanded ? 1.0 : 0.7)
                    .opacity(expanded ? 1.0 : 0.45)
                    .shadow(color: color.opacity(expanded ? 0.7 : 0), radius: expanded ? 4 : 0)
            } animation: { _ in .easeInOut(duration: 0.9) }
    }
}

// MARK: - Breathing Ring

/// A continuously rotating, gently breathing gradient ring drawn around the
/// running timer. Driven by `TimelineView(.animation)` for frame-smooth motion.
struct BreathingRing: View {
    var color: Color

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathe = 0.5 + 0.5 * sin(t * 1.5)          // 0…1
            let scale = 1.0 + 0.035 * breathe
            let rotation = Angle(degrees: (t * 26).truncatingRemainder(dividingBy: 360))

            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 5)

                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0), color.opacity(0.5), color, color.opacity(0)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(rotation)
            }
            .scaleEffect(scale)
            .shadow(color: color.opacity(0.20 + 0.25 * breathe), radius: 10)
        }
    }
}
