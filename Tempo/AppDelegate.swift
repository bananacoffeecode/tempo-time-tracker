import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let viewModel = AppViewModel()

    /// The latest running-timer title, applied to the menu bar only while the
    /// popover is closed (so the button width — and popover anchor — never
    /// shifts as the digits tick while the popover is open).
    private var runningTitle: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()

        // Mirror the live session timer into the menu bar.
        viewModel.onMenuBarUpdate = { [weak self] title in
            if let title {
                self?.updateStatusTitle(title)
            } else {
                self?.clearStatusTitle()
            }
        }
        // Let the view model open / close the popover (auth success, start
        // session, close button).
        viewModel.onRequestOpen = { [weak self] in self?.showPopover() }
        viewModel.onRequestClose = { [weak self] in self?.closePopover() }

        // First run (before the user has connected a calendar): surface the
        // popover automatically so the menu-bar app isn't invisible and the
        // "Welcome to Tempo" screen appears right away.
        if case .onboarding = viewModel.state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.showPopover()
            }
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Persist the icon's position across launches once the user places it.
        statusItem.autosaveName = "TempoStatusItem"
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Tempo")
        button.imagePosition = .imageLeft
        button.action = #selector(togglePopover(_:))
        button.target = self
    }

    func updateStatusTitle(_ title: String) {
        runningTitle = title
        // Don't touch the button while the popover is open — see `runningTitle`.
        guard !popover.isShown else { return }
        applyRunningTitle(title)
    }

    func clearStatusTitle() {
        runningTitle = nil
        statusItem.button?.title = ""
        statusItem.button?.image = NSImage(systemSymbolName: "clock",
                                           accessibilityDescription: "Tempo")
    }

    private func applyRunningTitle(_ title: String) {
        statusItem.button?.title = " \(title)"
        statusItem.button?.image = NSImage(systemSymbolName: "clock.fill",
                                           accessibilityDescription: "Tempo — running")
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: Metrics.panelWidth, height: Metrics.panelHeight)
        // Stays open until explicitly closed (icon, close button, or start).
        popover.behavior = .applicationDefined
        popover.animates = false
        popover.delegate = self

        // Lock the content size so SwiftUI layout never resizes the popover.
        let hosting = NSHostingController(rootView: RootView().environment(viewModel))
        hosting.sizingOptions = []
        popover.contentViewController = hosting
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown { closePopover() } else { showPopover() }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            // Freeze the menu-bar button to an icon-only, fixed width before anchoring
            // so the popover won't drift when the timer title updates behind it.
            button.title = ""
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        // Restore the live timer title in the menu bar once the popover is gone.
        if let runningTitle {
            applyRunningTitle(runningTitle)
        }
    }
}
