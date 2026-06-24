# DrafterCharts

Native **SwiftUI** charting library — a pure-Swift port of the Drafter Compose charts. Every chart is drawn with SwiftUI `Canvas` / `GraphicsContext` and carries the same premium character: Catmull-Rom smooth curves, soft fade-to-transparent gradient fills, rounded shapes, and a left-to-right reveal animation.

- **Pure SwiftUI**, zero dependencies, no UIKit/AppKit bridging
- **27 chart views** across 20 families
- **iOS 16+ / macOS 13+**
- Value-type data models, `@Environment`-based theming, and a one-line replay-animation hook

## Installation

### Swift Package Manager (Xcode)
File ▸ Add Package Dependencies… and enter the repo URL:

```
https://github.com/<your-org>/DrafterCharts.git
```

### Swift Package Manager (Package.swift)
```swift
dependencies: [
  .package(url: "https://github.com/<your-org>/DrafterCharts.git", from: "1.0.0")
],
targets: [
  .target(name: "MyApp", dependencies: [
    .product(name: "DrafterCharts", package: "DrafterCharts")
  ])
]
```

## Quick start

```swift
import SwiftUI
import DrafterCharts

struct Dashboard: View {
  var body: some View {
    AreaChart(
      data: AreaChartData(
        labels: ["Jan", "Feb", "Mar", "Apr", "May"],
        values: [12, 28, 19, 41, 35]
      )
    )
    .frame(height: 220)
    .drafterTheme(.light)   // or .dark
  }
}
```

### Replay the entrance animation
Every chart takes a `replay: Int` — increment it (e.g. from a button) to retrace all charts at once:

```swift
@State private var replay = 0

ScrollView {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
    AreaChart(data: areaData, replay: replay).frame(height: 200)
    PieChart(data: pieData, replay: replay).frame(height: 200)
    // …
  }
}
.toolbar { Button("Replay") { replay += 1 } }
```

Pass `animate: false` to render fully drawn with no entrance.

## Charts

Area · Line (simple / grouped / stacked) · Bar (simple / grouped / stacked / histogram / waterfall) · Pie · Donut · Candlestick (with moving averages) · Radar · Scatter · Bubble · Gauge · Sankey · Treemap · Stream graph · Sunburst · Funnel · Bullet · Box plot · Gantt · Step line · Heatmap (contribution calendar) · Polar area

## Theming

Charts read a `DrafterThemeColors` from the environment. Use the bundled `.light` / `.dark`, or supply your own palette:

```swift
content.drafterTheme(DrafterThemeColors(
  palette: [.blue, .teal, .indigo],
  grid: Color(white: 0.92),
  label: .secondary,
  surface: .white,
  isDark: false
))
```

## Architecture

Each chart is a pure `ChartRenderer` (all geometry/drawing, fully testable) hosted by `ChartCanvas`, which owns theming + the reveal animation in one place. The reveal is driven by an `Animatable` canvas host so SwiftUI interpolates progress frame-by-frame. Reusable primitives (`smoothPath`, `areaGradient`, `SmoothLineShape`, `ChartAxis`, `RadialLayout`, …) are shared across charts.

## Demo

```bash
swift run DrafterChartsDemo
```

## License

Apache License 2.0. See [LICENSE](LICENSE).
