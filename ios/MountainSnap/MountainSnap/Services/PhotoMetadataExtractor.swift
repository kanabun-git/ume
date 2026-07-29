import Foundation
import ImageIO

/// フォトライブラリから選んだ写真のEXIFから位置・方位を取り出す。
/// カメラ即時撮影と違いライブ計測ができないため、写真自体に埋め込まれた
/// GPS/方位情報(iPhoneのカメラアプリはコンパス較正済みなら方位も記録することがある)を利用する。
/// 方位情報が無い場合は nil を返し、呼び出し側で手動調整UIにフォールバックする。
enum PhotoMetadataExtractor {
    struct Metadata {
        let coordinate: Coordinate?
        let headingDegrees: Double?
    }

    static func extractMetadata(from url: URL) -> Metadata {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return Metadata(coordinate: nil, headingDegrees: nil)
        }

        let coordinate = coordinate(fromGPS: gps)
        let heading = (gps[kCGImagePropertyGPSImgDirection] as? NSNumber)?.doubleValue
            ?? (gps[kCGImagePropertyGPSDestBearing] as? NSNumber)?.doubleValue

        return Metadata(coordinate: coordinate, headingDegrees: heading)
    }

    private static func coordinate(fromGPS gps: [CFString: Any]) -> Coordinate? {
        guard let latitude = (gps[kCGImagePropertyGPSLatitude] as? NSNumber)?.doubleValue,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let longitude = (gps[kCGImagePropertyGPSLongitude] as? NSNumber)?.doubleValue,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }

        let signedLatitude = latitudeRef.uppercased() == "S" ? -latitude : latitude
        let signedLongitude = longitudeRef.uppercased() == "W" ? -longitude : longitude
        return Coordinate(latitude: signedLatitude, longitude: signedLongitude)
    }
}
