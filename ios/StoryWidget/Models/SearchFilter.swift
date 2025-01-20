import Foundation

public enum SearchFilter: Equatable, Hashable {
    case story
    case comment
    case dateRange(Date, Date)
    
    var query: String {
        switch(self){
        case .story:
            return "story"
        case .comment:
            return "comment"
        case .dateRange(let startDate, let endDate):
            let startTimestamp = Int(startDate.timeIntervalSince1970.rounded())
            let endTimestamp = Int(endDate.timeIntervalSince1970.rounded())
            
            if startTimestamp != endTimestamp {
                return "created_at_i>=\(startTimestamp),created_at_i<=\(endTimestamp)"
            } else {
                let updatedStartDate = Calendar.current.date(
                    byAdding: .hour,
                    value: -24,
                    to: startDate)
                let updatedStartTimestamp = updatedStartDate?.timeIntervalSince1970
                
                if let updatedStartTimestamp = updatedStartTimestamp?.rounded() {
                    return "created_at_i>=\(Int(updatedStartTimestamp)),created_at_i<=\(endTimestamp)"
                }
                
                return .init()
            }
        }
    }
    
    var isNumericFilter: Bool {
        switch(self){
        case .story, .comment:
            return false
        case .dateRange:
            return true
        }
    }
    
    var isTagFilter: Bool {
        !isNumericFilter
    }
}
