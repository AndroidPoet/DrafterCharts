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

<div align="center">

![DrafterCharts demo](Art/demo.gif)

<sub><a href="https://github.com/AndroidPoet/DrafterCharts/raw/main/Art/demo.mp4">▶ Watch the full-resolution video</a></sub>

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
- ♿️ **VoiceOver built in** — every chart announces its kind and a data summary, so a `Canvas` is never silently invisible to assistive technology
- 🧩 **One consistent, type-safe API** — every chart takes its bound elements directly (`points:`, `series:`, `bars:`, `slices:`, `nodes:`…), so a label can't desync from its value and there's no `data:` wrapper to learn

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
  .package(url: "https://github.com/AndroidPoet/DrafterCharts.git", from: "0.2.0")
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
AreaChart(points: areaPoints)              // animates on appear
AreaChart(points: areaPoints, animate: false)   // static
AreaChart(points: areaPoints, replay: replayKey)  // bump replayKey to re-run
```

Size charts like any SwiftUI view with `.frame(...)`, and set the palette/light-dark with `.drafterTheme(...)`.

For the simplest single-series charts there are **values-first** convenience initializers, so trivial cases can skip building labeled elements:

```swift
LineChart(values: [40, 65, 50, 80, 70, 95])
AreaChart(values: [12, 18, 9, 24, 20, 30], color: .teal)
SimpleBarChart(values: [24, 38, 30, 46])
StepLineChart(values: [10, 25, 18, 32])
```

The full point/series form (`points:`, `series:`, `bars:`) is the primary API for labels, multi-series, and per-element colors.

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
  bars: [BarItem("Q1", 24), BarItem("Q2", 38), BarItem("Q3", 30), BarItem("Q4", 46)]
)
.frame(height: 300)
```

### Grouped Bar Chart

```swift
GroupedBarChart(
  series: [
    ChartSeries(name: "2023", color: DrafterColors.blue, values: [20, 34, 26, 40]),
    ChartSeries(name: "2024", color: DrafterColors.teal, values: [28, 30, 38, 44]),
  ],
  categories: ["Q1", "Q2", "Q3", "Q4"]
)
.frame(height: 300)
```

### Stacked Bar Chart

```swift
StackedBarChart(
  series: [
    ChartSeries(color: DrafterColors.blue,   values: [12, 16, 14, 20]),
    ChartSeries(color: DrafterColors.teal,   values: [8, 10, 12, 14]),
    ChartSeries(color: DrafterColors.violet, values: [6, 8, 10, 9]),
  ],
  categories: ["Q1", "Q2", "Q3", "Q4"]
)
.frame(height: 300)
```

## Line Charts

### Simple Line Chart

```swift
LineChart(
  points: [ChartPoint("Jan", 40), ChartPoint("Feb", 65), ChartPoint("Mar", 50), ChartPoint("Apr", 80)],
  color: .blue
)
.frame(height: 300)
```

### Grouped Line Chart

```swift
GroupedLineChart(
  series: [
    ChartSeries(name: "A", color: DrafterColors.blue, values: [30, 45, 40, 70]),
    ChartSeries(name: "B", color: DrafterColors.teal, values: [20, 35, 50, 45]),
  ],
  categories: ["Jan", "Feb", "Mar", "Apr"]
)
.frame(height: 300)
```

### Stacked Line Chart

```swift
StackedLineChart(
  series: [
    ChartSeries(color: DrafterColors.violet, values: [10, 14, 12, 20]),
    ChartSeries(color: DrafterColors.green,  values: [8, 10, 14, 12]),
  ],
  categories: ["Jan", "Feb", "Mar", "Apr"]
)
.frame(height: 300)
```

## Histogram Chart

```swift
Histogram(
  values: [2, 3, 3, 4, 5, 5, 6, 7, 8, 9, 10, 12, 13, 15],
  binCount: 5
)
.frame(height: 300)
```

## Waterfall Chart

Each `WaterfallStep` is an incremental change applied to `initialValue`; the
number of bars is driven by `steps` (one step per delta), so the counts always
line up.

```swift
WaterfallChart(
  steps: [WaterfallStep("Revenue", 50), WaterfallStep("Cost", -20), WaterfallStep("Profit", 30)],
  initialValue: 100
)
.frame(height: 300)
```

Opt into a leading **Start** bar (the initial value) and a trailing **Total**
bar (the final running total) — the classic Start … Total waterfall:

```swift
WaterfallChart(
  steps: [WaterfallStep("Sales", 60), WaterfallStep("Costs", -25), WaterfallStep("Tax", -10)],
  initialValue: 50,
  startLabel: "Start",   // draws a leading bar at the initial value
  totalLabel: "Net"      // draws a trailing bar at the final running total
)
.frame(height: 300)
```

> Counts don't have to be perfect: every chart drives its element count from the
> value arrays, and mismatched `labels`/`colors` are handled gracefully (missing
> entries fall back, extras are ignored) — no ghost columns or crashes.

## Area Chart

```swift
AreaChart(
  points: [
    ChartPoint("Jan", 12), ChartPoint("Feb", 28), ChartPoint("Mar", 18),
    ChartPoint("Apr", 34), ChartPoint("May", 24), ChartPoint("Jun", 40),
  ],
  color: DrafterColors.blue
)
.frame(height: 300)
```

## Step Line Chart

```swift
StepLineChart(
  points: [
    ChartPoint("Jan", 10), ChartPoint("Feb", 25),
    ChartPoint("Mar", 18), ChartPoint("Apr", 32),
  ]
)
.frame(height: 300)
```

## Pie & Donut Chart

```swift
let slices = [
  PieSlice(value: 40, color: DrafterColors.blue,   label: "Blue"),
  PieSlice(value: 30, color: DrafterColors.teal,   label: "Teal"),
  PieSlice(value: 20, color: DrafterColors.violet, label: "Violet"),
  PieSlice(value: 10, color: DrafterColors.amber,  label: "Amber"),
]

PieChart(slices: slices).frame(width: 240, height: 240)
DonutChart(slices: slices).frame(width: 240, height: 240)
```

## Scatter Plot Chart

```swift
ScatterPlot(
  points: [
    ScatterPoint(x: 1, y: 2),
    ScatterPoint(x: 2, y: 5),
    ScatterPoint(x: 3, y: 3, color: DrafterColors.coral),
  ]
)
.frame(height: 300)
```

## Bubble Chart

```swift
BubbleChart(
  series: [
    [ BubbleData(x: 10, y: 26, size: 30, color: DrafterColors.blue),
      BubbleData(x: 26, y: 30, size: 60, color: DrafterColors.blue) ],
    [ BubbleData(x: 14, y: 15, size: 30, color: DrafterColors.teal),
      BubbleData(x: 22, y: 36, size: 45, color: DrafterColors.teal) ],
  ]
)
.frame(height: 300)
```

## Candlestick Chart

```swift
CandlestickChart(
  candles: [
    Candle(label: "1", open: 20, high: 30, low: 16, close: 26),
    Candle(label: "2", open: 26, high: 32, low: 22, close: 23),
    Candle(label: "3", open: 23, high: 28, low: 18, close: 27),
    Candle(label: "4", open: 27, high: 38, low: 25, close: 35),
  ],
  movingAverages: [MovingAverage(period: 3, color: DrafterColors.amber)]
)
.frame(height: 300)
```

## Box Plot Chart

```swift
BoxPlotChart(
  groups: [
    BoxGroup(label: "A", min: 5,  q1: 18, median: 28, q3: 38, max: 52, color: DrafterColors.violet),
    BoxGroup(label: "B", min: 10, q1: 22, median: 30, q3: 41, max: 48, color: DrafterColors.blue),
    BoxGroup(label: "C", min: 8,  q1: 15, median: 24, q3: 33, max: 44, color: DrafterColors.teal),
  ]
)
.frame(height: 300)
```

## Radar Chart

```swift
RadarChart(
  series: [
    RadarSeries(color: DrafterColors.blue, values: ["Speed": 0.8, "Power": 0.6, "Range": 0.9]),
    RadarSeries(color: DrafterColors.teal, values: ["Speed": 0.5, "Power": 0.9, "Range": 0.6]),
  ]
)
.frame(width: 300, height: 300)
```

## Gauge Chart

```swift
GaugeChart(value: 72, min: 0, max: 100, label: "Score", color: DrafterColors.teal)
  .frame(height: 300)
```

## Bullet Chart

```swift
BulletChart(
  metrics: [
    BulletMetric(label: "Revenue", value: 72, target: 80, ranges: [40, 65, 100], color: DrafterColors.blue),
    BulletMetric(label: "Profit",  value: 55, target: 50, ranges: [30, 60, 90],  color: DrafterColors.teal),
  ]
)
.frame(height: 300)
```

## Funnel Chart

```swift
FunnelChart(
  stages: [
    FunnelStage(label: "Visits",  value: 100, color: DrafterColors.blue),
    FunnelStage(label: "Signups", value: 64,  color: DrafterColors.teal),
    FunnelStage(label: "Trials",  value: 38,  color: DrafterColors.violet),
    FunnelStage(label: "Paid",    value: 18,  color: DrafterColors.amber),
  ]
)
.frame(height: 300)
```

## Treemap Chart

```swift
TreemapChart(
  items: [
    TreemapItem(label: "Mobile",  value: 45, color: DrafterColors.blue),
    TreemapItem(label: "Desktop", value: 30, color: DrafterColors.teal),
    TreemapItem(label: "Tablet",  value: 15, color: DrafterColors.violet),
    TreemapItem(label: "Watch",   value: 8,  color: DrafterColors.amber),
  ]
)
.frame(height: 300)
```

## Polar Area Chart

```swift
PolarAreaChart(
  slices: [
    PolarSlice(label: "N", value: 40, color: DrafterColors.blue),
    PolarSlice(label: "E", value: 35, color: DrafterColors.violet),
    PolarSlice(label: "S", value: 30, color: DrafterColors.green),
    PolarSlice(label: "W", value: 22, color: DrafterColors.amber),
  ]
)
.frame(width: 300, height: 300)
```

## Sunburst Chart

```swift
SunburstChart(
  roots: [
    SunburstNode(label: "Web", value: 50, color: DrafterColors.blue, children: [
      SunburstNode(label: "HTML", value: 20, color: DrafterColors.blue),
      SunburstNode(label: "CSS",  value: 15, color: DrafterColors.blue),
      SunburstNode(label: "JS",   value: 15, color: DrafterColors.blue),
    ]),
    SunburstNode(label: "Mobile", value: 35, color: DrafterColors.teal, children: [
      SunburstNode(label: "iOS",     value: 20, color: DrafterColors.teal),
      SunburstNode(label: "Android", value: 15, color: DrafterColors.teal),
    ]),
  ]
)
.frame(width: 300, height: 300)
```

## Sankey Chart

```swift
SankeyChart(
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
.frame(height: 300)
```

## Stream Graph Chart

```swift
StreamGraphChart(
  series: [
    ChartSeries(name: "A", color: DrafterColors.blue, values: [4, 6, 8, 7, 9, 6]),
    ChartSeries(name: "B", color: DrafterColors.teal, values: [3, 4, 6, 8, 7, 9]),
  ],
  categories: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
)
.frame(height: 300)
```

## Gantt Chart

```swift
GanttChart(
  tasks: [
    GanttTask(name: "Design", startMonth: 0, duration: 2, color: DrafterColors.blue),
    GanttTask(name: "Build",  startMonth: 2, duration: 3, color: DrafterColors.teal),
  ]
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

Heatmap(contributions: contributions)
  .frame(height: 120)
```

## Theming

All charts read their palette and light/dark colors from a `DrafterThemeColors` in the SwiftUI environment. Set it once for a subtree:

```swift
VStack {
  AreaChart(points: areaPoints)
  PieChart(slices: pieSlices)
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

## Accessibility

A `Canvas` is a single opaque drawing — by default VoiceOver skips right over it. DrafterCharts fixes this for you: `ChartCanvas` collapses each chart into one accessibility element and pulls its description from the renderer, so every chart announces **what it is** and **a summary of its data** with no extra work at the call site.

```swift
AreaChart(points: [ChartPoint("Jan", 40), ChartPoint("Feb", 65), ChartPoint("Mar", 30)])
// VoiceOver: "Area chart, 3 points, Jan 40, Feb 65, Mar 30"

GaugeChart(value: 72, min: 0, max: 100, label: "Score")
// VoiceOver: "Gauge, Score 72 of 0 to 100"

SankeyChart(nodes: nodes, links: links)
// VoiceOver: "Sankey diagram, 5 nodes, 4 flows"
```

The label/value come from each `ChartRenderer`'s `accessibilityLabel` and `accessibilityValue`, so if you write a custom renderer you can describe it the same way.

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
