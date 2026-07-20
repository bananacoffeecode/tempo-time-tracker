import SwiftUI

enum CalendarColor: Int, CaseIterable, Identifiable {
    case lavender  = 1
    case sage      = 2
    case grape     = 3
    case flamingo  = 4
    case banana    = 5
    case tangerine = 6
    case peacock   = 7
    case graphite  = 8
    case blueberry = 9
    case basil     = 10
    case tomato    = 11

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .lavender:  return "Lavender"
        case .sage:      return "Sage"
        case .grape:     return "Grape"
        case .flamingo:  return "Flamingo"
        case .banana:    return "Banana"
        case .tangerine: return "Tangerine"
        case .peacock:   return "Peacock"
        case .graphite:  return "Graphite"
        case .blueberry: return "Blueberry"
        case .basil:     return "Basil"
        case .tomato:    return "Tomato"
        }
    }

    var color: Color {
        switch self {
        case .lavender:  return Color(red: 0.60, green: 0.60, blue: 0.85)
        case .sage:      return Color(red: 0.52, green: 0.68, blue: 0.54)
        case .grape:     return Color(red: 0.58, green: 0.44, blue: 0.72)
        case .flamingo:  return Color(red: 0.93, green: 0.58, blue: 0.67)
        case .banana:    return Color(red: 0.95, green: 0.84, blue: 0.43)
        case .tangerine: return Color(red: 0.98, green: 0.60, blue: 0.24)
        case .peacock:   return Color(red: 0.16, green: 0.64, blue: 0.82)
        case .graphite:  return Color(red: 0.55, green: 0.57, blue: 0.60)
        case .blueberry: return Color(red: 0.24, green: 0.37, blue: 0.67)
        case .basil:     return Color(red: 0.20, green: 0.47, blue: 0.37)
        case .tomato:    return Color(red: 0.87, green: 0.28, blue: 0.24)
        }
    }
}
