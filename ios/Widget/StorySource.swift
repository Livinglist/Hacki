import AppIntents

enum StorySource: String, AppEnum {
    case top
    case best
    case new
    case ask
    case show
    case job
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Story Source"
    
    static var caseDisplayRepresentations: [StorySource : DisplayRepresentation] = [
        .top: "Top",
        .best: "Best",
        .new: "New",
        .ask: "Ask",
        .show: "Show",
        .job: "Jobs"
    ]
}
