import Foundation
import SwiftUI

enum SleepContextTag: String, CaseIterable, Hashable, Identifiable, Sendable {
    case alcohol
    case exercise
    case heavyDinner
    case caffeine
    case congestion
    case stress
    case medication
    case sleepingOnBack

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .alcohol:
            "He begut alcohol"
        case .exercise:
            "He fet esport"
        case .heavyDinner:
            "He sopat molt"
        case .caffeine:
            "He pres cafeïna"
        case .congestion:
            "Tinc congestió"
        case .stress:
            "He tingut estrès"
        case .medication:
            "He pres medicació"
        case .sleepingOnBack:
            "Dormiré d'esquena"
        }
    }

    var systemImage: String {
        switch self {
        case .alcohol:
            "wineglass"
        case .exercise:
            "figure.run"
        case .heavyDinner:
            "fork.knife"
        case .caffeine:
            "cup.and.saucer"
        case .congestion:
            "facemask"
        case .stress:
            "brain.head.profile"
        case .medication:
            "pills"
        case .sleepingOnBack:
            "bed.double"
        }
    }
}
