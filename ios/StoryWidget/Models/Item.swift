import Foundation

public protocol Item: Codable, Identifiable, Hashable {
    var id: Int { get }
    var parent: Int? { get }
    var title: String? { get }
    var text: String? { get }
    var url: String? { get }
    var type: String? { get }
    var by: String? { get }
    var score: Int? { get }
    var descendants: Int? { get }
    var time: Int { get }
    var kids: [Int]? { get }
    var metadata: String { get }
}

public extension Item {
    var createdAtDate: Date {
        let date = Date(timeIntervalSince1970: Double(time))
        return date
    }
    
    var createdAt: String {
        let date = Date(timeIntervalSince1970: Double(time))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
    
    var timeAgo: String {
        let date = Date(timeIntervalSince1970: Double(time))
        return date.timeAgoString
    }

    var formattedTime: String {
        Date(timeIntervalSince1970: Double(time)).formatted()
    }

    var itemUrl: String {
        "https://news.ycombinator.com/item?id=\(self.id)"
    }
    
    var readableUrl: String? {
        if let url = self.url {
            let domain = URL(string: url)?.host
            return domain
        }
        return nil
    }
    
    var isJob: Bool {
        return type == "job"
    }
    
    var isJobWithUrl: Bool {
        return type == "job" && text.isNullOrEmpty && url.isNotNullOrEmpty
    }
}
