import WidgetKit
import SwiftUI

// MARK: - Constants
struct WidgetConstants {
    static let appGroup = "group.com.rachid.silva.widgets"
    static let keyQuote = "quote_text"
    static let keyTreeImage = "tree_image"
}

// MARK: - Quote Widget

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: "Loading quote...")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = QuoteEntry(date: Date(), quote: loadQuote())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let entry = QuoteEntry(date: Date(), quote: loadQuote())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadQuote() -> String {
        let userDefaults = UserDefaults(suiteName: WidgetConstants.appGroup)
        return userDefaults?.string(forKey: WidgetConstants.keyQuote) ?? "Open Silva to see your daily thought."
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
}

struct QuoteWidgetEntryView : View {
    var entry: QuoteProvider.Entry

    var body: some View {
        VStack {
            Text(entry.quote)
                .font(.custom("Palatino-Italic", size: 16))
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(Color(UIColor.darkGray))
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            if #available(iOS 17.0, *) {
                QuoteWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                QuoteWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Daily Quote")
        .description("Your daily thought from Silva.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Tree Widget

struct TreeProvider: TimelineProvider {
    func placeholder(in context: Context) -> TreeEntry {
        TreeEntry(date: Date(), image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TreeEntry) -> ()) {
        let entry = TreeEntry(date: Date(), image: loadTreeImage())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TreeEntry>) -> ()) {
        let entry = TreeEntry(date: Date(), image: loadTreeImage())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadTreeImage() -> UIImage? {
        let userDefaults = UserDefaults(suiteName: WidgetConstants.appGroup)
        if let filename = userDefaults?.string(forKey: WidgetConstants.keyTreeImage) {
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetConstants.appGroup)
            if let fileUrl = url?.appendingPathComponent(filename) {
                if let data = try? Data(contentsOf: fileUrl) {
                    return UIImage(data: data)
                }
            }
        }
        return nil
    }
}

struct TreeEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
}

struct TreeWidgetEntryView : View {
    var entry: TreeProvider.Entry

    var body: some View {
        ZStack {
            Color.white
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Text("Grow your tree in Silva")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct TreeWidget: Widget {
    let kind: String = "TreeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TreeProvider()) { entry in
             if #available(iOS 17.0, *) {
                TreeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TreeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Silva Tree")
        .description("View the growth of your digital tree.")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}
