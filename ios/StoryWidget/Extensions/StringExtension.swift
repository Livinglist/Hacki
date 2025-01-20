import Foundation
import UIKit
import SwiftSoup

public extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
    
    var htmlStripped: String {
        do {
            let pRegex = try Regex("<p>")
            let iRegex = try Regex(#"\<i\>(.*?)\<\/i\>"#)
            let codeRegex = try Regex(#"\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>"#)
                .dotMatchesNewlines(true)
            let linkRegex = try Regex(#"\<a href=\"(.*?)\".*?\>.*?\<\/a\>"#)
            let res = try Entities.unescape(self)
                .replacing(pRegex, with: { match in
                    "\n"
                })
                .replacing(iRegex, with: { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return "**\(matchedStr)**"
                    }
                    return String()
                })
                .replacing(linkRegex, with: { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return matchedStr
                    }
                    return String()
                })
                .withExtraLineBreak
                .replacing(codeRegex, with: { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return "```" + String(matchedStr.replacing("\n\n", with: "``` \n ``` \n").dropLast(1)) + "```"
                    }
                    return String()
                })
            return res
        } catch {
            return error.localizedDescription
        }
    }
    
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    private var withExtraLineBreak: String {
        if isEmpty { return self }
        let range = startIndex..<index(endIndex, offsetBy: -1)
        var str = String(replacingOccurrences(of: "\n", with: "\n\n", range: range))
        while str.last?.isWhitespace == true {
            str = String(str.dropLast())
        }
        return str
    }
}

public extension Optional where Wrapped == String {
    var orEmpty: String {
        guard let unwrapped = self else {
            return ""
        }
        return unwrapped
    }
    
    var htmlStripped: String{
        guard let unwrapped = self else {
            return ""
        }
        
        return unwrapped.htmlStripped
    }
    
    var isNotNullOrEmpty: Bool {
        guard let unwrapped = self else {
            return false
        }
        
        return unwrapped.isNotEmpty
    }
}
