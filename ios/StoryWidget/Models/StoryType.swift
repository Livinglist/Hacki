import AppIntents
import SwiftData

public enum StoryType: String, Equatable, CaseIterable, AppEnum, Codable {
    case top = "top"
    case best = "best"
    case new = "new"
    case ask = "ask"
    case show = "show"
    case jobs = "job"
    
    public var icon: String {
        switch self {
        case .top:
            return "flame"
        case .best:
            return "medal"
        case .new:
            return "rectangle.dashed"
        case .ask:
            return "questionmark.bubble"
        case .show:
            return "sparkles.tv"
        case .jobs:
            return "briefcase"
        }
    }
    
    public var label: String {
        switch self {
        case .jobs:
            return "jobs"
        default:
            return self.rawValue
        }
    }
    
    public var isDownloadable: Bool {
        switch self {
        case .top, .ask, .best:
            return true
        default:
            return false
        }
    }
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Story Type"
    public static var caseDisplayRepresentations: [StoryType : DisplayRepresentation] = [
        .top: "Top",
        .best: "Best",
        .new: "New",
        .ask: "Ask HN",
        .show: "Show HN",
        .jobs: "YC Jobs"
    ]
}
