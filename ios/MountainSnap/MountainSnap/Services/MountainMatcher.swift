import Foundation

/// 判定された山の候補。角度差が小さいほど、カメラの向きに近い方角にある山。
struct MountainMatch: Identifiable {
    let mountain: Mountain
    let distanceMeters: Double
    let bearingDegrees: Double
    let angularDifferenceDegrees: Double

    var id: String { mountain.id }
}

/// 現在地・撮影方位から視野内の山を検索するロジック。
/// CoreLocation/UIKit に依存しないため単体テストが可能。
struct MountainMatcher {
    /// iPhone標準(広角)カメラの水平画角のおおよその値。
    var cameraHorizontalFieldOfViewDegrees: Double = 60
    /// コンパス精度・手ブレ・端末の傾き誤差を吸収するための許容角度。
    var headingToleranceDegrees: Double = 8
    /// 探索する最大距離。富士山のような高峰は100km以上離れても視認できるため広めに取る。
    var maxSearchRadiusMeters: Double = 200_000
    /// 遠距離(50km超)では低い山は稜線に隠れて見えないことが多いため、
    /// 一定標高以上の山だけを候補に残す簡易フィルタ。
    var minElevationForLongRangeMeters: Double = 1500
    var longRangeThresholdMeters: Double = 50_000

    func candidates(
        userLocation: Coordinate,
        headingDegrees: Double,
        mountains: [Mountain]
    ) -> [MountainMatch] {
        let halfFOV = cameraHorizontalFieldOfViewDegrees / 2 + headingToleranceDegrees

        let matches: [MountainMatch] = mountains.compactMap { mountain in
            let distance = GeoMath.distanceMeters(from: userLocation, to: mountain.coordinate)
            guard distance > 0, distance <= maxSearchRadiusMeters else { return nil }
            if distance > longRangeThresholdMeters, mountain.elevationMeters < minElevationForLongRangeMeters {
                return nil
            }

            let bearing = GeoMath.initialBearingDegrees(from: userLocation, to: mountain.coordinate)
            let angularDiff = GeoMath.angularDifferenceDegrees(bearing, headingDegrees)
            guard angularDiff <= halfFOV else { return nil }

            return MountainMatch(
                mountain: mountain,
                distanceMeters: distance,
                bearingDegrees: bearing,
                angularDifferenceDegrees: angularDiff
            )
        }

        // カメラの向きに近い山を優先し、角度差がほぼ同じ場合は近い山を優先する。
        return matches.sorted { lhs, rhs in
            if abs(lhs.angularDifferenceDegrees - rhs.angularDifferenceDegrees) > 1 {
                return lhs.angularDifferenceDegrees < rhs.angularDifferenceDegrees
            }
            return lhs.distanceMeters < rhs.distanceMeters
        }
    }

    func bestMatch(
        userLocation: Coordinate,
        headingDegrees: Double,
        mountains: [Mountain]
    ) -> MountainMatch? {
        candidates(userLocation: userLocation, headingDegrees: headingDegrees, mountains: mountains).first
    }
}

/// 指定座標付近のスキー場を検索する。
struct SkiResortFinder {
    var searchRadiusMeters: Double = 20_000

    struct Nearby: Identifiable {
        let resort: SkiResort
        let distanceMeters: Double
        var id: String { resort.id }
    }

    func nearbyResorts(around coordinate: Coordinate, skiResorts: [SkiResort]) -> [Nearby] {
        skiResorts
            .map { Nearby(resort: $0, distanceMeters: GeoMath.distanceMeters(from: coordinate, to: $0.coordinate)) }
            .filter { $0.distanceMeters <= searchRadiusMeters }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    /// 判定された山に紐づくスキー場を優先しつつ、周辺のスキー場も含めて返す。
    func resorts(near mountain: Mountain?, userLocation: Coordinate, skiResorts: [SkiResort]) -> [Nearby] {
        guard let mountain else {
            return nearbyResorts(around: userLocation, skiResorts: skiResorts)
        }

        let linked = skiResorts.filter { $0.nearestMountainId == mountain.id }
        let linkedNearby = linked
            .map { Nearby(resort: $0, distanceMeters: GeoMath.distanceMeters(from: mountain.coordinate, to: $0.coordinate)) }
            .sorted { $0.distanceMeters < $1.distanceMeters }

        if !linkedNearby.isEmpty {
            return linkedNearby
        }
        return nearbyResorts(around: mountain.coordinate, skiResorts: skiResorts)
    }
}
