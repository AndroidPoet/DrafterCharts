//
//  ChartRenderTests.swift
//  DrafterChartsTests
//
//  Snapshot-style render tests. Each chart is rendered off-screen at full reveal
//  and asserted to produce a non-trivial amount of drawn content, so a renderer
//  that silently draws nothing (like the Sankey flow bands once did) fails CI.
//  The Sankey case additionally asserts content *between* the node columns, which
//  is exactly the region the missing flow ribbons occupy.
//

import SwiftUI
import XCTest
@testable import DrafterCharts

@MainActor
final class ChartRenderTests: XCTestCase {
  private let size = CGSize(width: 320, height: 240)
  private let palette = DrafterColors.palette
  private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
  private let quarters = ["Q1", "Q2", "Q3", "Q4"]

  /// Asserts the rendered chart fills at least `minRatio` of its pixels with
  /// non-background content — a guard against fully blank / broken renders.
  private func assertNotBlank(
    _ bitmap: Bitmap,
    minRatio: Double = 0.004,
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let drawn = bitmap.contentPixels()
    let ratio = Double(drawn) / Double(bitmap.pixelCount)
    XCTAssertGreaterThan(
      ratio, minRatio,
      "\(message): only \(drawn) drawn pixels (\(ratio) of frame)",
      file: file, line: line
    )
  }

  // MARK: - Lines & areas

  func testAreaChartRenders() throws {
    let chart = AreaChart(
      data: AreaChartData(labels: months, values: [12, 18, 9, 24, 20, 30]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "AreaChart")
  }

  func testLineChartRenders() throws {
    let chart = LineChart(
      data: SimpleLineChartData(labels: months, values: [40, 65, 50, 80, 70, 95]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "LineChart")
  }

  func testStepLineChartRenders() throws {
    let chart = StepLineChart(
      data: StepLineChartData(labels: months, values: [10, 10, 25, 18, 32, 28]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "StepLineChart")
  }

  func testStackedLineChartRenders() throws {
    let chart = StackedLineChart(
      data: StackedLineChartData(
        labels: months,
        stacks: [[10, 8], [14, 10], [12, 14], [20, 12], [18, 16], [24, 14]],
        colors: [palette[2], palette[4]]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "StackedLineChart")
  }

  func testStreamGraphChartRenders() throws {
    let chart = StreamGraphChart(
      data: StreamData(
        labels: months,
        series: [
          StreamSeries(name: "A", values: [4, 6, 8, 7, 9, 6], color: palette[0]),
          StreamSeries(name: "B", values: [3, 4, 6, 8, 7, 9], color: palette[1]),
        ]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "StreamGraphChart")
  }

  // MARK: - Bars

  func testSimpleBarChartRenders() throws {
    let chart = SimpleBarChart(
      data: SimpleBarChartData(labels: quarters, values: [24, 38, 30, 46]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "SimpleBarChart")
  }

  func testStackedBarChartRenders() throws {
    let chart = StackedBarChart(
      data: StackedBarChartData(labels: quarters, stacks: [[12, 8, 6], [16, 10, 8], [14, 12, 10], [20, 14, 9]]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "StackedBarChart")
  }

  func testHistogramRenders() throws {
    let chart = Histogram(
      data: HistogramData(dataPoints: [2, 3, 3, 4, 5, 5, 6, 7, 8, 9, 10, 12, 13, 15], binCount: 5),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Histogram")
  }

  func testWaterfallChartRenders() throws {
    let chart = WaterfallChart(
      data: WaterfallChartData(labels: ["Start", "Sales", "Costs", "Net"], values: [0, 60, -25, 0], initialValue: 50),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "WaterfallChart")
  }

  func testBulletChartRenders() throws {
    let chart = BulletChart(
      data: BulletData(metrics: [BulletMetric(label: "Revenue", value: 78, target: 85, ranges: [50, 75, 100])]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "BulletChart")
  }

  func testGanttChartRenders() throws {
    let chart = GanttChart(
      data: GanttChartData(
        tasks: [GanttTask(name: "Design", startMonth: 0, duration: 2), GanttTask(name: "Build", startMonth: 2, duration: 3)],
        taskColors: [palette[0], palette[1]]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "GanttChart")
  }

  // MARK: - Part-to-whole & radial

  func testPieChartRenders() throws {
    let chart = PieChart(data: pieData, animate: false)
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "PieChart")
  }

  func testDonutChartRenders() throws {
    let chart = DonutChart(data: pieData, animate: false)
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "DonutChart")
  }

  func testPolarAreaChartRenders() throws {
    let chart = PolarAreaChart(
      data: PolarAreaData(slices: [
        PolarSlice(label: "Mon", value: 8, color: palette[0]),
        PolarSlice(label: "Tue", value: 12, color: palette[1]),
        PolarSlice(label: "Wed", value: 6, color: palette[2]),
      ]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "PolarAreaChart")
  }

  func testSunburstChartRenders() throws {
    let chart = SunburstChart(
      data: SunburstData(roots: [
        SunburstNode(label: "Web", value: 50, color: palette[0], children: [
          SunburstNode(label: "iOS", value: 30, color: palette[0]),
          SunburstNode(label: "And", value: 20, color: palette[0]),
        ]),
        SunburstNode(label: "API", value: 30, color: palette[1], children: []),
      ]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "SunburstChart")
  }

  func testFunnelChartRenders() throws {
    let chart = FunnelChart(
      data: FunnelData(stages: [
        FunnelStage(label: "Visits", value: 1000, color: palette[0]),
        FunnelStage(label: "Signups", value: 620, color: palette[1]),
        FunnelStage(label: "Paid", value: 120, color: palette[4]),
      ]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "FunnelChart")
  }

  func testTreemapChartRenders() throws {
    let chart = TreemapChart(
      data: TreemapData(items: [
        TreemapItem(label: "Alpha", value: 40, color: palette[0]),
        TreemapItem(label: "Beta", value: 25, color: palette[1]),
        TreemapItem(label: "Gamma", value: 18, color: palette[2]),
      ]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "TreemapChart")
  }

  func testRadarChartRenders() throws {
    let chart = RadarChart(
      data: [RadarChartData(values: ["Speed": 0.8, "Power": 0.6, "Range": 0.9, "Agility": 0.5, "Armor": 0.7])],
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "RadarChart")
  }

  func testGaugeChartRenders() throws {
    let chart = GaugeChart(data: GaugeData(value: 72, min: 0, max: 100, label: "Score"), animate: false)
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "GaugeChart")
  }

  // MARK: - Distribution

  func testScatterPlotRenders() throws {
    let chart = ScatterPlot(
      data: ScatterPlotData(points: [(1, 2), (2, 5), (3, 3), (4, 8), (5, 6), (6, 9)], pointColors: palette),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "ScatterPlot")
  }

  func testBubbleChartRenders() throws {
    let chart = BubbleChart(
      data: BubbleChartData(series: [[
        BubbleData(x: 10, y: 20, size: 3, color: palette[0]),
        BubbleData(x: 50, y: 25, size: 5, color: palette[2]),
        BubbleData(x: 70, y: 60, size: 8, color: palette[4]),
      ]]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "BubbleChart")
  }

  func testBoxPlotChartRenders() throws {
    let chart = BoxPlotChart(
      data: BoxPlotData(groups: [
        BoxGroup(label: "A", min: 5, q1: 12, median: 18, q3: 24, max: 30),
        BoxGroup(label: "B", min: 8, q1: 15, median: 22, q3: 28, max: 38, color: palette[1]),
      ]),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "BoxPlotChart")
  }

  func testCandlestickChartRenders() throws {
    let chart = CandlestickChart(
      data: CandlestickData(
        candles: [
          Candle(label: "1", open: 20, high: 26, low: 18, close: 24),
          Candle(label: "2", open: 24, high: 28, low: 22, close: 21),
          Candle(label: "3", open: 21, high: 25, low: 19, close: 23),
        ],
        movingAverages: [MovingAverage(period: 2, color: palette[3])]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "CandlestickChart")
  }

  func testHeatmapRenders() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    var contributions: [ContributionData] = []
    for day in 0..<120 {
      guard let date = calendar.date(byAdding: .day, value: day, to: start) else { continue }
      contributions.append(ContributionData(date: date, count: (day * 7) % 12))
    }
    let chart = Heatmap(data: ContributionHeatmapData(contributions: contributions), animate: false)
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Heatmap")
  }

  // MARK: - Convenience (values-first) initializers

  func testValuesFirstInitializersRender() throws {
    assertNotBlank(try RenderHarness.bitmap(LineChart(values: [40, 65, 50, 80], animate: false), size: size), "LineChart(values:)")
    assertNotBlank(try RenderHarness.bitmap(AreaChart(values: [12, 18, 9, 24], animate: false), size: size), "AreaChart(values:)")
    assertNotBlank(try RenderHarness.bitmap(SimpleBarChart(values: [24, 38, 30, 46], animate: false), size: size), "SimpleBarChart(values:)")
    assertNotBlank(try RenderHarness.bitmap(StepLineChart(values: [10, 25, 18, 32], animate: false), size: size), "StepLineChart(values:)")
  }

  // MARK: - Sankey (regression: flow bands must render)

  func testSankeyChartRenders() throws {
    let chart = SankeyChart(data: sankeyData, animate: false)
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "SankeyChart")
  }

  /// The flow ribbons live in the horizontal gaps *between* the node columns.
  /// A blank gap means the bands silently failed to draw (the original bug), so
  /// assert there is substantial content in the strip between column 0 and
  /// column 1.
  func testSankeyDrawsFlowBandsBetweenColumns() throws {
    let renderSize = CGSize(width: 400, height: 300)
    let bitmap = try RenderHarness.bitmap(SankeyChart(data: sankeyData, animate: false), size: renderSize)

    // Columns sit at ~8% (left), ~50% (middle) and ~92% (right) of the width.
    // The strip from 18%..42% is purely band territory — no node bars there.
    let gap = CGRect(
      x: renderSize.width * 0.18,
      y: 0,
      width: renderSize.width * 0.24,
      height: renderSize.height
    )
    let bandPixels = bitmap.contentPixels(in: gap)
    XCTAssertGreaterThan(
      bandPixels, 300,
      "Sankey flow bands missing: the gap between columns has only \(bandPixels) drawn pixels"
    )
  }

  // MARK: - Shared fixtures

  private var pieData: PieChartData {
    PieChartData(slices: [
      PieChartData.Slice(value: 40, color: palette[0], label: "A"),
      PieChartData.Slice(value: 25, color: palette[1], label: "B"),
      PieChartData.Slice(value: 20, color: palette[2], label: "C"),
      PieChartData.Slice(value: 15, color: palette[4], label: "D"),
    ])
  }

  private var sankeyData: SankeyData {
    SankeyData(
      nodes: [
        SankeyNode(id: "src", label: "Source", column: 0, color: palette[0]),
        SankeyNode(id: "a", label: "A", column: 1, color: palette[1]),
        SankeyNode(id: "b", label: "B", column: 1, color: palette[2]),
        SankeyNode(id: "out", label: "Out", column: 2, color: palette[4]),
      ],
      links: [
        SankeyLink(from: "src", to: "a", value: 30),
        SankeyLink(from: "src", to: "b", value: 20),
        SankeyLink(from: "a", to: "out", value: 30),
        SankeyLink(from: "b", to: "out", value: 20),
      ]
    )
  }
}
