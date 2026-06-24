//
//  ScatterPlot.swift
//  DrafterCharts
//
//  Cartesian scatter plot: an origin-bottom-left coordinate system with axis
//  lines, value labels at each tick, and filled dots whose radius scales up with
//  the reveal progress. Each dot carries a soft translucent halo and a crisp
//  white ring for a premium, glassy feel. Consumes an array of `ScatterPoint`
//  (x, y, plus an optional per-point color), so a color can never index past its
//  data. Mirrors the Compose `ScatterPlot` / `SimpleScatterPlotRenderer`.
//

import SwiftUI

/// Draws `[ScatterPoint]` into a canvas using a bottom-left origin.
public struct ScatterPlotRenderer: ChartRenderer {
  public let points: [ScatterPoint]
  public init(points: [ScatterPoint]) { self.points = points }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard !points.isEmpty else { return }

    // 10% inset on every side, matching the Compose layout (0.8 plot area).
    // Floor the left inset so Y axis labels never clip off the left edge at
    // small canvas sizes (10% of 300pt is only 30pt — too tight for "100.0").
    let chartHeight = size.height * 0.8
    let chartTop = size.height * 0.1
    let chartBottom = chartTop + chartHeight
    let chartLeft = Swift.max(size.width * 0.1, 34)
    let chartWidth = size.width * 0.9 - chartLeft

    let maxX = CGFloat(points.map(\.x).max() ?? 0)
    let maxY = CGFloat(points.map(\.y).max() ?? 0)
    guard maxX > 0, maxY > 0 else { return }

    // Axes: left (Y) and bottom (X), origin at bottom-left.
    var axes = Path()
    axes.move(to: CGPoint(x: chartLeft, y: chartTop))
    axes.addLine(to: CGPoint(x: chartLeft, y: chartBottom))
    axes.move(to: CGPoint(x: chartLeft, y: chartBottom))
    axes.addLine(to: CGPoint(x: chartLeft + chartWidth, y: chartBottom))
    context.stroke(axes, with: .color(theme.grid), lineWidth: 1.5)

    // Y labels: a few evenly spaced ticks (drawing one per distinct value
    // overlaps badly at small canvas sizes).
    for value in tickValues(max: Float(maxY), count: 4) {
      let y = chartBottom - (CGFloat(value) / maxY) * (chartBottom - chartTop)
      let text = Text(ChartFormatting.format(value)).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: chartLeft - 5, y: y), anchor: .trailing)
    }

    // X labels: a few evenly spaced ticks.
    for value in tickValues(max: Float(maxX), count: 4) {
      let x = chartLeft + (CGFloat(value) / maxX) * chartWidth
      let text = Text(ChartFormatting.format(value)).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: x, y: chartBottom + 5), anchor: .top)
    }

    // Points: radius scales with progress; halo + fill + white ring.
    let p = CGFloat(min(max(progress, 0), 1))
    let pointSize = 6.0 * p
    guard pointSize > 0 else { return }

    for (index, point) in points.enumerated() {
      let x = chartLeft + (CGFloat(point.x) / maxX) * chartWidth
      let y = chartTop + chartHeight - (CGFloat(point.y) / maxY) * chartHeight
      let center = CGPoint(x: x, y: y)

      // Each point's color travels with it; fall back to the theme palette by
      // position when none is given, so a color can never bind to the wrong dot.
      let color = point.color ?? theme.color(at: index)

      // Soft translucent halo.
      context.fill(circlePath(center: center, radius: pointSize * 2), with: .color(color.opacity(0.16 * Double(p))))
      // Crisp filled dot.
      context.fill(circlePath(center: center, radius: pointSize), with: .color(color.opacity(Double(p))))
      // White ring.
      context.stroke(circlePath(center: center, radius: pointSize), with: .color(Color.white.opacity(Double(p))), lineWidth: 1.5)
    }
  }

  /// Evenly spaced tick values from 0...max (inclusive) for axis labels.
  private func tickValues(max: Float, count: Int) -> [Float] {
    guard max > 0, count > 0 else { return [] }
    return (0...count).map { max * Float($0) / Float(count) }
  }

  private func circlePath(center: CGPoint, radius: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
  }
}

/// A cartesian scatter plot with axis labels and dots that scale in on reveal.
public struct ScatterPlot: View {
  public let points: [ScatterPoint]
  public var animate: Bool
  public var replay: Int

  public init(points: [ScatterPoint], animate: Bool = true, replay: Int = 0) {
    self.points = points
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: ScatterPlotRenderer(points: points), animate: animate, duration: 2.0, replay: replay)
  }
}
