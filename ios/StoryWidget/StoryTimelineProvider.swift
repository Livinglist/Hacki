import WidgetKit

struct StoryTimelineProvider: AppIntentTimelineProvider {
    func snapshot(for configuration: SelectStoryTypeIntent, in context: Context) async -> StoryEntry {
        let ids = await StoryRepository.shared.fetchStoryIds(from: configuration.source.rawValue)
        guard let first = ids.first else { return .errorPlaceholder }
        let story = await StoryRepository.shared.fetchStory(first)
        guard let story = story else { return .errorPlaceholder }
        let entry = StoryEntry(date: Date(), story: story, source: configuration.source)
        return entry
    }
    
    func placeholder(in context: Context) -> StoryEntry {
        let story = Story(
            id: 0,
            title: "This is a placeholder story",
            text: "text",
            url: "",
            type: "story",
            by: "Hacki",
            score: 100,
            descendants: 24,
            time: Int(Date().timeIntervalSince1970)
        )
        return StoryEntry(date: Date(), story: story, source: .top)
    }
    
    func timeline(for configuration: SelectStoryTypeIntent, in context: Context) async -> Timeline<StoryEntry> {
        let ids = await StoryRepository.shared.fetchStoryIds(from: configuration.source.rawValue)
        guard let first = ids.first else {
            return Timeline(entries: [.errorPlaceholder], policy: .atEnd)
        }
        let story = await StoryRepository.shared.fetchStory(first)
        guard let story = story else {
            return Timeline(entries: [.errorPlaceholder], policy: .atEnd)
        }
        let entry = StoryEntry(date: Date(), story: story, source: configuration.source)
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        return timeline
    }
}
