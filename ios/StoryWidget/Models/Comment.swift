public struct Comment: Item {
    public let id: Int
    public let parent: Int?
    public let text: String?
    public let type: String?
    public let by: String?
    public let time: Int
    public let kids: [Int]?
    public let level: Int?
    public var metadata: String {
        if let count = kids?.count, count != 0 {
            return "\(count) cmt\(count > 1 ? "s":"") | \(timeAgo) by \(by.orEmpty)"
        } else {
            return "\(timeAgo) by \(by.orEmpty)"
        }
    }
    
    /// Values below will always be nil for `Comment`.
    public let title: String?
    public let url: String?
    public let descendants: Int?
    public let score: Int?


    init(id: Int, parent: Int?, text: String?, by: String?, time: Int, kids: [Int]? = [Int](), level: Int? = 0) {
        self.id = id
        self.parent = parent
        self.text = text
        self.by = by
        self.time = time
        self.kids = kids
        self.level = level
        self.type = "comment"
        self.title = nil
        self.url = nil
        self.descendants = nil
        self.score = nil
    }

    // Empty initializer
    init() {
        self.init(id: 0, parent: 0, text: "", by: "", time: 0)
    }

    public func copyWith(text: String? = nil, level: Int? = nil) -> Comment {
        Comment(id: id, 
                parent: parent,
                text: text ?? self.text,
                by: by,
                time: time,
                kids: kids ?? [Int](),
                level: level ?? self.level)
    }
}
