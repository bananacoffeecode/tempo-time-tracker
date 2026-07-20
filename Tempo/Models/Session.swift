import Foundation

struct Session {
    var name: String
    var colorId: Int   // 1–11, maps to Google Calendar colorId
    var startTime: Date
    var endTime: Date

    init(name: String = "Work session", colorId: Int = 7, startTime: Date = .now) {
        self.name = name
        self.colorId = colorId
        self.startTime = startTime
        self.endTime = startTime
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
