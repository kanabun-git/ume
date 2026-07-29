import Foundation

/// バンドルされた山・スキー場のJSONデータを読み込むシンプルなストア。
final class DataStore {
    static let shared = DataStore()

    let mountains: [Mountain]
    let skiResorts: [SkiResort]

    private init() {
        mountains = Self.load(resourceName: "mountains_japan", as: [Mountain].self)
        skiResorts = Self.load(resourceName: "ski_resorts_japan", as: [SkiResort].self)
    }

    private static func load<T: Decodable>(resourceName: String, as type: T.Type) -> T where T: RangeReplaceableCollection {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("バンドルリソースが見つかりません: \(resourceName).json")
            return T()
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("\(resourceName).json のデコードに失敗しました: \(error)")
            return T()
        }
    }
}
