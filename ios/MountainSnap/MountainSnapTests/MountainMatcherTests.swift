import XCTest
@testable import MountainSnap

final class GeoMathTests: XCTestCase {
    func testDistanceIsZeroForSamePoint() {
        let point = Coordinate(latitude: 35.0, longitude: 138.0)
        XCTAssertEqual(GeoMath.distanceMeters(from: point, to: point), 0, accuracy: 0.001)
    }

    func testDistanceRoughlyMatchesOneDegreeOfLatitude() {
        // 緯度1度分の距離はおよそ111kmになる。
        let a = Coordinate(latitude: 35.0, longitude: 138.0)
        let b = Coordinate(latitude: 36.0, longitude: 138.0)
        let distance = GeoMath.distanceMeters(from: a, to: b)
        XCTAssertEqual(distance, 111_000, accuracy: 2_000)
    }

    func testBearingDueNorth() {
        let a = Coordinate(latitude: 35.0, longitude: 138.0)
        let b = Coordinate(latitude: 36.0, longitude: 138.0)
        let bearing = GeoMath.initialBearingDegrees(from: a, to: b)
        XCTAssertEqual(bearing, 0, accuracy: 0.5)
    }

    func testBearingDueSouth() {
        let a = Coordinate(latitude: 35.0, longitude: 138.0)
        let b = Coordinate(latitude: 34.0, longitude: 138.0)
        let bearing = GeoMath.initialBearingDegrees(from: a, to: b)
        XCTAssertEqual(bearing, 180, accuracy: 0.5)
    }

    func testAngularDifferenceHandlesWraparound() {
        XCTAssertEqual(GeoMath.angularDifferenceDegrees(350, 10), 20, accuracy: 0.001)
        XCTAssertEqual(GeoMath.angularDifferenceDegrees(10, 350), 20, accuracy: 0.001)
        XCTAssertEqual(GeoMath.angularDifferenceDegrees(10, 20), 10, accuracy: 0.001)
    }
}

final class MountainMatcherTests: XCTestCase {
    private let userLocation = Coordinate(latitude: 35.0, longitude: 138.0)

    private func mountain(id: String, latitudeOffset: Double, longitudeOffset: Double, elevation: Double = 2500) -> Mountain {
        Mountain(
            id: id,
            name: id,
            nameKana: nil,
            elevationMeters: elevation,
            latitude: userLocation.latitude + latitudeOffset,
            longitude: userLocation.longitude + longitudeOffset,
            prefecture: nil
        )
    }

    func testBestMatchPicksMountainInCameraDirection() {
        // 北(方位0度)にある山と、東(方位90度)にある山を用意する。
        let northMountain = mountain(id: "north", latitudeOffset: 0.5, longitudeOffset: 0)
        let eastMountain = mountain(id: "east", latitudeOffset: 0, longitudeOffset: 0.5)
        let matcher = MountainMatcher()

        let best = matcher.bestMatch(
            userLocation: userLocation,
            headingDegrees: 0,
            mountains: [northMountain, eastMountain]
        )

        XCTAssertEqual(best?.mountain.id, "north")
    }

    func testCandidatesExcludeMountainsOutsideFieldOfView() {
        // 真反対(方位180度)の山は、北向き(0度)のカメラの視野には入らない。
        let behindMountain = mountain(id: "behind", latitudeOffset: -0.5, longitudeOffset: 0)
        let matcher = MountainMatcher()

        let candidates = matcher.candidates(
            userLocation: userLocation,
            headingDegrees: 0,
            mountains: [behindMountain]
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testLowElevationMountainsAreExcludedAtLongRange() {
        // 100km以上離れた低山(1000m)は稜線に隠れる想定で除外される。
        let farLowMountain = mountain(id: "far-low", latitudeOffset: 1.0, longitudeOffset: 0, elevation: 1000)
        let matcher = MountainMatcher()

        let candidates = matcher.candidates(
            userLocation: userLocation,
            headingDegrees: 0,
            mountains: [farLowMountain]
        )

        XCTAssertTrue(candidates.isEmpty)
    }
}

final class SkiResortFinderTests: XCTestCase {
    func testNearbyResortsAreSortedByDistance() {
        let origin = Coordinate(latitude: 35.0, longitude: 138.0)
        let near = SkiResort(id: "near", name: "near", latitude: 35.02, longitude: 138.0, nearestMountainId: nil, baseElevationMeters: nil, topElevationMeters: nil)
        let far = SkiResort(id: "far", name: "far", latitude: 35.1, longitude: 138.0, nearestMountainId: nil, baseElevationMeters: nil, topElevationMeters: nil)
        let outOfRange = SkiResort(id: "out", name: "out", latitude: 40.0, longitude: 138.0, nearestMountainId: nil, baseElevationMeters: nil, topElevationMeters: nil)

        let finder = SkiResortFinder(searchRadiusMeters: 20_000)
        let result = finder.nearbyResorts(around: origin, skiResorts: [far, near, outOfRange])

        XCTAssertEqual(result.map(\.resort.id), ["near", "far"])
    }
}
