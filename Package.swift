// swift-tools-version: 5.9
import PackageDescription

// DrafterCharts — a native SwiftUI port of the Drafter Compose charting library.
//
// Pure Swift, no Kotlin dependency. Every chart is drawn with SwiftUI `Canvas` /
// `GraphicsContext` and carries the same premium character as the Compose
// original: Catmull-Rom smooth curves, soft fade-to-transparent gradient fills,
// and a left-to-right reveal animation. Idiomatic for an iOS SwiftUI app —
// value-type data models, `Shape`-based geometry, and `withAnimation`-driven
// entrances.
let package = Package(
  name: "DrafterCharts",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "DrafterCharts", targets: ["DrafterCharts"]),
    .executable(name: "DrafterChartsDemo", targets: ["DrafterChartsDemo"]),
  ],
  targets: [
    .target(name: "DrafterCharts"),
    .executableTarget(name: "DrafterChartsDemo", dependencies: ["DrafterCharts"]),
    .testTarget(name: "DrafterChartsTests", dependencies: ["DrafterCharts"]),
  ],
)
