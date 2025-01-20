import Foundation

extension Optional where Wrapped: Collection {
    var isMoreThanOne: Bool {
        guard let unwrapped = self else {
            return false
        }
        
        if unwrapped.count > 1 {
            return true
        } else {
            return false
        }
    }
    
    
    var isNullOrEmpty: Bool {
        guard let unwrapped = self else {
            return true
        }
        
        return unwrapped.isEmpty
    }
    
    var isNotNullOrEmpty: Bool {
        return !isNullOrEmpty
    }
    
    var countOrZero: Int {
        guard let unwrapped = self else {
            return 0
        }
        
        return unwrapped.count
    }
}
