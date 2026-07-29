import CoreLocation
import SwiftUI
import UIKit

struct ContentView: View {
    private enum Route: Hashable {
        case review
        case result
    }

    @StateObject private var locationProvider = LocationHeadingProvider()

    @State private var path: [Route] = []
    @State private var activePicker: ImagePickerView.Source?
    @State private var pendingImage: UIImage?
    @State private var pendingCoordinate: Coordinate?
    @State private var pendingHeadingDegrees: Double = 0
    @State private var headingIsKnown = false
    @State private var coordinateSourceLabel = ""
    @State private var matchResult: MatchResult?
    @State private var errorMessage: String?

    private let mountainMatcher = MountainMatcher()
    private let skiResortFinder = SkiResortFinder()
    private let dataStore = DataStore.shared

    var body: some View {
        NavigationStack(path: $path) {
            homeView
                .navigationTitle("MountainSnap")
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .review:
                        reviewView
                    case .result:
                        if let matchResult {
                            ResultView(result: matchResult)
                        }
                    }
                }
        }
        .sheet(item: $activePicker) { source in
            ImagePickerView(
                source: source,
                onPick: { image, url in
                    activePicker = nil
                    handlePicked(image: image, url: url, source: source)
                },
                onCancel: { activePicker = nil }
            )
            .ignoresSafeArea()
        }
        .onAppear {
            locationProvider.requestAuthorizationIfNeeded()
        }
    }

    private var homeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("山の写真を撮ると、現在地とコンパスの向きから山の名前・標高・近くのスキー場を判定します。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    errorMessage = nil
                    locationProvider.start()
                    activePicker = .camera
                } label: {
                    Label("カメラで撮影", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    errorMessage = nil
                    activePicker = .photoLibrary
                } label: {
                    Label("写真を選ぶ", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 48)
    }

    private var reviewView: some View {
        VStack(spacing: 20) {
            if let pendingImage {
                Image(uiImage: pendingImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if headingIsKnown {
                Text("方位 \(Int(pendingHeadingDegrees))° で判定します")
                    .font(.subheadline)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("この写真を撮ったときに向いていた方角を指定してください")
                        .font(.subheadline)
                    HStack {
                        Text("北 0°")
                        Slider(value: $pendingHeadingDegrees, in: 0...359, step: 1)
                        Text("\(Int(pendingHeadingDegrees))°")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                .padding(.horizontal)
            }

            Text(coordinateSourceLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                confirmReview()
            } label: {
                Text("この内容で判定する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .disabled(pendingCoordinate == nil)

            Spacer()
        }
        .padding(.top, 24)
        .navigationTitle("撮影方向の確認")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handlePicked(image: UIImage, url: URL?, source: ImagePickerView.Source) {
        errorMessage = nil
        pendingImage = image

        switch source {
        case .camera:
            if let snapshot = locationProvider.currentSnapshot {
                finalize(
                    image: image,
                    coordinate: snapshot.coordinate,
                    headingDegrees: snapshot.headingDegrees,
                    sourceLabel: "現在地とコンパスの向きから判定しました"
                )
            } else {
                pendingCoordinate = currentDeviceCoordinate
                pendingHeadingDegrees = locationProvider.headingDegrees ?? 0
                headingIsKnown = false
                coordinateSourceLabel = pendingCoordinate == nil
                    ? "現在地を取得できませんでした。設定アプリで位置情報を許可し、屋外で電波の入る場所で再度お試しください。"
                    : "現在地は取得できましたが方位がまだ取得できていないため、方角を指定してください。"
                path.append(.review)
            }

        case .photoLibrary:
            let metadata = url.map(PhotoMetadataExtractor.extractMetadata(from:))
                ?? PhotoMetadataExtractor.Metadata(coordinate: nil, headingDegrees: nil)

            if let coordinate = metadata.coordinate, let heading = metadata.headingDegrees {
                finalize(
                    image: image,
                    coordinate: coordinate,
                    headingDegrees: heading,
                    sourceLabel: "写真に記録されたGPS・方位情報から判定しました"
                )
            } else {
                pendingCoordinate = metadata.coordinate ?? currentDeviceCoordinate
                pendingHeadingDegrees = metadata.headingDegrees ?? 0
                headingIsKnown = false
                coordinateSourceLabel = metadata.coordinate != nil
                    ? "写真のGPS情報を使用します(方位情報がないため方角を指定してください)"
                    : "写真に位置情報がないため現在地を使用します(方角を指定してください)"
                path.append(.review)
            }
        }
    }

    private var currentDeviceCoordinate: Coordinate? {
        guard let location = locationProvider.location else { return nil }
        return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    private func confirmReview() {
        guard let pendingImage, let pendingCoordinate else { return }
        finalize(
            image: pendingImage,
            coordinate: pendingCoordinate,
            headingDegrees: pendingHeadingDegrees,
            sourceLabel: coordinateSourceLabel
        )
    }

    private func finalize(image: UIImage, coordinate: Coordinate, headingDegrees: Double, sourceLabel: String) {
        let matches = mountainMatcher.candidates(
            userLocation: coordinate,
            headingDegrees: headingDegrees,
            mountains: dataStore.mountains
        )
        let resorts = skiResortFinder.resorts(
            near: matches.first?.mountain,
            userLocation: coordinate,
            skiResorts: dataStore.skiResorts
        )

        matchResult = MatchResult(
            image: image,
            mountainMatches: matches,
            skiResorts: resorts,
            usedCoordinate: coordinate,
            usedHeadingDegrees: headingDegrees,
            coordinateSourceDescription: sourceLabel
        )
        path.append(.result)
    }
}
