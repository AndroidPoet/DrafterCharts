//
//  AreaChart.swift
//  DrafterCharts
//
//  Single smooth-curve area chart: Catmull-Rom spline, soft gradient fill that
//  fades to the baseline, a left-to-right reveal, and white-haloed vertex dots.
//  Reference implementation for the point-based pattern: an array of `ChartPoint`
//  (label bound to value), a pure `ChartRenderer`, and a thin hosting view.
//

import SwiftUI

/// Draws a smooth area chart from `[ChartPoint]`.
public struct AreaChartRenderer: ChartRenderer {
  public let points: [ChartPoint]
  public let color: Color

  public init(points: [ChartPoint], color: Color = DrafterColors.blue) {
    self.points = points
    self.color = color
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard points.count >= 2 else { return }
    let values = points.map { $0.value }

    let bounds = ChartBounds(in: size, left: 40, top: 12, right: 16, bottom: 26)
    // Zero-anchored axis, like the Compose renderer (max clamped to >= 1).
    let rawMax = Double(values.max() ?? 0)
    let maxValue = rawMax <= 0 ? 1 : rawMax

    // Y grid + labels (4 ticks).
    let tickCount = 4
    for i in 0...tickCount {
      let frac = CGFloat(i) / CGFloat(tickCount)
      let y = bounds.bottom - frac * bounds.height
      var line = Path()
      line.move(to: CGPoint(x: bounds.left, y: y))
      line.addLine(to: CGPoint(x: bounds.right, y: y))
      context.stroke(line, with: .color(theme.grid), lineWidth: 1)

      let tickValue = maxValue * Double(frac)
      let text = Text(ChartFormatting.format(Float(tickValue))).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: bounds.left - 6, y: y), anchor: .trailing)
    }

    // Map points into pixel space.
    let denom = CGFloat(max(1, values.count - 1))
    let pixelPoints: [CGPoint] = values.enumerated().map { index, value in
      let t = CGFloat(index) / denom
      let x = bounds.left + bounds.width * t
      let norm = CGFloat(Double(value) / maxValue)
      let y = bounds.bottom - norm * bounds.height
      return CGPoint(x: x, y: y)
    }

    // Smooth area + line + reveal + end dot (shared helper).
    drawSmoothLine(
      in: &context,
      points: pixelPoints,
      color: color,
      baseline: bounds.bottom,
      progress: progress,
      strokeWidth: 5,
      fill: true,
      endDot: true,
      smooth: true
    )

    // Vertex dots, revealed alongside the trace.
    let revealRight = bounds.left + bounds.width * CGFloat(min(max(progress, 0), 1))
    for point in pixelPoints where point.x <= revealRight + 0.5 {
      drawVertexDot(in: &context, center: point, color: color, radius: 4)
    }

    // X labels, thinned so they stay legible at small sizes (at most ~6). Each
    // label travels with its point, so labels can never shift or run short.
    let maxLabels = 6
    let labelStride = max(1, (pixelPoints.count + maxLabels - 1) / maxLabels)
    for index in pixelPoints.indices where index % labelStride == 0 {
      let label = points[index].label
      guard !label.isEmpty else { continue }
      let text = Text(label).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: pixelPoints[index].x, y: bounds.bottom + 13), anchor: .center)
    }
  }

  public var accessibilityLabel: String { "Area chart" }
  public var accessibilityValue: String {
    points.isEmpty ? "No data" : "\(points.count) points, \(AccessibilityFormat.points(points.map { ($0.label, $0.value) }))"
  }
}

/// A smooth area chart with a soft gradient fill and an animated reveal.
public struct AreaChart: View {
  public let points: [ChartPoint]
  public let color: Color
  public var animate: Bool
  public var replay: Int

  public init(points: [ChartPoint], color: Color = DrafterColors.blue, animate: Bool = true, replay: Int = 0) {
    self.points = points
    self.color = color
    self.animate = animate
    self.replay = replay
  }

  /// Convenience for unlabeled data: one value per point, blank x-axis labels.
  public init(values: [Float], color: Color = DrafterColors.blue, animate: Bool = true, replay: Int = 0) {
    self.init(points: values.map(ChartPoint.init), color: color, animate: animate, replay: replay)
  }

  public var body: some View {
    ChartCanvas(renderer: AreaChartRenderer(points: points, color: color), animate: animate, duration: 0.9, replay: replay)
  }
}
