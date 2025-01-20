import Foundation

extension Int?  {
    var orZero: Int {
        guard let unwrapped = self else {
            return 0
        }
        return unwrapped
    }
}
