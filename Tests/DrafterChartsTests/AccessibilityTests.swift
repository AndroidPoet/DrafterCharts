//
//  AccessibilityTests.swift
//  DrafterChartsTests
//
//  A `Canvas` is opaque to VoiceOver, so every renderer overrides
//  `accessibilityLabel` (the chart kind) and `accessibilityValue` (a data
//  summary). These tests assert each renderer names itself and reads its data
//  back — never falling through to the empty protocol defaults — so a chart can
//  never ship silently invisible to assistive technology.
//

import SwiftUI
import XCTest
@testable import DrafterCharts

@MainActor
final class AccessibilityTests: XCTestCase {
  private let palette = DrafterColors.palette

  func testRenderersExposeMeaningfulLabels() {
    let cases: [(ChartRenderer, String)] = [
      (AreaChartRenderer(points: [ChartPoint("Jan", 40), ChartPoint("Feb", 65)]), "Area chart"),
      (LineChartRenderer(points: [ChartPoint("Jan", 40), ChartPoint("Feb", 65)]), "Line chart"),
      (SimpleBarChartRenderer(bars: [BarItem("A", 10), BarItem("B", 20)]), "Bar chart"),
      (PieChartRenderer(slices: [PieSlice(value: 3, color: palette[0], label: "X")]), "Pie chart"),
      (GaugeChartRenderer(value: 72, min: 0, max: 100, label: "Score"), "Gauge"),
      (FunnelChartRenderer(stages: [FunnelStage(label: "Visits", value: 1000, color: palette[0])]), "Funnel chart"),
      (
        SankeyChartRenderer(
          nodes: [SankeyNode(id: "a", label: "A", column: 0, color: palette[0])],
          links: []
        ),
        "Sankey diagram"
      ),
      (
        CandlestickChartRenderer(
          candles: [Candle(label: "D1", open: 10, high: 14, low: 8, close: 12)]
        ),
        "Candlestick chart"
      ),
      (TreemapChartRenderer(items: [TreemapItem(label: "Alpha", value: 40, color: palette[0])]), "Treemap"),
      (PolarAreaChartRenderer(slices: [PolarSlice(label: "Mon", value: 8, color: palette[0])]), "Polar area chart"),
    ]

    for (renderer, expected) in cases {
      XCTAssertEqual(renderer.accessibilityLabel, expected)
      XCTAssertNotEqual(renderer.accessibilityLabel, "Chart", "\(expected) fell through to the default label")
      XCTAssertFalse(
        renderer.accessibilityValue.isEmpty,
        "\(expected) has an empty accessibilityValue — VoiceOver would announce no data"
      )
    }
  }

  func testValueSummaryReadsBackTheData() {
    let area = AreaChartRenderer(points: [ChartPoint("Jan", 40), ChartPoint("Feb", 65)])
    XCTAssertTrue(area.accessibilityValue.contains("Jan 40"), "Area summary should read its first point")
    XCTAssertTrue(area.accessibilityValue.contains("2 points"), "Area summary should report its point count")

    let gauge = GaugeChartRenderer(value: 72, min: 0, max: 100, label: "Score")
    XCTAssertTrue(gauge.accessibilityValue.contains("72"), "Gauge summary should read its value")
  }

  func testEmptyRenderersDegradeGracefully() {
    XCTAssertEqual(AreaChartRenderer(points: []).accessibilityValue, "No data")
    XCTAssertEqual(PieChartRenderer(slices: []).accessibilityValue, "No data")
    XCTAssertEqual(TreemapChartRenderer(items: []).accessibilityValue, "No data")
  }

  func testNumberFormatterTrimsTrailingZeros() {
    XCTAssertEqual(AccessibilityFormat.number(40), "40")
    XCTAssertEqual(AccessibilityFormat.number(3.5), "3.5")
    XCTAssertEqual(AccessibilityFormat.number(3.0), "3")
  }
}
