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
          galleryCards(replay: replayKey)
        }
        .padding(16)
      }
      .drafterTheme(.light)
    }
    .frame(minWidth: 720, minHeight: 560)
  }

  // Concrete, non-type-erased cards. Grouped in tens because `@ViewBuilder`
  // blocks accept at most ten direct children; each `Group` is one child.
  @ViewBuilder
  private func galleryCards(replay: Int) -> some View {
    galleryCardsLines(replay: replay)
    galleryCardsMid(replay: replay)
    galleryCardsRest(replay: replay)
  }

  @ViewBuilder
  private func galleryCardsLines(replay: Int) -> some View {
    Group {
      ChartCard(title: "Area Chart") {
        AreaChart(data: AreaChartData(labels: SampleData.months, values: [12, 18, 9, 24, 20, 30]), replay: replay)
      }
      ChartCard(title: "Line Chart") {
        LineChart(data: SimpleLineChartData(labels: SampleData.months, values: [40, 65, 50, 80, 70, 95]), replay: replay)
      }
      ChartCard(title: "Grouped Line Chart") {
        GroupedLineChart(
          data: GroupedLineChartData(
            labels: SampleData.months,
            itemNames: ["A", "B"],
            groupedValues: [[30, 20], [45, 35], [40, 50], [70, 45], [60, 65], [85, 55]],
            colors: [SampleData.p[0], SampleData.p[1]]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Stacked Line Chart") {
        StackedLineChart(
          data: StackedLineChartData(
            labels: SampleData.months,
            stacks: [[10, 8], [14, 10], [12, 14], [20, 12], [18, 16], [24, 14]],
            colors: [SampleData.p[2], SampleData.p[4]]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Simple Bar Chart") {
        SimpleBarChart(data: SimpleBarChartData(labels: SampleData.quarters, values: [24, 38, 30, 46]), replay: replay)
      }
      ChartCard(title: "Grouped Bar Chart") {
        GroupedBarChart(
          data: GroupedBarChartData(
            labels: SampleData.quarters,
            itemNames: ["2023", "2024"],
            groupedValues: [[20, 28], [34, 30], [26, 38], [40, 44]]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Stacked Bar Chart") {
        StackedBarChart(
          data: StackedBarChartData(
            labels: SampleData.quarters,
            stacks: [[12, 8, 6], [16, 10, 8], [14, 12, 10], [20, 14, 9]]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Histogram") {
        Histogram(
          data: HistogramData(
            dataPoints: [2, 3, 3, 4, 5, 5, 5, 6, 6, 7, 7, 8, 9, 10, 11, 12, 12, 13, 15],
            binCount: 5
          ),
          replay: replay
        )
      }
      ChartCard(title: "Waterfall Chart") {
        WaterfallChart(
          data: WaterfallChartData(
            labels: ["Start", "Sales", "Costs", "Tax", "Net"],
            values: [0, 60, -25, -10, 0],
            initialValue: 50
          ),
          replay: replay
        )
      }
      ChartCard(title: "Pie Chart") {
        PieChart(data: SampleData.pieData, replay: replay)
      }
    }
  }

  @ViewBuilder
  private func galleryCardsMid(replay: Int) -> some View {
    Group {
      ChartCard(title: "Donut Chart") {
        DonutChart(data: SampleData.pieData, replay: replay)
      }
      ChartCard(title: "Candlestick Chart") {
        CandlestickChart(
          data: CandlestickData(candles: SampleData.candles, movingAverages: [MovingAverage(period: 3, color: SampleData.p[3])]),
          replay: replay
        )
      }
      ChartCard(title: "Radar Chart") {
        RadarChart(
          data: [
            RadarChartData(values: ["Speed": 0.8, "Power": 0.6, "Range": 0.9, "Agility": 0.5, "Armor": 0.7]),
            RadarChartData(values: ["Speed": 0.5, "Power": 0.9, "Range": 0.6, "Agility": 0.8, "Armor": 0.4]),
          ],
          replay: replay
        )
      }
      ChartCard(title: "Scatter Plot") {
        ScatterPlot(
          data: ScatterPlotData(points: [(1, 2), (2, 5), (3, 3), (4, 8), (5, 6), (6, 9), (7, 7)], pointColors: SampleData.p),
          replay: replay
        )
      }
      ChartCard(title: "Bubble Chart") {
        BubbleChart(
          data: BubbleChartData(series: [[
            BubbleData(x: 10, y: 20, size: 3, color: SampleData.p[0]),
            BubbleData(x: 30, y: 40, size: 6, color: SampleData.p[1]),
            BubbleData(x: 50, y: 25, size: 4, color: SampleData.p[2]),
            BubbleData(x: 70, y: 60, size: 8, color: SampleData.p[4]),
          ]]),
          replay: replay
        )
      }
      ChartCard(title: "Gauge Chart") {
        GaugeChart(data: GaugeData(value: 72, min: 0, max: 100, label: "Score"), replay: replay)
      }
      ChartCard(title: "Sankey Chart") {
        SankeyChart(data: SampleData.sankeyData, replay: replay)
      }
      ChartCard(title: "Treemap Chart") {
        TreemapChart(
          data: TreemapData(items: [
            TreemapItem(label: "Alpha", value: 40, color: SampleData.p[0]),
            TreemapItem(label: "Beta", value: 25, color: SampleData.p[1]),
            TreemapItem(label: "Gamma", value: 18, color: SampleData.p[2]),
            TreemapItem(label: "Delta", value: 12, color: SampleData.p[4]),
            TreemapItem(label: "Eps", value: 8, color: SampleData.p[3]),
          ]),
          replay: replay
        )
      }
      ChartCard(title: "Stream Graph Chart") {
        StreamGraphChart(
          data: StreamData(
            labels: SampleData.months,
            series: [
              StreamSeries(name: "A", values: [4, 6, 8, 7, 9, 6], color: SampleData.p[0]),
              StreamSeries(name: "B", values: [3, 4, 6, 8, 7, 9], color: SampleData.p[1]),
              StreamSeries(name: "C", values: [2, 3, 4, 5, 6, 7], color: SampleData.p[4]),
            ]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Sunburst Chart") {
        SunburstChart(
          data: SunburstData(roots: [
            SunburstNode(label: "Web", value: 50, color: SampleData.p[0], children: [
              SunburstNode(label: "iOS", value: 30, color: SampleData.p[0]),
              SunburstNode(label: "And", value: 20, color: SampleData.p[0]),
            ]),
            SunburstNode(label: "API", value: 30, color: SampleData.p[1], children: [
              SunburstNode(label: "REST", value: 20, color: SampleData.p[1]),
              SunburstNode(label: "gRPC", value: 10, color: SampleData.p[1]),
            ]),
            SunburstNode(label: "DB", value: 20, color: SampleData.p[4], children: [
              SunburstNode(label: "SQL", value: 12, color: SampleData.p[4]),
              SunburstNode(label: "KV", value: 8, color: SampleData.p[4]),
            ]),
          ]),
          replay: replay
        )
      }
    }
  }

  @ViewBuilder
  private func galleryCardsRest(replay: Int) -> some View {
    Group {
      ChartCard(title: "Funnel Chart") {
        FunnelChart(
          data: FunnelData(stages: [
            FunnelStage(label: "Visits", value: 1000, color: SampleData.p[0]),
            FunnelStage(label: "Signups", value: 620, color: SampleData.p[1]),
            FunnelStage(label: "Trials", value: 310, color: SampleData.p[2]),
            FunnelStage(label: "Paid", value: 120, color: SampleData.p[4]),
          ]),
          replay: replay
        )
      }
      ChartCard(title: "Bullet Chart") {
        BulletChart(
          data: BulletData(metrics: [
            BulletMetric(label: "Revenue", value: 78, target: 85, ranges: [50, 75, 100]),
            BulletMetric(label: "Profit", value: 62, target: 60, ranges: [40, 70, 100], color: SampleData.p[1]),
          ]),
          replay: replay
        )
      }
      ChartCard(title: "Box Plot Chart") {
        BoxPlotChart(
          data: BoxPlotData(groups: [
            BoxGroup(label: "A", min: 5, q1: 12, median: 18, q3: 24, max: 30),
            BoxGroup(label: "B", min: 8, q1: 15, median: 22, q3: 28, max: 38, color: SampleData.p[1]),
            BoxGroup(label: "C", min: 4, q1: 10, median: 14, q3: 20, max: 26, color: SampleData.p[4]),
          ]),
          replay: replay
        )
      }
      ChartCard(title: "Gantt Chart") {
        GanttChart(
          data: GanttChartData(
            tasks: [
              GanttTask(name: "Design", startMonth: 0, duration: 2),
              GanttTask(name: "Build", startMonth: 2, duration: 3),
              GanttTask(name: "Test", startMonth: 4, duration: 2),
              GanttTask(name: "Ship", startMonth: 6, duration: 1),
            ],
            taskColors: [SampleData.p[0], SampleData.p[1], SampleData.p[2], SampleData.p[4]]
          ),
          replay: replay
        )
      }
      ChartCard(title: "Step Line Chart") {
        StepLineChart(data: StepLineChartData(labels: SampleData.months, values: [10, 10, 25, 18, 32, 28]), replay: replay)
      }
      ChartCard(title: "Heatmap") {
        Heatmap(data: SampleData.heatmapData, replay: replay)
      }
      ChartCard(title: "Polar Area Chart") {
        PolarAreaChart(
          data: PolarAreaData(slices: [
            PolarSlice(label: "Mon", value: 8, color: SampleData.p[0]),
            PolarSlice(label: "Tue", value: 12, color: SampleData.p[1]),
            PolarSlice(label: "Wed", value: 6, color: SampleData.p[2]),
            PolarSlice(label: "Thu", value: 15, color: SampleData.p[3]),
            PolarSlice(label: "Fri", value: 10, color: SampleData.p[4]),
          ]),
          replay: replay
        )
      }
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Drafter Charts")
          .font(.title.bold())
        Text("SwiftUI demo gallery — \(SampleData.chartCount) chart types")
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

private enum SampleData {

  /// Number of charts shown in the gallery (kept in sync with `galleryCards`).
  static let chartCount = 27

  // A fixed palette pulled from the library for legible multi-series charts.
  static let p = DrafterColors.palette

  // Shared deterministic axes.
  static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
  static let quarters = ["Q1", "Q2", "Q3", "Q4"]

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
