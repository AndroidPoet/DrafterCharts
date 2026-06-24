//
//  BubbleChart.swift
//  DrafterCharts
//
//  Scatter of sized bubbles on Cartesian axes. Each bubble's pixel radius is
//  proportional to its `size` relative to the largest bubble; a per-bubble
//  staggered reveal grows radii from zero. Magnitude-based grid steps drive the
//  axis lines and integer tick labels. Bubbles render as a translucent fill
//  under a crisp stroked ring. Mirrors the Compose `BubbleChart` family.
//

import SwiftUI

/// A single bubble: position (`x`, `y`), relative `size`, and a fill color.
public struct BubbleData: Equatable, Sendable {
  public var x: Float
  public var y: Float
  public var size: Float
  public var color: Color

  public init(x: Float, y: Float, size: Float, color: Color = DrafterColors.blue) {
    self.x = x
    self.y = y
    self.size = size
    self.color = color
  }
}

/// Axis value ranges (always anchored at 0, max rounded up to a nice number).
private struct BubbleValueRanges {
  var xMin: Double
  var xMax: Double
  var yMin: Double
  var yMax: Double
}

/// Draws a bubble chart into a canvas with Cartesian axes and a grid.
public struct BubbleChartRenderer: ChartRenderer {
  public let series: [[BubbleData]]
  public init(series: [[BubbleData]]) { self.series = series }

  // Always start at 0; round the max up to a tidy bound (matches Compose).
  private func roundToNiceNumber(_ value: Double) -> Double {
    switch value {
    case ...50: return Double((Int(value + 9) / 10) * 10)
    case ...100: return Double((Int(value + 24) / 25) * 25)
    default: return Double((Int(value + 49) / 50) * 50)
    }
  }

  private func valueRanges() -> BubbleValueRanges {
    let all = series.flatMap { $0 }
    let xMax = roundToNiceNumber(Double(all.map { $0.x }.max() ?? 0))
    let yMax = roundToNiceNumber(Double(all.map { $0.y }.max() ?? 0))
    return BubbleValueRanges(xMin: 0, xMax: xMax, yMin: 0, yMax: yMax)
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let all = series.flatMap { $0 }
    guard !all.isEmpty else { return }

    // Plot origin / extent (mirrors the Compose 40 / 20 / 60 insets).
    let originX: CGFloat = 40
    let originY: CGFloat = size.height - 20
    let chartWidth = size.width - 60
    let chartHeight = size.height - 60
    guard chartWidth > 0, chartHeight > 0 else { return }

    let ranges = valueRanges()
    let xRange = max(ranges.xMax - ranges.xMin, 0.0001)
    let yRange = max(ranges.yMax - ranges.yMin, 0.0001)

    // Magnitude-based grid steps.
    let xStep = ChartAxis.gridStep(forMax: xRange)
    let yStep = ChartAxis.gridStep(forMax: yRange)
    let xLines = max(Int(xRange / xStep), 0)
    let yLines = max(Int(yRange / yStep), 0)

    // Grid lines.
    for i in 0...max(xLines, 0) {
      let value = ranges.xMin + Double(i) * xStep
      let ratio = (value - ranges.xMin) / xRange
      let x = originX + CGFloat(ratio) * chartWidth
      var line = Path()
      line.move(to: CGPoint(x: x, y: originY))
      line.addLine(to: CGPoint(x: x, y: originY - chartHeight))
      context.stroke(line, with: .color(theme.grid), lineWidth: 1)
    }
    for i in 0...max(yLines, 0) {
      let value = ranges.yMin + Double(i) * yStep
      let ratio = (value - ranges.yMin) / yRange
      let y = originY - CGFloat(ratio) * chartHeight
      var line = Path()
      line.move(to: CGPoint(x: originX, y: y))
      line.addLine(to: CGPoint(x: originX + chartWidth, y: y))
      context.stroke(line, with: .color(theme.grid), lineWidth: 1)
    }

    // Axes (x along the bottom, y up the left).
    var axes = Path()
    axes.move(to: CGPoint(x: originX, y: originY))
    axes.addLine(to: CGPoint(x: originX + chartWidth, y: originY))
    axes.move(to: CGPoint(x: originX, y: originY))
    axes.addLine(to: CGPoint(x: originX, y: originY - chartHeight))
    context.stroke(axes, with: .color(theme.label), lineWidth: 1)

    // Axis tick labels (integers, matching Compose `value.toInt()`).
    for i in 0...max(xLines, 0) {
      let value = ranges.xMin + Double(i) * xStep
      let ratio = (value - ranges.xMin) / xRange
      let x = originX + CGFloat(ratio) * chartWidth
      let text = Text("\(Int(value))").font(.system(size: 10)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: x, y: originY + 11), anchor: .center)
    }
    for i in 0...max(yLines, 0) {
      let value = ranges.yMin + Double(i) * yStep
      let ratio = (value - ranges.yMin) / yRange
      let y = originY - CGFloat(ratio) * chartHeight
      let text = Text("\(Int(value))").font(.system(size: 10)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: originX - 5, y: y), anchor: .trailing)
    }

    // Bubbles, with a per-bubble staggered reveal and size-proportional radius.
    let maxBubbleSize = Double(all.map { $0.size }.max() ?? 0)
    guard maxBubbleSize > 0 else { return }
    let scaleFactor = min(chartWidth, chartHeight) / 6

    for (seriesIndex, group) in series.enumerated() {
      for (bubbleIndex, bubble) in group.enumerated() {
        let delay = Double(seriesIndex * group.count + bubbleIndex) * 0.1
        let bubbleProgress = min(max(progress - delay, 0), 1)

        let x = originX + CGFloat(Double(bubble.x) / ranges.xMax) * chartWidth
        let y = originY - CGFloat(Double(bubble.y) / ranges.yMax) * chartHeight
        let scaledSize = CGFloat(Double(bubble.size) / maxBubbleSize) * scaleFactor
        let radius = scaledSize * CGFloat(bubbleProgress)
        guard radius > 0 else { continue }

        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        let circle = Path(ellipseIn: rect)
        context.fill(circle, with: .color(bubble.color.opacity(0.30)))
        context.stroke(circle, with: .color(bubble.color.opacity(0.9)), lineWidth: 2.5)
      }
    }
  }

  public var accessibilityLabel: String { "Bubble chart" }
  public var accessibilityValue: String {
    "\(series.count) series, \(series.reduce(0) { $0 + $1.count }) bubbles"
  }
}

/// A bubble (scatter) chart with magnitude-based axes and a staggered reveal.
public struct BubbleChart: View {
  public let series: [[BubbleData]]
  public var animate: Bool
  public var replay: Int

  public init(series: [[BubbleData]], animate: Bool = true, replay: Int = 0) {
    self.series = series
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: BubbleChartRenderer(series: series), animate: animate, duration: 2.0, replay: replay)
  }
}
