import Foundation

/// 緯度・経度(度)。CoreLocation に依存しない純粋な値型にしておくことで、
/// UIKit/CoreLocation なしでも幾何計算のテストができるようにしている。
struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

/// 大圏距離・方位角の計算。半径6,371kmの球体近似(Haversine公式)を用いる。
/// 山岳判定に必要な精度(数百m〜数km程度の誤差)には十分。
enum GeoMath {
    static let earthRadiusMeters = 6_371_000.0

    /// 2点間の距離(メートル)。
    static func distanceMeters(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude.degreesToRadians
        let lat2 = b.latitude.degreesToRadians
        let dLat = (b.latitude - a.latitude).degreesToRadians
        let dLon = (b.longitude - a.longitude).degreesToRadians

        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(h), sqrt(1 - h))
        return earthRadiusMeters * c
    }

    /// aからbを見たときの初期方位角(度、真北=0、時計回り)。
    static func initialBearingDegrees(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude.degreesToRadians
        let lat2 = b.latitude.degreesToRadians
        let dLon = (b.longitude - a.longitude).degreesToRadians

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).radiansToDegrees
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    /// 2つの方位角(度)の差の絶対値(0〜180度)。
    static func angularDifferenceDegrees(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return diff > 180 ? 360 - diff : diff
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
