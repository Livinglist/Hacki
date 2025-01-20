import WidgetKit
import Foundation

struct StoryEntry: TimelineEntry {
    let date: Date
    let story: Story
    let source: StorySource
    
    static let errorPlaceholder: StoryEntry = StoryEntry(
        date: .now,
        story: .errorPlaceholder,
        source: .top
    )
}
