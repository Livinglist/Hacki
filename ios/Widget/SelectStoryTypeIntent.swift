import AppIntents
import HackerNewsKit

struct SelectStoryTypeIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Story Type"
    static var description = IntentDescription("Select the type of story you want to see.")
    
    @Parameter(title: "Story Type", default: StorySource.top)
    var source: StorySource
    
    init(source: StorySource) {
        self.source = source
    }
    
    init() {
        self.source = .top
    }
}
