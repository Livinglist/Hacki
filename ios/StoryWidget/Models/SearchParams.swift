import Foundation

public class SearchParams: Equatable {
    public let page: Int
    public let query: String
    public let sorted: Bool
    public let filters: Set<SearchFilter>
    
    public var filteredQuery: String {
        var buffer = String()
        
        if sorted {
            buffer.append("search_by_date?query=\(query)")
        } else {
            buffer.append("search?query=\(query)")
        }
        
        if !filters.isEmpty {
            let numericFilters = filters.filter({ $0.isNumericFilter })
            let tagFilters = filters.filter({ $0.isTagFilter })
            
            if !numericFilters.isEmpty {
                buffer.append("&numericFilters=")
                for filter in filters.filter({ $0.isNumericFilter }) {
                    buffer.append(filter.query)
                    buffer.append(",")
                }
                buffer = String(buffer.dropLast(1))
            }

            if !tagFilters.isEmpty {
                buffer.append("&tags=(")
                for filter in filters.filter({ $0.isTagFilter }) {
                    buffer.append(filter.query)
                    buffer.append(",")
                }
                buffer = String(buffer.dropLast(1))
                buffer.append(")")
            }

        }
        
        buffer.append("&page=\(page)");
        
        return buffer
    }
    
    public init(page: Int, query: String, sorted: Bool, filters: Set<SearchFilter>) {
        self.page = page
        self.query = query
        self.sorted = sorted
        self.filters = filters
    }
    
    public func copyWith(page: Int? = nil, query: String? = nil, sorted: Bool? = nil, filters: Set<SearchFilter>? = nil) -> SearchParams {
        return SearchParams(page: page ?? self.page, query: query ?? self.query, sorted: sorted ?? self.sorted, filters: filters ?? self.filters)
    }
    
    public static func == (lhs: SearchParams, rhs: SearchParams) -> Bool {
        return lhs.page == rhs.page && lhs.query == rhs.query && lhs.sorted == rhs.sorted && lhs.filters == rhs.filters
    }
}
