import Foundation

// MARK: - App State

enum AppState: Equatable {
    case onboarding(OnboardingStep)
    case idle
    case running
    case review
    case settings
}

enum OnboardingStep: Hashable {
    case email
    case auth
}

// MARK: - AppViewModel

@Observable
final class AppViewModel {

    // MARK: State

    var state: AppState = .onboarding(.email)
    var session         = Session()
    var elapsedSeconds  = 0
    var isLoggingEvent  = false
    var logError: String?
    var logSuccess      = false

    // MARK: Dependencies

    var authManager = AuthManager()
    private let calendarService = CalendarService()
    private var timerTask: Task<Void, Never>?

    /// Set by `AppDelegate` to mirror the live timer into the menu bar.
    /// Passes a compact string while running, `nil` when idle/stopped.
    var onMenuBarUpdate: ((String?) -> Void)?

    /// Hooks for the `AppDelegate` to show / hide the popover.
    var onRequestOpen: (() -> Void)?
    var onRequestClose: (() -> Void)?

    /// Invoked by the close button in the UI.
    func requestClose() { onRequestClose?() }

    // MARK: Init

    init() {
        authManager.loadStoredAuth()
        state = authManager.isAuthenticated ? .idle : .onboarding(.email)
    }

    // MARK: - Onboarding

    func advanceToAuthStep() {
        state = .onboarding(.auth)
    }

    func startGoogleAuth() async {
        await authManager.startOAuthFlow()
        if authManager.isAuthenticated {
            state = .idle
            // Bring the popover forward immediately after auth completes.
            onRequestOpen?()
        }
    }

    // MARK: - Session Lifecycle

    func startSession() {
        session = Session(name: session.name, colorId: session.colorId, startTime: .now)
        elapsedSeconds = 0
        startTimer()
        state = .running
        // Collapse to the menu bar; the live timer keeps ticking there.
        onRequestClose?()
    }

    func stopSession() {
        session.endTime = .now
        stopTimer()
        state = .review
    }

    func discardSession() {
        stopTimer()
        elapsedSeconds = 0
        logError = nil
        logSuccess = false
        state = .idle
    }

    /// True when the review window describes a positive-length session.
    var isSessionRangeValid: Bool {
        session.endTime > session.startTime
    }

    /// Duration of the current session in whole seconds (never negative).
    var sessionDurationSeconds: Int {
        max(0, Int(session.duration))
    }

    func logSession() async {
        guard isSessionRangeValid else {
            logError = "End time must be after start time."
            return
        }
        isLoggingEvent = true
        logError = nil

        do {
            let token = try await authManager.validAccessToken()
            let event = CalendarEvent(
                title:     session.name,
                startTime: session.startTime,
                endTime:   session.endTime,
                colorId:   session.colorId
            )
            _ = try await calendarService.createEvent(event, accessToken: token)
            isLoggingEvent = false

            // Show the success confirmation briefly, then return to idle.
            logSuccess = true
            try? await Task.sleep(for: .milliseconds(1100))
            logSuccess = false
            elapsedSeconds = 0
            state = .idle
        } catch {
            isLoggingEvent = false
            logError = error.localizedDescription
        }
    }

    /// Opens the review panel pre-filled with a 1-hour window ending now,
    /// for manually logging a past event without having run the timer.
    func openManualLog() {
        session = Session(
            name: "Work session",
            colorId: 7,
            startTime: Date(timeIntervalSinceNow: -3600)
        )
        session.endTime = .now
        logError = nil
        logSuccess = false
        state = .review
    }

    // MARK: - Settings

    func showSettings() { state = .settings }
    func dismissSettings() { state = .idle }

    func signOut() {
        stopTimer()
        authManager.signOut()
        state = .onboarding(.email)
    }

    // MARK: - Timer

    var elapsedFormatted: String { elapsedSeconds.asElapsedTime }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let seconds = Int(Date.now.timeIntervalSince(self.session.startTime))
                self.elapsedSeconds = seconds
                self.onMenuBarUpdate?(seconds.asCompactElapsed)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        onMenuBarUpdate?(nil)
    }
}
