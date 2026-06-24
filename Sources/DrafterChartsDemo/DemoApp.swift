//
//  DemoApp.swift
//  DrafterChartsDemo
//
//  A runnable SwiftUI gallery for DrafterCharts: every chart type laid out in an
//  adaptive grid, each with realistic deterministic sample data, plus a "Replay
//  animations" button that re-triggers every chart's entrance animation.
//
//  Run with: `swift run DrafterChartsDemo`.
//

import SwiftUI
import DrafterCharts

@main
struct DrafterChartsDemoApp: App {
  var body: some Scene {
    WindowGroup("Drafter Charts — SwiftUI") {
      ContentView()
    }
  }
}

// MARK: - Content

struct ContentView: View {
  @State private var replayKey = 0

  private let columns = [GridItem(.adaptive(minimum: 300), spacing: 16)]

  var body: some View {
    VStack(spacing: 0) {
      header

      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(SampleData.cards, id: \.title) { card in
            ChartCard(title: card.title) {
              card.make(replayKey)
            }
          }
        }
        .padding(16)
      }
      .drafterTheme(.light)
    }
    .frame(minWidth: 720, minHeight: 560)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Drafter Charts")
          .font(.title.bold())
        Text("SwiftUI demo gallery — \(SampleData.cards.count) chart types")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button {
        replayKey += 1
      } label: {
        Label("Replay animations", systemImage: "arrow.clockwise")
      }
      .keyboardShortcut("r", modifiers: [.command])
    }
    .padding(16)
    .background(.thinMaterial)
  }
}

// MARK: - Card chrome

/// A titled card wrapping a single chart at a fixed height.
private struct ChartCard<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      content
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    )
  }
}

// MARK: - Sample data + card registry

/// One gallery entry: a title and a factory that builds the chart for a replay key.
private struct GalleryCard {
  let title: String
  let make: (Int) -> AnyView
}

private enum SampleData {

  // A fixed palette pulled from the library for legible multi-series charts.
  static let p = DrafterColors.palette

  // Shared deterministic axes.
  static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
  static let quarters = ["Q1", "Q2", "Q3", "Q4"]

  static let cards: [GalleryCard] = [
    GalleryCard(title: "Area Chart") { key in
      AnyView(AreaChart(
        data: AreaChartData(labels: months, values: [12, 18, 9, 24, 20, 30]),
        replay: key
      ))
    },
    GalleryCard(title: "Line Chart") { key in
      AnyView(LineChart(
        data: SimpleLineChartData(labels: months, values: [40, 65, 50, 80, 70, 95]),
        replay: key
      ))
    },
    GalleryCard(title: "Grouped Line Chart") { key in
      AnyView(GroupedLineChart(
        data: GroupedLineChartData(
          labels: months,
          itemNames: ["A", "B"],
          groupedValues: [
            [30, 20], [45, 35], [40, 50], [70, 45], [60, 65], [85, 55],
          ],
          colors: [p[0], p[1]]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Stacked Line Chart") { key in
      AnyView(StackedLineChart(
        data: StackedLineChartData(
          labels: months,
          stacks: [
            [10, 8], [14, 10], [12, 14], [20, 12], [18, 16], [24, 14],
          ],
          colors: [p[2], p[4]]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Simple Bar Chart") { key in
      AnyView(SimpleBarChart(
        data: SimpleBarChartData(labels: quarters, values: [24, 38, 30, 46]),
        replay: key
      ))
    },
    GalleryCard(title: "Grouped Bar Chart") { key in
      AnyView(GroupedBarChart(
        data: GroupedBarChartData(
          labels: quarters,
          itemNames: ["2023", "2024"],
          groupedValues: [
            [20, 28], [34, 30], [26, 38], [40, 44],
          ]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Stacked Bar Chart") { key in
      AnyView(StackedBarChart(
        data: StackedBarChartData(
          labels: quarters,
          stacks: [
            [12, 8, 6], [16, 10, 8], [14, 12, 10], [20, 14, 9],
          ]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Histogram") { key in
      AnyView(Histogram(
        data: HistogramData(
          dataPoints: [2, 3, 3, 4, 5, 5, 5, 6, 6, 7, 7, 8, 9, 10, 11, 12, 12, 13, 15],
          binCount: 5
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Waterfall Chart") { key in
      AnyView(WaterfallChart(
        data: WaterfallChartData(
          labels: ["Start", "Sales", "Costs", "Tax", "Net"],
          values: [0, 60, -25, -10, 0],
          initialValue: 50
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Pie Chart") { key in
      AnyView(PieChart(data: pieData, replay: key))
    },
    GalleryCard(title: "Donut Chart") { key in
      AnyView(DonutChart(data: pieData, replay: key))
    },
    GalleryCard(title: "Candlestick Chart") { key in
      AnyView(CandlestickChart(
        data: CandlestickData(
          candles: candles,
          movingAverages: [MovingAverage(period: 3, color: p[3])]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Radar Chart") { key in
      AnyView(RadarChart(
        data: [
          RadarChartData(values: ["Speed": 0.8, "Power": 0.6, "Range": 0.9, "Agility": 0.5, "Armor": 0.7]),
          RadarChartData(values: ["Speed": 0.5, "Power": 0.9, "Range": 0.6, "Agility": 0.8, "Armor": 0.4]),
        ],
        replay: key
      ))
    },
    GalleryCard(title: "Scatter Plot") { key in
      AnyView(ScatterPlot(
        data: ScatterPlotData(
          points: [(1, 2), (2, 5), (3, 3), (4, 8), (5, 6), (6, 9), (7, 7)],
          pointColors: p
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Bubble Chart") { key in
      AnyView(BubbleChart(
        data: BubbleChartData(series: [[
          BubbleData(x: 10, y: 20, size: 3, color: p[0]),
          BubbleData(x: 30, y: 40, size: 6, color: p[1]),
          BubbleData(x: 50, y: 25, size: 4, color: p[2]),
          BubbleData(x: 70, y: 60, size: 8, color: p[4]),
        ]]),
        replay: key
      ))
    },
    GalleryCard(title: "Gauge Chart") { key in
      AnyView(GaugeChart(
        data: GaugeData(value: 72, min: 0, max: 100, label: "Score"),
        replay: key
      ))
    },
    GalleryCard(title: "Sankey Chart") { key in
      AnyView(SankeyChart(data: sankeyData, replay: key))
    },
    GalleryCard(title: "Treemap Chart") { key in
      AnyView(TreemapChart(
        data: TreemapData(items: [
          TreemapItem(label: "Alpha", value: 40, color: p[0]),
          TreemapItem(label: "Beta", value: 25, color: p[1]),
          TreemapItem(label: "Gamma", value: 18, color: p[2]),
          TreemapItem(label: "Delta", value: 12, color: p[4]),
          TreemapItem(label: "Eps", value: 8, color: p[3]),
        ]),
        replay: key
      ))
    },
    GalleryCard(title: "Stream Graph Chart") { key in
      AnyView(StreamGraphChart(
        data: StreamData(
          labels: months,
          series: [
            StreamSeries(name: "A", values: [4, 6, 8, 7, 9, 6], color: p[0]),
            StreamSeries(name: "B", values: [3, 4, 6, 8, 7, 9], color: p[1]),
            StreamSeries(name: "C", values: [2, 3, 4, 5, 6, 7], color: p[4]),
          ]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Sunburst Chart") { key in
      AnyView(SunburstChart(
        data: SunburstData(roots: [
          SunburstNode(label: "Web", value: 50, color: p[0], children: [
            SunburstNode(label: "iOS", value: 30, color: p[0]),
            SunburstNode(label: "And", value: 20, color: p[0]),
          ]),
          SunburstNode(label: "API", value: 30, color: p[1], children: [
            SunburstNode(label: "REST", value: 20, color: p[1]),
            SunburstNode(label: "gRPC", value: 10, color: p[1]),
          ]),
          SunburstNode(label: "DB", value: 20, color: p[4], children: [
            SunburstNode(label: "SQL", value: 12, color: p[4]),
            SunburstNode(label: "KV", value: 8, color: p[4]),
          ]),
        ]),
        replay: key
      ))
    },
    GalleryCard(title: "Funnel Chart") { key in
      AnyView(FunnelChart(
        data: FunnelData(stages: [
          FunnelStage(label: "Visits", value: 1000, color: p[0]),
          FunnelStage(label: "Signups", value: 620, color: p[1]),
          FunnelStage(label: "Trials", value: 310, color: p[2]),
          FunnelStage(label: "Paid", value: 120, color: p[4]),
        ]),
        replay: key
      ))
    },
    GalleryCard(title: "Bullet Chart") { key in
      AnyView(BulletChart(
        data: BulletData(metrics: [
          BulletMetric(label: "Revenue", value: 78, target: 85, ranges: [50, 75, 100]),
          BulletMetric(label: "Profit", value: 62, target: 60, ranges: [40, 70, 100], color: p[1]),
        ]),
        replay: key
      ))
    },
    GalleryCard(title: "Box Plot Chart") { key in
      AnyView(BoxPlotChart(
        data: BoxPlotData(groups: [
          BoxGroup(label: "A", min: 5, q1: 12, median: 18, q3: 24, max: 30),
          BoxGroup(label: "B", min: 8, q1: 15, median: 22, q3: 28, max: 38, color: p[1]),
          BoxGroup(label: "C", min: 4, q1: 10, median: 14, q3: 20, max: 26, color: p[4]),
        ]),
        replay: key
      ))
    },
    GalleryCard(title: "Gantt Chart") { key in
      AnyView(GanttChart(
        data: GanttChartData(
          tasks: [
            GanttTask(name: "Design", startMonth: 0, duration: 2),
            GanttTask(name: "Build", startMonth: 2, duration: 3),
            GanttTask(name: "Test", startMonth: 4, duration: 2),
            GanttTask(name: "Ship", startMonth: 6, duration: 1),
          ],
          taskColors: [p[0], p[1], p[2], p[4]]
        ),
        replay: key
      ))
    },
    GalleryCard(title: "Step Line Chart") { key in
      AnyView(StepLineChart(
        data: StepLineChartData(labels: months, values: [10, 10, 25, 18, 32, 28]),
        replay: key
      ))
    },
    GalleryCard(title: "Heatmap") { key in
      AnyView(Heatmap(data: heatmapData, replay: key))
    },
    GalleryCard(title: "Polar Area Chart") { key in
      AnyView(PolarAreaChart(
        data: PolarAreaData(slices: [
          PolarSlice(label: "Mon", value: 8, color: p[0]),
          PolarSlice(label: "Tue", value: 12, color: p[1]),
          PolarSlice(label: "Wed", value: 6, color: p[2]),
          PolarSlice(label: "Thu", value: 15, color: p[3]),
          PolarSlice(label: "Fri", value: 10, color: p[4]),
        ]),
        replay: key
      ))
    },
  ]

  // MARK: - Reusable datasets

  static let pieData = PieChartData(slices: [
    PieChartData.Slice(value: 40, color: p[0], label: "A"),
    PieChartData.Slice(value: 25, color: p[1], label: "B"),
    PieChartData.Slice(value: 20, color: p[2], label: "C"),
    PieChartData.Slice(value: 15, color: p[4], label: "D"),
  ])

  static let candles: [Candle] = [
    Candle(label: "1", open: 20, high: 26, low: 18, close: 24),
    Candle(label: "2", open: 24, high: 28, low: 22, close: 21),
    Candle(label: "3", open: 21, high: 25, low: 19, close: 23),
    Candle(label: "4", open: 23, high: 30, low: 22, close: 29),
    Candle(label: "5", open: 29, high: 32, low: 26, close: 27),
    Candle(label: "6", open: 27, high: 31, low: 25, close: 30),
  ]

  static let sankeyData = SankeyData(
    nodes: [
      SankeyNode(id: "src", label: "Source", column: 0, color: p[0]),
      SankeyNode(id: "a", label: "A", column: 1, color: p[1]),
      SankeyNode(id: "b", label: "B", column: 1, color: p[2]),
      SankeyNode(id: "out", label: "Out", column: 2, color: p[4]),
    ],
    links: [
      SankeyLink(from: "src", to: "a", value: 30),
      SankeyLink(from: "src", to: "b", value: 20),
      SankeyLink(from: "a", to: "out", value: 30),
      SankeyLink(from: "b", to: "out", value: 20),
    ]
  )

  /// GitHub-style contributions over a fixed window: deterministic dates stepped
  /// by day from a constant epoch, with a deterministic count pattern.
  static let heatmapData: ContributionHeatmapData = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    var contributions: [ContributionData] = []
    // A full year of deterministic data with realistic gaps (some empty days).
    for day in 0..<371 {
      guard let date = calendar.date(byAdding: .day, value: day, to: start) else { continue }
      let raw = (day * 13 + (day % 7) * 5 + (day % 11) * 2) % 16
      let count = max(0, raw - 4) // 0...11, with a sprinkling of empty days
      contributions.append(ContributionData(date: date, count: count))
    }
    return ContributionHeatmapData(contributions: contributions)
  }()
}
