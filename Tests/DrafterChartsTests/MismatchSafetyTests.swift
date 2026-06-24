//
//  MismatchSafetyTests.swift
//  DrafterChartsTests
//
//  Charts take parallel arrays (labels / values / colors) that callers can pass
//  with mismatched lengths. These tests feed deliberately-malformed data and
//  assert the renderer neither crashes nor produces ghost columns — element
//  counts are driven by the value arrays, and label/color lookups are bounds-safe.
//

import SwiftUI
import XCTest
@testable import DrafterCharts

@MainActor
final class MismatchSafetyTests: XCTestCase {
  private let size = CGSize(width: 320, height: 240)
  private let palette = DrafterColors.palette

  private func assertNotBlank(
    _ bitmap: Bitmap,
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let ratio = Double(bitmap.contentPixels()) / Double(bitmap.pixelCount)
    XCTAssertGreaterThan(ratio, 0.002, "\(message): rendered effectively blank (\(ratio))", file: file, line: line)
  }

  // MARK: - Waterfall: Start/Total bars + the original 4-label/3-value example

  func testWaterfallStartAndTotalBarsRenderUsersExample() throws {
    // The exact snippet that originally confused the labels: 4 labels, 3 deltas.
    let chart = WaterfallChart(
      data: WaterfallChartData(
        labels: ["Start", "Revenue", "Cost", "Profit"],
        values: [50, -20, 30],
        initialValue: 100,
        showInitialBar: true,
        showTotalBar: true
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Waterfall Start/Total")
  }

  func testWaterfallLeadingStartBarHasContent() throws {
    let renderSize = CGSize(width: 400, height: 300)
    let chart = WaterfallChart(
      data: WaterfallChartData(
        labels: ["Start", "A", "B"],
        values: [40, -15],
        initialValue: 80,
        showInitialBar: true
      ),
      animate: false
    )
    let bitmap = try RenderHarness.bitmap(chart, size: renderSize)
    // The Start bar is the leftmost column; assert the left ~22% strip (past the
    // y-axis labels) has a tall bar rather than being empty.
    let leftStrip = CGRect(x: renderSize.width * 0.10, y: 0, width: renderSize.width * 0.18, height: renderSize.height)
    XCTAssertGreaterThan(bitmap.contentPixels(in: leftStrip), 200, "Waterfall Start bar missing")
  }

  func testWaterfallMoreLabelsThanValuesDoesNotCrash() throws {
    // Five labels, two deltas, no bookend bars: must render two bars, no ghosts.
    let chart = WaterfallChart(
      data: WaterfallChartData(
        labels: ["a", "b", "c", "d", "e"],
        values: [20, -5],
        initialValue: 10
      ),
      animate: false
    )
    _ = try RenderHarness.bitmap(chart, size: size) // returning a bitmap == no crash
  }

  // MARK: - Single-series: labels vs values mismatch

  func testAreaAndLineTolerateMismatchedLabels() throws {
    let values: [Float] = [12, 18, 9, 24, 20]
    let tooFew = ["Jan", "Feb"]
    let tooMany = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"]

    assertNotBlank(try RenderHarness.bitmap(AreaChart(values: values, labels: tooFew, animate: false), size: size), "Area few labels")
    assertNotBlank(try RenderHarness.bitmap(AreaChart(values: values, labels: tooMany, animate: false), size: size), "Area many labels")
    assertNotBlank(try RenderHarness.bitmap(LineChart(values: values, labels: tooFew, animate: false), size: size), "Line few labels")
    assertNotBlank(try RenderHarness.bitmap(StepLineChart(values: values, labels: tooMany, animate: false), size: size), "Step many labels")
  }

  // MARK: - Bars: labels/colors mismatch

  func testSimpleBarToleratesMismatchedLabelsAndColors() throws {
    let chart = SimpleBarChart(
      data: SimpleBarChartData(
        labels: ["only", "two"],            // fewer than values
        values: [10, 20, 30, 40],
        colors: [palette[0]]                // fewer than values
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "SimpleBar mismatch")
  }

  func testGroupedAndStackedBarsTolerateRaggedRows() throws {
    let grouped = GroupedBarChart(
      data: GroupedBarChartData(
        labels: ["Q1", "Q2", "Q3"],
        itemNames: ["A", "B", "C"],         // more series than some rows provide
        groupedValues: [[10, 20], [30], [15, 25, 35]],
        colors: [palette[0]]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(grouped, size: size), "Grouped ragged")

    let stacked = StackedBarChart(
      data: StackedBarChartData(
        labels: ["Q1"],                      // fewer labels than stacks
        stacks: [[5, 8, 6], [10, 4], [7]],
        colors: [palette[1]]
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(stacked, size: size), "Stacked ragged")
  }

  // MARK: - Multi-series & color-array mismatch

  func testGroupedLineToleratesColorAndRowMismatch() throws {
    let chart = GroupedLineChart(
      data: GroupedLineChartData(
        labels: ["Jan", "Feb", "Mar"],
        itemNames: ["A", "B"],
        groupedValues: [[30, 20], [45], [40, 50]], // ragged middle row
        colors: []                                  // no colors at all
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "GroupedLine mismatch")
  }

  func testScatterToleratesPointColorMismatch() throws {
    let chart = ScatterPlot(
      data: ScatterPlotData(
        points: [(1, 2), (2, 5), (3, 3), (4, 8)],
        pointColors: [palette[0]]            // one color, four points
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Scatter color mismatch")
  }

  func testRadarToleratesColorMismatchAndDifferingAxes() throws {
    let chart = RadarChart(
      data: [
        RadarChartData(values: ["Speed": 0.8, "Power": 0.6, "Range": 0.9]),
        RadarChartData(values: ["Speed": 0.5, "Power": 0.9]), // missing an axis
      ],
      colors: []                              // no colors
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Radar mismatch")
  }

  func testStreamGraphToleratesRaggedSeries() throws {
    let chart = StreamGraphChart(
      data: StreamData(
        labels: ["Jan", "Feb", "Mar", "Apr"],
        series: [
          StreamSeries(name: "A", values: [4, 6, 8, 7], color: palette[0]),
          StreamSeries(name: "B", values: [3, 4], color: palette[1]), // short series
        ]
      ),
      animate: false
    )
    _ = try RenderHarness.bitmap(chart, size: size) // no crash on ragged series
  }

  func testGanttToleratesColorMismatch() throws {
    let chart = GanttChart(
      data: GanttChartData(
        tasks: [
          GanttTask(name: "Design", startMonth: 0, duration: 2),
          GanttTask(name: "Build", startMonth: 2, duration: 3),
          GanttTask(name: "Ship", startMonth: 5, duration: 1),
        ],
        taskColors: [palette[0]]              // one color, three tasks
      ),
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Gantt color mismatch")
  }
}
