import Foundation

/// 山の位置・標高データ。`Resources/mountains_japan.json` から読み込まれる。
struct Mountain: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let nameKana: String?
    let elevationMeters: Double
    let latitude: Double
    let longitude: Double
    let prefecture: String?

    var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}
