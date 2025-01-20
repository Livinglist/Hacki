import WidgetKit

extension Timeline where EntryType == StoryEntry {
    static let errorPlaceholder: Timeline<StoryEntry> = .init(
        entries: [.errorPlaceholder],
        policy: .atEnd
    )
}
