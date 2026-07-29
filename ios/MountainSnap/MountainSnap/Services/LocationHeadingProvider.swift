import Combine
import CoreLocation
import Foundation

/// 現在地とコンパス方位(真北基準)を提供する。
/// カメラ画面が表示されている間、常に最新の位置・方位を保持しておき、
/// シャッターが押された瞬間の値をスナップショットとして取得する。
@MainActor
final class LocationHeadingProvider: NSObject, ObservableObject {
    struct Snapshot {
        let coordinate: Coordinate
        let headingDegrees: Double
        let capturedAt: Date
    }

    @Published private(set) var location: CLLocation?
    @Published private(set) var headingDegrees: Double?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isHeadingAvailable: Bool = CLLocationManager.headingAvailable()

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
    }

    func requestAuthorizationIfNeeded() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    var currentSnapshot: Snapshot? {
        guard let location, let headingDegrees else { return nil }
        return Snapshot(
            coordinate: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            headingDegrees: headingDegrees,
            capturedAt: Date()
        )
    }
}

extension LocationHeadingProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        Task { @MainActor in
            self.location = newLocation
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = heading
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.start()
            }
        }
    }
}
