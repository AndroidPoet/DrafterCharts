//
//  MismatchSafetyTests.swift
//  DrafterChartsTests
//
//  With the point-based API, a label can no longer desync from its value and a
//  color can't index past its data — those mismatches are unrepresentable, so
//  they need no test. What remains is multi-series data where each `ChartSeries`
//  may carry a different number of values (ragged), and empty input. These tests
//  feed those edges and assert the renderer never crashes or draws garbage.
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

  // MARK: - Waterfall Start / Total (the example that originally confused labels)

  func testWaterfallStartAndTotalRenders() throws {
    let chart = WaterfallChart(
      steps: [WaterfallStep("Revenue", 50), WaterfallStep("Cost", -20), WaterfallStep("Profit", 30)],
      initialValue: 100,
      startLabel: "Start",
      totalLabel: "Total",
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Waterfall Start/Total")
  }

  func testWaterfallLeadingStartBarHasContent() throws {
    let renderSize = CGSize(width: 400, height: 300)
    let chart = WaterfallChart(
      steps: [WaterfallStep("A", 40), WaterfallStep("B", -15)],
      initialValue: 80,
      startLabel: "Start",
      animate: false
    )
    let bitmap = try RenderHarness.bitmap(chart, size: renderSize)
    // The Start bar is the leftmost column; assert the left strip (past the
    // y-axis labels) has a tall bar rather than being empty.
    let leftStrip = CGRect(x: renderSize.width * 0.10, y: 0, width: renderSize.width * 0.18, height: renderSize.height)
    XCTAssertGreaterThan(bitmap.contentPixels(in: leftStrip), 200, "Waterfall Start bar missing")
  }

  // MARK: - Ragged multi-series (series of differing value lengths)

  func testGroupedLineRaggedSeriesDoesNotCrash() throws {
    let chart = GroupedLineChart(
      series: [
        ChartSeries(name: "A", color: palette[0], values: [30, 20, 40, 70]),
        ChartSeries(name: "B", color: palette[1], values: [45, 35]),        // shorter
      ],
      categories: ["Jan", "Feb", "Mar", "Apr"],
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "GroupedLine ragged")
  }

  func testGroupedBarRaggedSeriesDoesNotCrash() throws {
    let chart = GroupedBarChart(
      series: [
        ChartSeries(name: "A", color: palette[0], values: [10, 20, 30]),
        ChartSeries(name: "B", color: palette[1], values: [15]),            // shorter
        ChartSeries(name: "C", color: palette[2], values: [25, 35, 18, 22]), // longer
      ],
      categories: ["Q1", "Q2", "Q3"],
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "GroupedBar ragged")
  }

  func testStackedBarRaggedSeriesDoesNotCrash() throws {
    let chart = StackedBarChart(
      series: [
        ChartSeries(color: palette[0], values: [5, 8, 6]),
        ChartSeries(color: palette[1], values: [10, 4]),                    // shorter
        ChartSeries(color: palette[2], values: [7]),                       // shorter still
      ],
      categories: ["Q1", "Q2", "Q3"],
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "StackedBar ragged")
  }

  func testStreamGraphRaggedSeriesDoesNotCrash() throws {
    let chart = StreamGraphChart(
      series: [
        ChartSeries(name: "A", color: palette[0], values: [4, 6, 8, 7]),
        ChartSeries(name: "B", color: palette[1], values: [3, 4]),          // shorter
      ],
      categories: ["Jan", "Feb", "Mar", "Apr"],
      animate: false
    )
    _ = try RenderHarness.bitmap(chart, size: size) // returning a bitmap == no crash
  }

  func testFewerCategoriesThanValuesDoesNotCrash() throws {
    // Categories shorter than the series — extra points simply render unlabeled.
    let chart = GroupedBarChart(
      series: [ChartSeries(name: "A", color: palette[0], values: [10, 20, 30, 40, 50])],
      categories: ["only", "two"],
      animate: false
    )
    assertNotBlank(try RenderHarness.bitmap(chart, size: size), "Few categories")
  }

  // MARK: - Empty input

  func testEmptyInputDoesNotCrash() throws {
    _ = try RenderHarness.bitmap(AreaChart(values: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(LineChart(values: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(SimpleBarChart(values: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(GroupedLineChart(series: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(StackedBarChart(series: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(ScatterPlot(points: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(RadarChart(series: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(StreamGraphChart(series: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(GanttChart(tasks: [], animate: false), size: size)
    _ = try RenderHarness.bitmap(
      WaterfallChart(steps: [], initialValue: 0, animate: false), size: size
    )
  }
}
