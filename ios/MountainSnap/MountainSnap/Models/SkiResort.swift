import Foundation

/// スキー場の位置データ。`Resources/ski_resorts_japan.json` から読み込まれる。
struct SkiResort: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    /// 最寄りの `Mountain.id`(存在する場合)。
    let nearestMountainId: String?
    let baseElevationMeters: Double?
    let topElevationMeters: Double?

    var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}
