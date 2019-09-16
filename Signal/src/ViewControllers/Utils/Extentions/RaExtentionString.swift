
import Foundation

public extension String {
    subscript (range: PartialRangeFrom<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<endIndex])
    }
    
    subscript (range: PartialRangeUpTo<Int>) -> String {
        let endIndex = self.index(self.endIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    subscript (range: PartialRangeThrough<Int>) -> String {
        let endIndex = self.index(self.endIndex, offsetBy: range.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript (range: ClosedRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript (range: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
