//
//  ScatterPlot.swift
//  DrafterCharts
//
//  Cartesian scatter plot: an origin-bottom-left coordinate system with axis
//  lines, value labels at each distinct x/y, and filled dots whose radius scales
//  up with the reveal progress. Each dot carries a soft translucent halo and a
//  crisp white ring for a premium, glassy feel. Mirrors the Compose
//  `ScatterPlot` / `SimpleScatterPlotRenderer` geometry and animation.
//

import SwiftUI

/// Data for a `ScatterPlot`: cartesian `points` (x, y) and a parallel list of
/// `pointColors` cycled per point (falls back to gray when a color is missing).
public struct ScatterPlotData: Equatable, Sendable {
  public var points: [Point]
  public var pointColors: [Color]

  /// A single (x, y) sample. Equatable/Sendable stand-in for a tuple in a stored property.
  public struct Point: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public init(_ x: Float, _ y: Float) {
      self.x = x
      self.y = y
    }
  }

  public init(points: [Point], pointColors: [Color] = [.black]) {
    self.points = points
    self.pointColors = pointColors
  }

  /// Convenience initializer accepting raw `(Float, Float)` tuples.
  public init(points: [(Float, Float)], pointColors: [Color] = [.black]) {
    self.points = points.map { Point($0.0, $0.1) }
    self.pointColors = pointColors
  }
}

/// Draws a `ScatterPlotData` into a canvas using a bottom-left origin.
public struct ScatterPlotRenderer: ChartRenderer {
  public let data: ScatterPlotData
  public init(data: ScatterPlotData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let points = data.points
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

      let color = index < data.pointColors.count ? data.pointColors[index] : .gray

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
  public let data: ScatterPlotData
  public var animate: Bool
  public var replay: Int

  public init(data: ScatterPlotData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: ScatterPlotRenderer(data: data), animate: animate, duration: 2.0, replay: replay)
  }
}
