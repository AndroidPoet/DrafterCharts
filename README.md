<h1 align="center">DrafterCharts</h1>

<p align="center">
  <a href="https://github.com/AndroidPoet/DrafterCharts/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/AndroidPoet/DrafterCharts/actions/workflows/ci.yml/badge.svg"/></a>
  <a href="https://opensource.org/licenses/Apache-2.0"><img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"/></a>
  <a href="https://swift.org"><img alt="Swift 5.9" src="https://img.shields.io/badge/Swift-5.9-orange.svg"/></a>
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20macOS%2013%2B-lightgrey.svg"/>
  <a href="https://github.com/AndroidPoet/DrafterCharts/releases"><img alt="Release" src="https://img.shields.io/github/v/tag/AndroidPoet/DrafterCharts?label=release"/></a>
  <a href="https://swiftpackageindex.com/AndroidPoet/DrafterCharts"><img alt="SPM" src="https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg"/></a>
</p>

<div align="center">
<p align="center">
📊 A powerful, flexible charting library for <b>SwiftUI</b> — a native Swift port of <a href="https://github.com/androidpoet/Drafter">Drafter</a> for Compose.
</p>
</div>

## Features

- 📊 **27 chart types** out of the box:
  - **Bars** — Bar, Grouped Bar, Stacked Bar, Histogram, Waterfall
  - **Lines** — Line, Grouped Line, Stacked Line, Step Line, Area
  - **Distribution** — Scatter, Bubble, Box Plot, Candlestick
  - **Part-to-whole** — Pie, Donut, Funnel, Treemap, Polar Area, Sunburst
  - **Specialized** — Radar, Gantt, Gauge, Bullet, Sankey, Stream Graph, Contribution Heatmap
- 🎨 Highly customizable appearance with a shared `DrafterThemeColors` (light/dark, custom palettes)
- ✨ Smooth, premium rendering — Catmull-Rom curves, soft gradient fills, rounded shapes
- 🎬 Built-in left-to-right reveal animation with a one-line `replay` hook
- 🚀 Pure SwiftUI `Canvas`, **zero dependencies**, no UIKit/AppKit bridging
- 📱 Value-type data models and an `@Environment`-based theme

## Installation

[![Release](https://img.shields.io/github/v/tag/AndroidPoet/DrafterCharts?label=release)](https://github.com/AndroidPoet/DrafterCharts/releases)

### Swift Package Manager (Xcode)
**File ▸ Add Package Dependencies…** and enter:

```
https://github.com/AndroidPoet/DrafterCharts.git
```

### Swift Package Manager (Package.swift)

```swift
dependencies: [
  .package(url: "https://github.com/AndroidPoet/DrafterCharts.git", from: "1.0.0")
],
targets: [
  .target(name: "MyApp", dependencies: [
    .product(name: "DrafterCharts", package: "DrafterCharts")
  ])
]
```

Then `import DrafterCharts`.

## Anatomy of a chart

Every chart is a SwiftUI `View` that takes a value-type data model. Two optional knobs are shared by all charts:

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `animate` | `true`  | Play the left-to-right reveal on appear. Pass `false` to draw fully revealed. |
| `replay`  | `0`     | Change this value (e.g. from a button) to replay the entrance animation. |

```swift
AreaChart(data: areaData)              // animates on appear
AreaChart(data: areaData, animate: false)   // static
AreaChart(data: areaData, replay: replayKey)  // bump replayKey to re-run
```

Size charts like any SwiftUI view with `.frame(...)`, and set the palette/light-dark with `.drafterTheme(...)`.

## Table of Contents

1. [Bar Charts](#bar-charts) — [Simple](#simple-bar-chart) · [Grouped](#grouped-bar-chart) · [Stacked](#stacked-bar-chart)
2. [Line Charts](#line-charts) — [Simple](#simple-line-chart) · [Grouped](#grouped-line-chart) · [Stacked](#stacked-line-chart)
3. [Histogram Chart](#histogram-chart)
4. [Waterfall Chart](#waterfall-chart)
5. [Area Chart](#area-chart)
6. [Step Line Chart](#step-line-chart)
7. [Pie & Donut Chart](#pie--donut-chart)
8. [Scatter Plot Chart](#scatter-plot-chart)
9. [Bubble Chart](#bubble-chart)
10. [Candlestick Chart](#candlestick-chart)
11. [Box Plot Chart](#box-plot-chart)
12. [Radar Chart](#radar-chart)
13. [Gauge Chart](#gauge-chart)
14. [Bullet Chart](#bullet-chart)
15. [Funnel Chart](#funnel-chart)
16. [Treemap Chart](#treemap-chart)
17. [Polar Area Chart](#polar-area-chart)
18. [Sunburst Chart](#sunburst-chart)
19. [Sankey Chart](#sankey-chart)
20. [Stream Graph Chart](#stream-graph-chart)
21. [Gantt Chart](#gantt-chart)
22. [Heatmap Chart](#heatmap-chart)

## Bar Charts

### Simple Bar Chart

```swift
SimpleBarChart(
  data: SimpleBarChartData(
    labels: ["Jan", "Feb", "Mar", "Apr"],
    values: [10, 30, 15, 45]
  )
)
.frame(height: 300)
```

### Grouped Bar Chart

```swift
GroupedBarChart(
  data: GroupedBarChartData(
    labels: ["2020", "2021", "2022"],
    itemNames: ["Product A", "Product B", "Product C"],
    groupedValues: [
      [10, 20, 15],   // 2020
      [25, 5, 30],    // 2021
      [12, 28, 10],   // 2022
    ]
  )
)
.frame(height: 300)
```

### Stacked Bar Chart

```swift
StackedBarChart(
  data: StackedBarChartData(
    labels: ["Q1", "Q2", "Q3"],
    stacks: [
      [10, 15, 5],    // Q1
      [8, 12, 20],    // Q2
      [18, 10, 15],   // Q3
    ]
  )
)
.frame(height: 300)
```

## Line Charts

### Simple Line Chart

```swift
LineChart(
  data: SimpleLineChartData(
    labels: ["A", "B", "C", "D"],
    values: [10, 20, 15, 25]
  )
)
.frame(height: 300)
```

### Grouped Line Chart

```swift
GroupedLineChart(
  data: GroupedLineChartData(
    labels: ["Q1", "Q2", "Q3", "Q4"],
    itemNames: ["Product A", "Product B"],
    groupedValues: [
      [10, 15], [20, 25], [15, 10], [25, 20],
    ],
    colors: DrafterColors.palette
  )
)
.frame(height: 300)
```

### Stacked Line Chart

```swift
StackedLineChart(
  data: StackedLineChartData(
    labels: ["Jan", "Feb", "Mar", "Apr"],
    stacks: [
      [5, 5, 2], [7, 3, 4], [6, 4, 3], [8, 2, 5],
    ],
    colors: DrafterColors.palette
  )
)
.frame(height: 300)
```

## Histogram Chart

```swift
Histogram(
  data: HistogramData(
    dataPoints: [1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 5],
    binCount: 5,
    color: DrafterColors.blue
  )
)
.frame(height: 300)
```

## Waterfall Chart

```swift
WaterfallChart(
  data: WaterfallChartData(
    labels: ["Start", "Revenue", "Cost", "Profit"],
    values: [50, -20, 30],   // changes from the initial value
    initialValue: 100
  )
)
.frame(height: 300)
```

## Area Chart

```swift
AreaChart(
  data: AreaChartData(
    labels: ["A", "B", "C", "D", "E", "F"],
    values: [12, 28, 18, 34, 24, 40],
    color: DrafterColors.blue
  )
)
.frame(height: 300)
```

## Step Line Chart

```swift
StepLineChart(
  data: StepLineChartData(
    labels: ["Mon", "Tue", "Wed", "Thu", "Fri"],
    values: [20, 35, 30, 45, 38],
    color: DrafterColors.teal
  )
)
.frame(height: 300)
```

## Pie & Donut Chart

```swift
let pie = PieChartData(slices: [
  .init(value: 40, color: DrafterColors.blue,   label: "Blue"),
  .init(value: 30, color: DrafterColors.teal,   label: "Teal"),
  .init(value: 20, color: DrafterColors.violet, label: "Violet"),
  .init(value: 10, color: DrafterColors.amber,  label: "Amber"),
])

PieChart(data: pie).frame(width: 240, height: 240)
DonutChart(data: pie).frame(width: 240, height: 240)
```

## Scatter Plot Chart

```swift
ScatterPlot(
  data: ScatterPlotData(
    points: [(8, 12), (15, 30), (22, 18), (33, 41), (40, 25), (48, 38)],
    pointColors: DrafterColors.palette
  )
)
.frame(height: 300)
```

## Bubble Chart

```swift
BubbleChart(
  data: BubbleChartData(series: [
    [ .init(x: 10, y: 26, size: 30, color: DrafterColors.blue),
      .init(x: 26, y: 30, size: 60, color: DrafterColors.blue) ],
    [ .init(x: 14, y: 15, size: 30, color: DrafterColors.teal),
      .init(x: 22, y: 36, size: 45, color: DrafterColors.teal) ],
  ])
)
.frame(height: 300)
```

## Candlestick Chart

```swift
CandlestickChart(
  data: CandlestickData(
    candles: [
      Candle(label: "1", open: 20, high: 30, low: 16, close: 26),
      Candle(label: "2", open: 26, high: 32, low: 22, close: 23),
      Candle(label: "3", open: 23, high: 28, low: 18, close: 27),
      Candle(label: "4", open: 27, high: 38, low: 25, close: 35),
    ],
    movingAverages: [MovingAverage(period: 3, color: DrafterColors.amber)]
  )
)
.frame(height: 300)
```

## Box Plot Chart

```swift
BoxPlotChart(
  data: BoxPlotData(groups: [
    BoxGroup(label: "A", min: 5,  q1: 18, median: 28, q3: 38, max: 52, color: DrafterColors.violet),
    BoxGroup(label: "B", min: 10, q1: 22, median: 30, q3: 41, max: 48, color: DrafterColors.blue),
    BoxGroup(label: "C", min: 8,  q1: 15, median: 24, q3: 33, max: 44, color: DrafterColors.teal),
  ])
)
.frame(height: 300)
```

## Radar Chart

```swift
RadarChart(
  data: [
    RadarChartData(values: [
      "Execution": 0.8, "Landing": 0.6, "Difficulty": 0.9,
      "Style": 0.7, "Creativity": 0.85,
    ])
  ]
)
.frame(width: 300, height: 300)
```

## Gauge Chart

```swift
GaugeChart(
  data: GaugeData(value: 72, min: 0, max: 100, label: "Score", color: DrafterColors.teal)
)
.frame(height: 300)
```

## Bullet Chart

```swift
BulletChart(
  data: BulletData(metrics: [
    BulletMetric(label: "Revenue", value: 72, target: 80, ranges: [40, 65, 100], color: DrafterColors.blue),
    BulletMetric(label: "Profit",  value: 55, target: 50, ranges: [30, 60, 90],  color: DrafterColors.teal),
  ])
)
.frame(height: 300)
```

## Funnel Chart

```swift
FunnelChart(
  data: FunnelData(stages: [
    FunnelStage(label: "Visits",  value: 100, color: DrafterColors.blue),
    FunnelStage(label: "Signups", value: 64,  color: DrafterColors.teal),
    FunnelStage(label: "Trials",  value: 38,  color: DrafterColors.violet),
    FunnelStage(label: "Paid",    value: 18,  color: DrafterColors.amber),
  ])
)
.frame(height: 300)
```

## Treemap Chart

```swift
TreemapChart(
  data: TreemapData(items: [
    TreemapItem(label: "Mobile",  value: 45, color: DrafterColors.blue),
    TreemapItem(label: "Desktop", value: 30, color: DrafterColors.teal),
    TreemapItem(label: "Tablet",  value: 15, color: DrafterColors.violet),
    TreemapItem(label: "Watch",   value: 8,  color: DrafterColors.amber),
  ])
)
.frame(height: 300)
```

## Polar Area Chart

```swift
PolarAreaChart(
  data: PolarAreaData(slices: [
    PolarSlice(label: "N", value: 40, color: DrafterColors.blue),
    PolarSlice(label: "E", value: 35, color: DrafterColors.violet),
    PolarSlice(label: "S", value: 30, color: DrafterColors.green),
    PolarSlice(label: "W", value: 22, color: DrafterColors.amber),
  ])
)
.frame(width: 300, height: 300)
```

## Sunburst Chart

```swift
SunburstChart(
  data: SunburstData(roots: [
    SunburstNode(label: "Web", value: 50, color: DrafterColors.blue, children: [
      SunburstNode(label: "HTML", value: 20, color: DrafterColors.blue),
      SunburstNode(label: "CSS",  value: 15, color: DrafterColors.blue),
      SunburstNode(label: "JS",   value: 15, color: DrafterColors.blue),
    ]),
    SunburstNode(label: "Mobile", value: 35, color: DrafterColors.teal, children: [
      SunburstNode(label: "iOS",     value: 20, color: DrafterColors.teal),
      SunburstNode(label: "Android", value: 15, color: DrafterColors.teal),
    ]),
  ])
)
.frame(width: 300, height: 300)
```

## Sankey Chart

```swift
SankeyChart(
  data: SankeyData(
    nodes: [
      SankeyNode(id: "a", label: "Source A", column: 0, color: DrafterColors.blue),
      SankeyNode(id: "b", label: "Source B", column: 0, color: DrafterColors.teal),
      SankeyNode(id: "m", label: "Hub",      column: 1, color: DrafterColors.violet),
      SankeyNode(id: "x", label: "Out X",    column: 2, color: DrafterColors.amber),
      SankeyNode(id: "y", label: "Out Y",    column: 2, color: DrafterColors.green),
    ],
    links: [
      SankeyLink(from: "a", to: "m", value: 30),
      SankeyLink(from: "b", to: "m", value: 20),
      SankeyLink(from: "m", to: "x", value: 28),
      SankeyLink(from: "m", to: "y", value: 22),
    ]
  )
)
.frame(height: 300)
```

## Stream Graph Chart

```swift
StreamGraphChart(
  data: StreamData(
    labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
    series: [
      StreamSeries(name: "A", values: [10, 14, 12, 18, 16, 22], color: DrafterColors.blue),
      StreamSeries(name: "B", values: [8, 10, 16, 12, 18, 14],  color: DrafterColors.teal),
      StreamSeries(name: "C", values: [6, 9, 8, 14, 11, 16],    color: DrafterColors.violet),
    ]
  )
)
.frame(height: 300)
```

## Gantt Chart

```swift
GanttChart(
  data: GanttChartData(tasks: [
    GanttTask(name: "Planning",    startMonth: 0, duration: 2),
    GanttTask(name: "Design",      startMonth: 2, duration: 2),
    GanttTask(name: "Development", startMonth: 4, duration: 3),
    GanttTask(name: "Testing",     startMonth: 7, duration: 2),
    GanttTask(name: "Deployment",  startMonth: 9, duration: 1),
  ])
)
.frame(height: 300)
```

## Heatmap Chart

```swift
let calendar = Calendar(identifier: .gregorian)
let start = Date(timeIntervalSince1970: 1_700_000_000)
let contributions: [ContributionData] = (0..<365).compactMap { day in
  guard let date = calendar.date(byAdding: .day, value: day, to: start) else { return nil }
  return ContributionData(date: date, count: max(0, (day * 13 + day % 7 * 5) % 16 - 4))
}

Heatmap(data: ContributionHeatmapData(contributions: contributions))
  .frame(height: 120)
```

## Theming

All charts read their palette and light/dark colors from a `DrafterThemeColors` in the SwiftUI environment. Set it once for a subtree:

```swift
VStack {
  AreaChart(data: areaData)
  PieChart(data: pieData)
}
.drafterTheme(.dark)   // or .light, or a custom set:
.drafterTheme(DrafterThemeColors(
  palette: [.blue, .teal, .indigo],
  grid: Color(white: 0.92),
  label: .secondary,
  surface: .white,
  isDark: false
))
```

Each chart's geometry lives in a pure `ChartRenderer` hosted by `ChartCanvas`, so the drawing is testable and the theming + reveal animation are centralized in one place.

## Demo

A runnable macOS gallery of every chart, with a **Replay animations** button:

```bash
swift run DrafterChartsDemo
```

## Contributing

Contributions are welcome! Found a bug, have an improvement, or want a new chart? Open an issue or a pull request.

## Find this repository useful? :heart:
Support it by joining __[stargazers](https://github.com/AndroidPoet/DrafterCharts/stargazers)__ for this repository. :star: <br>
Also, __[follow me](https://github.com/AndroidPoet)__ on GitHub for my next creations! 🤩

## License

```
Designed and developed by AndroidPoet (Ranbir Singh)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
