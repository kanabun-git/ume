import SwiftUI
import UIKit

/// 判定結果一式。ContentView がカメラ/フォトライブラリからの入力を解決した後に生成する。
struct MatchResult {
    let image: UIImage?
    let mountainMatches: [MountainMatch]
    let skiResorts: [SkiResortFinder.Nearby]
    let usedCoordinate: Coordinate
    let usedHeadingDegrees: Double
    let coordinateSourceDescription: String
}

struct ResultView: View {
    let result: MatchResult

    private var bestMatch: MountainMatch? { result.mountainMatches.first }
    private var alternatives: [MountainMatch] { Array(result.mountainMatches.dropFirst().prefix(4)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = result.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                mountainSection
                skiResortSection

                Text(result.coordinateSourceDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("判定結果")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var mountainSection: some View {
        if let bestMatch {
            VStack(alignment: .leading, spacing: 8) {
                Text(bestMatch.mountain.name)
                    .font(.largeTitle.bold())
                Label("標高 \(Int(bestMatch.mountain.elevationMeters)) m", systemImage: "mountain.2.fill")
                    .font(.title3)
                Text("現在地から約\(distanceText(bestMatch.distanceMeters))・方位\(Int(bestMatch.bearingDegrees))°")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !alternatives.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("他の候補")
                        .font(.headline)
                    ForEach(alternatives) { match in
                        HStack {
                            Text(match.mountain.name)
                            Spacer()
                            Text("\(Int(match.mountain.elevationMeters)) m")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label("山を特定できませんでした", systemImage: "questionmark.circle")
                    .font(.title3.bold())
                Text("撮影方向のデータベース内に一致する山が見つかりませんでした。方角や現在地の指定を見直してください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var skiResortSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("近くのスキー場", systemImage: "figure.skiing.downhill")
                .font(.headline)

            if result.skiResorts.isEmpty {
                Text("近くにスキー場は見つかりませんでした。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(result.skiResorts) { nearby in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nearby.resort.name)
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            Text("約\(distanceText(nearby.distanceMeters))")
                            if let base = nearby.resort.baseElevationMeters, let top = nearby.resort.topElevationMeters {
                                Text("標高 \(Int(base))〜\(Int(top)) m")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func distanceText(_ meters: Double) -> String {
        meters >= 1000 ? String(format: "%.1f km", meters / 1000) : "\(Int(meters)) m"
    }
}
