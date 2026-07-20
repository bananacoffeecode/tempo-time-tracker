import Foundation

extension Int {
    /// Formats a total seconds count as HH:MM:SS.
    var asElapsedTime: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Compact form for the menu bar: `M:SS` under an hour, else `H:MM:SS`.
    var asCompactElapsed: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    /// Human duration label, e.g. `5m`, `1h 05m`.
    var asDurationLabel: String {
        let total = Swift.max(0, self)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }
}

extension Date {
    /// Seconds elapsed between this date and now, formatted as HH:MM:SS.
    var elapsedFormatted: String {
        Int(Date.now.timeIntervalSince(self)).asElapsedTime
    }
}
