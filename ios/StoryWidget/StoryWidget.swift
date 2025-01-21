import WidgetKit
import SwiftUI
import AppIntents

struct StoryWidgetView : View {
    @Environment(\.widgetFamily) var family
    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
    var story: Story
    var source: StorySource

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 0) {
                Text(story.shortMetadata)
                    .font(.caption)
                Text(story.title.orEmpty)
                    .font(.caption).fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Spacer(minLength: 0)
            }
            .containerBackground(for: .widget) {
                Color(UIColor.secondarySystemBackground)
            }
            .widgetURL(URL(string: "/item/\(story.id)"))
        default:
            HStack {
                VStack {
                    Text(story.title.orEmpty)
                        .font(family == .systemSmall ? .system(size: 14) : .body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    if let text = story.text, text.isNotEmpty {
                        HStack {
                            Text(text.replacingOccurrences(of: "\n", with: " "))
                                .font(.footnote)
                                .lineLimit(3)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    Spacer()
                    HStack {
                        if let url = story.readableUrl {
                            Text(url)
                                .font(family == .systemSmall ? .system(size: 8) : .footnote)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                    Divider().frame(maxWidth: .infinity)
                    HStack(alignment: .center) {
                        Text("\(source.rawValue.uppercased()) | \(story.metadata)")
                            .font(family == .systemSmall ? showsWidgetContainerBackground ? .system(size: 10) : .system(size: 8) : .caption)
                            .padding(.top, showsWidgetContainerBackground ? 2 : .zero)
                        Spacer()
                    }
                }
            }
            .padding(.all, showsWidgetContainerBackground ? .zero : nil)
            .containerBackground(for: .widget) {
                Color(UIColor.secondarySystemBackground)
            }
            .widgetURL(URL(string: "/item/\(story.id)"))
        }
    }
}

struct StoryWidget: Widget {
    let kind: String = "StoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectStoryTypeIntent.self,
            provider: StoryTimelineProvider()) { entry in
                StoryWidgetView(story: entry.story, source: entry.source)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .configurationDisplayName("Story on Hacker News")
        .description("Watch out. It's hot.")
    }
}
