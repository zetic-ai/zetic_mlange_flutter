import Foundation
import ZeticMLange

public struct YOLOv8ResultMapper {
    public static func toMap(_ result: YOLOv8Result) -> [String: Any] {
        let x     = result.box[0]
        let y     = result.box[1]
        let width = result.box[2]
        let height = result.box[3]
        
        let boxDictionary: [String: Int32] = [
            "x": x,
            "y": y,
            "width": width,
            "height": height
        ]
        
        return [
            "classId": result.classId,
            "confidence": result.confidence,
            "box": boxDictionary
        ]
    }
    public static func toMap(_ results: [YOLOv8Result]) -> [String: Any] {
        let mappedArray = results.map { toMap($0) }
        return ["value": mappedArray]
    }
}
