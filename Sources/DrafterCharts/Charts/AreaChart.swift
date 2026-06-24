//
//  AreaChart.swift
//  DrafterCharts
//
//  Single smooth-curve area chart: Catmull-Rom spline, soft gradient fill that
//  fades to the baseline, a left-to-right reveal, and white-haloed vertex dots.
//  Reference implementation for the chart pattern: an immutable data struct, a
//  pure `ChartRenderer`, and a thin view that hosts it in `ChartCanvas`.
//

import SwiftUI

/// Data for an `AreaChart`: parallel `labels` and `values`, plus a line color.
public struct AreaChartData: Equatable, Sendable {
  public var labels: [String]
  public var values: [Float]
  public var color: Color

  public init(labels: [String], values: [Float], color: Color = DrafterColors.blue) {
    self.labels = labels
    self.values = values
    self.color = color
  }
}

/// Draws an `AreaChartData` into a canvas.
public struct AreaChartRenderer: ChartRenderer {
  public let data: AreaChartData
  public init(data: AreaChartData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let values = data.values
    guard values.count >= 2 else { return }

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
    let points: [CGPoint] = values.enumerated().map { index, value in
      let t: CGFloat = values.count == 1 ? 0.5 : CGFloat(index) / denom
      let x: CGFloat = bounds.left + bounds.width * t
      let norm = CGFloat(Double(value) / maxValue)
      let y: CGFloat = bounds.bottom - norm * bounds.height
      return CGPoint(x: x, y: y)
    }

    // Smooth area + line + reveal + end dot (shared helper).
    drawSmoothLine(
      in: &context,
      points: points,
      color: data.color,
      baseline: bounds.bottom,
      progress: progress,
      strokeWidth: 5,
      fill: true,
      endDot: true,
      smooth: true
    )

    // Vertex dots, revealed alongside the trace.
    let revealRight = bounds.left + bounds.width * CGFloat(min(max(progress, 0), 1))
    for point in points where point.x <= revealRight + 0.5 {
      drawVertexDot(in: &context, center: point, color: data.color, radius: 4)
    }

    // X labels — driven by the points (values), thinned so they stay legible at
    // small sizes (at most ~6). A label is only drawn when one exists at that
    // index, so a short/long `labels` array can never crash or shift labels.
    let maxLabels = 6
    let labelStride = max(1, (points.count + maxLabels - 1) / maxLabels)
    for index in points.indices
    where index < data.labels.count && index % labelStride == 0 {
      let text = Text(data.labels[index]).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: points[index].x, y: bounds.bottom + 13), anchor: .center)
    }
  }
}

/// A smooth area chart with a soft gradient fill and an animated reveal.
public struct AreaChart: View {
  public let data: AreaChartData
  public var animate: Bool
  public var replay: Int

  public init(data: AreaChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: AreaChartRenderer(data: data), animate: animate, duration: 0.9, replay: replay)
  }
}
