//
//  StepLineChart.swift
//  DrafterCharts
//
//  Stepped line chart: an array of `ChartPoint` (label bound to value) connected
//  with horizontal-then-vertical segments (no smoothing), a soft gradient fill
//  that fades to the baseline below the steps, a left-to-right reveal that clips
//  the trace, and vertex dots at each data point. Mirrors the Compose
//  `StepLineChartRenderer`.
//

import SwiftUI

/// Draws a stepped line chart from `[ChartPoint]` as horizontal/vertical steps.
public struct StepLineChartRenderer: ChartRenderer {
  public let points: [ChartPoint]
  public let color: Color

  public init(points: [ChartPoint], color: Color = DrafterColors.teal) {
    self.points = points
    self.color = color
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let values = points.map { $0.value }
    guard !values.isEmpty else { return }

    let bounds = ChartBounds(in: size, left: 40, top: 12, right: 16, bottom: 26)
    // Anchored at zero, like the Compose renderer.
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

    // Map data points to pixel space.
    let count = values.count
    let pixelPoints: [CGPoint] = values.enumerated().map { index, value in
      let x: CGFloat
      if count == 1 {
        x = bounds.left + bounds.width / 2
      } else {
        x = bounds.left + CGFloat(index) / CGFloat(count - 1) * bounds.width
      }
      let y = bounds.bottom - CGFloat(Double(value) / maxValue) * bounds.height
      return CGPoint(x: x, y: y)
    }

    // Stepped path: horizontal to next x at the previous y, then vertical to next y.
    let stepPath = steppedPath(pixelPoints)

    let clamped = CGFloat(min(max(progress, 0), 1))
    let revealRight = bounds.left + bounds.width * clamped

    // Reveal clip: everything left of the moving edge.
    var clip = context
    clip.clip(to: Path(CGRect(x: 0, y: 0, width: revealRight, height: size.height)))

    if let first = pixelPoints.first, let last = pixelPoints.last {
      var fillPath = stepPath
      fillPath.addLine(to: CGPoint(x: last.x, y: bounds.bottom))
      fillPath.addLine(to: CGPoint(x: first.x, y: bounds.bottom))
      fillPath.closeSubpath()

      let topY = pixelPoints.map(\.y).min() ?? bounds.top
      clip.fill(
        fillPath,
        with: .linearGradient(
          Gradient(colors: [color.opacity(0.22), color.opacity(0)]),
          startPoint: CGPoint(x: 0, y: topY),
          endPoint: CGPoint(x: 0, y: bounds.bottom)
        )
      )
    }

    // Stepped line with rounded caps/joins.
    clip.stroke(
      stepPath,
      with: .color(color),
      style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
    )

    // Vertex dots at each revealed data point.
    for point in pixelPoints where point.x <= revealRight + 0.5 {
      drawVertexDot(in: &context, center: point, color: color, radius: 4)
    }

    // X-axis labels, thinned so they stay legible at small sizes (at most ~6).
    // Each label travels with its point, so labels can never shift or run short;
    // blank labels (unlabeled points) are simply skipped.
    let maxLabels = 6
    let labelStride = max(1, (pixelPoints.count + maxLabels - 1) / maxLabels)
    for index in pixelPoints.indices where index % labelStride == 0 {
      let label = points[index].label
      guard !label.isEmpty else { continue }
      let text = Text(label).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: pixelPoints[index].x, y: bounds.bottom + 13), anchor: .center)
    }
  }

  public var accessibilityLabel: String { "Step line chart" }
  public var accessibilityValue: String {
    points.isEmpty ? "No data" : "\(points.count) points, \(AccessibilityFormat.points(points.map { ($0.label, $0.value) }))"
  }

  /// Builds a stepped polyline: for each segment go horizontally at the prior
  /// y to the next x, then vertically to the next y.
  private func steppedPath(_ points: [CGPoint]) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    for i in 1..<max(points.count, 1) {
      path.addLine(to: CGPoint(x: points[i].x, y: points[i - 1].y))
      path.addLine(to: CGPoint(x: points[i].x, y: points[i].y))
    }
    return path
  }
}

/// A stepped line chart with a soft gradient fill and a left-to-right reveal.
public struct StepLineChart: View {
  public let points: [ChartPoint]
  public let color: Color
  public var animate: Bool
  public var replay: Int

  public init(points: [ChartPoint], color: Color = DrafterColors.teal, animate: Bool = true, replay: Int = 0) {
    self.points = points
    self.color = color
    self.animate = animate
    self.replay = replay
  }

  /// Convenience for unlabeled data: one value per point, blank x-axis labels.
  public init(values: [Float], color: Color = DrafterColors.teal, animate: Bool = true, replay: Int = 0) {
    self.init(points: values.map(ChartPoint.init), color: color, animate: animate, replay: replay)
  }

  public var body: some View {
    ChartCanvas(renderer: StepLineChartRenderer(points: points, color: color), animate: animate, duration: 0.9, replay: replay)
  }
}
