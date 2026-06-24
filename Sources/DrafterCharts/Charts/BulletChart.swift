//
//  BulletChart.swift
//  DrafterCharts
//
//  Bullet chart: a compact KPI display where each metric stacks vertically as a
//  horizontal track. Behind the measure sits a set of qualitative range bands
//  (translucent tint, increasing opacity), a rounded value bar that grows from
//  the left, and a vertical target marker. The label sits in a left gutter and
//  the formatted value floats above the row's end.
//

import SwiftUI

/// A single bullet-chart metric: a featured `value`, a `target` to beat, and a
/// set of qualitative `ranges` (band end-values) drawn as the backdrop.
public struct BulletMetric: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var target: Float
  public var ranges: [Float]
  public var color: Color

  public init(label: String, value: Float, target: Float, ranges: [Float], color: Color = DrafterColors.indigo) {
    self.label = label
    self.value = value
    self.target = target
    self.ranges = ranges
    self.color = color
  }
}

/// Data for a `BulletChart`: one or more metrics stacked vertically.
public struct BulletData: Equatable, Sendable {
  public var metrics: [BulletMetric]

  public init(metrics: [BulletMetric]) {
    self.metrics = metrics
  }
}

/// Draws a `BulletData` into a canvas.
public struct BulletChartRenderer: ChartRenderer {
  public let data: BulletData
  public init(data: BulletData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let metrics = data.metrics
    guard !metrics.isEmpty else { return }

    // Match the Compose host layout: an 80% plot inset on every side.
    let chartLeft = size.width * 0.1
    let chartTop = size.height * 0.1
    let chartWidth = size.width * 0.8
    let chartHeight = size.height * 0.8

    let bandBase: Color = theme.isDark ? .white : .black
    let markerColor: Color = theme.isDark ? .white : .black

    let count = metrics.count
    let rowSlot = chartHeight / CGFloat(count)
    let rowHeight = rowSlot * 0.55

    // Left gutter for labels: ~28% of width.
    let gutter = chartWidth * 0.28
    let trackLeft = chartLeft + gutter
    let trackWidth = chartWidth - gutter

    let p = CGFloat(min(max(progress, 0), 1))

    for (index, metric) in metrics.enumerated() {
      let rowTop = chartTop + rowSlot * CGFloat(index) + (rowSlot - rowHeight) / 2
      let rowCenterY = rowTop + rowHeight / 2

      let sortedRanges = metric.ranges.sorted()
      let rawMax = max(max(CGFloat(sortedRanges.max() ?? 0), CGFloat(metric.value)), CGFloat(metric.target))
      let maxValue = rawMax <= 0 ? 1 : rawMax

      // Qualitative range bands, increasingly darker translucent tint.
      for (rIndex, rangeEnd) in sortedRanges.enumerated() {
        let start = rIndex == 0 ? 0 : CGFloat(sortedRanges[rIndex - 1])
        let x0 = trackLeft + (start / maxValue) * trackWidth
        let x1 = trackLeft + (CGFloat(rangeEnd) / maxValue) * trackWidth
        let alpha = 0.06 + 0.07 * Double(rIndex)
        let bandRect = CGRect(x: x0, y: rowTop, width: max(x1 - x0, 0), height: rowHeight)
        context.fill(
          Path(roundedRect: bandRect, cornerRadius: 4),
          with: .color(bandBase.opacity(alpha))
        )
      }

      // Measure bar = value: thinner, rounded, animated width.
      let measureHeight = rowHeight * 0.42
      let measureTop = rowCenterY - measureHeight / 2
      let measureFullWidth = (CGFloat(metric.value) / maxValue) * trackWidth
      let measureWidth = max(measureFullWidth * p, 0)
      let measureRect = CGRect(x: trackLeft, y: measureTop, width: measureWidth, height: measureHeight)
      let measureCorner = measureHeight / 2
      context.fill(
        Path(roundedRect: measureRect, cornerRadius: measureCorner),
        with: .color(metric.color.opacity(0.2))
      )
      context.fill(
        Path(roundedRect: measureRect, cornerRadius: measureCorner),
        with: .color(metric.color)
      )

      // Vertical target tick.
      let targetX = trackLeft + (CGFloat(metric.target) / maxValue) * trackWidth
      var targetLine = Path()
      targetLine.move(to: CGPoint(x: targetX, y: rowTop - 2))
      targetLine.addLine(to: CGPoint(x: targetX, y: rowTop + rowHeight + 2))
      context.stroke(targetLine, with: .color(markerColor), lineWidth: 3)

      // Label on the left of the row, truncated to fit the gutter.
      let labelString = metric.label.count > 8 ? String(metric.label.prefix(7)) + "…" : metric.label
      let labelText = Text(labelString).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(labelText, at: CGPoint(x: chartLeft, y: rowCenterY), anchor: .leading)

      // Value at the end of the row, above the track.
      let valueString = ChartFormatting.format(metric.value, decimals: 1)
      let valueText = Text(valueString).font(.system(size: 9)).foregroundColor(metric.color)
      context.draw(valueText, at: CGPoint(x: chartLeft + chartWidth, y: rowTop - 1), anchor: .bottomTrailing)
    }
  }
}

/// A bullet chart: stacked KPI tracks with qualitative range bands, an animated
/// value bar, and a target marker per metric.
public struct BulletChart: View {
  public let data: BulletData
  public var animate: Bool
  public var replay: Int

  public init(data: BulletData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: BulletChartRenderer(data: data), animate: animate, duration: 0.9, replay: replay)
  }
}
