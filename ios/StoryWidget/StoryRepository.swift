import Foundation
import Alamofire

public class StoryRepository {
    public static let shared: StoryRepository = .init()
    
    private let baseUrl: String = "https://hacker-news.firebaseio.com/v0/"
    
    private init() {}
    
    // MARK: - Story related.
    
    public func fetchAllStories(from storyType: StoryType, onStoryFetched: @escaping (Story) -> Void) async -> Void {
        let storyIds = await fetchStoryIds(from: storyType)
        for id in storyIds {
            let story = await self.fetchStory(id)
            if let story = story {
                onStoryFetched(story)
            }
        }
    }
    
    public func fetchStoryIds(from storyType: StoryType) async -> [Int] {
        let response =  await AF.request("\(self.baseUrl)\(storyType.rawValue)stories.json").serializingString().response
        guard response.data != nil else { return [Int]() }
        let storyIds = try? JSONDecoder().decode([Int].self, from: response.data!)
        return storyIds ?? [Int]()
    }
    
    public func fetchStoryIds(from storyType: String) async -> [Int] {
        let response =  await AF.request("\(self.baseUrl)\(storyType)stories.json").serializingString().response
        guard response.data != nil else { return [Int]() }
        let storyIds = try? JSONDecoder().decode([Int].self, from: response.data!)
        return storyIds ?? [Int]()
    }
    
    public func fetchStories(ids: [Int], onStoryFetched: @escaping (Story) -> Void) async -> Void {
        for id in ids {
            let story = await fetchStory(id)
            if let story = story {
                onStoryFetched(story)
            }
        }
    }
    
    public func fetchStory(_ id: Int) async -> Story?{
        let response = await AF.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           var story = try? JSONDecoder().decode(Story.self, from: data) {
            let formattedText = story.text.htmlStripped
            story = story.copyWith(text: formattedText)
            return story
        } else {
            return nil
        }
    }
    
    // MARK: - Comment related.
    
    public func fetchComments(ids: [Int], onCommentFetched: @escaping (Comment) -> Void) async -> Void {
        for id in ids {
            let comment = await fetchComment(id)
            if let comment = comment {
                onCommentFetched(comment)
            }
        }
    }
    
    public func fetchComment(_ id: Int) async -> Comment? {
        let response = await AF.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           var comment = try? JSONDecoder().decode(Comment.self, from: data) {
            let formattedText = comment.text.htmlStripped
            comment = comment.copyWith(text: formattedText)
            return comment
        } else {
            return nil
        }
    }
    
    // MARK: - Item related.
    
    public func fetchItems(ids: [Int], filtered: Bool = true, onItemFetched: @escaping (any Item) -> Void) async -> Void {
        for id in ids {
            let item = await fetchItem(id)
            guard let item = item else { continue }
            if let story = item as? Story {
                onItemFetched(story)
            } else if let cmt = item as? Comment {
                onItemFetched(cmt)
            }
        }
    }
    
    public func fetchItem(_ id: Int) async -> (any Item)? {
        let response = await AF.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           let result = try? response.result.get(),
           let map = result.toJSON() as? [String: AnyObject],
           let type = map["type"] as? String {
            switch type {
            case "story":
                let story = try? JSONDecoder().decode(Story.self, from: data)
                let formattedText = story?.text.htmlStripped
                return story?.copyWith(text: formattedText)
            case "comment":
                let comment = try? JSONDecoder().decode(Comment.self, from: data)
                let formattedText = comment?.text.htmlStripped
                return comment?.copyWith(text: formattedText)
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - User related.
    
    public func fetchUser(_ id: String) async -> User? {
        let response = await AF.request("\(self.baseUrl)/user/\(id).json").serializingString().response
        if let data = response.data,
           let user = try? JSONDecoder().decode(User.self, from: data) {
            let formattedText = user.about.orEmpty.htmlStripped
            return user.copyWith(about: formattedText)
        } else {
            return nil
        }
    }
}
