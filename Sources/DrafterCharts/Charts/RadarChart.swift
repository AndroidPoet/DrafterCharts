//
//  RadarChart.swift
//  DrafterCharts
//
//  Multi-axis radar (spider) chart: five concentric grid rings, one axis
//  radiating per dimension, and a filled + stroked polygon per dataset whose
//  vertices grow from the center as the reveal `progress` advances. Mirrors the
//  Kotlin `RadarChartRenderer` geometry. Follows the canonical chart pattern: an
//  immutable data struct, a pure `ChartRenderer`, and a thin hosting view.
//

import SwiftUI

/// One radar dataset: a dimension-name to normalized-value (0...1) mapping.
public struct RadarChartData: Equatable, Sendable {
  public var values: [String: Float]

  public init(values: [String: Float]) {
    self.values = values
  }
}

/// Draws one or more overlaid `RadarChartData` polygons into a canvas.
///
/// Axes are taken from the first dataset's keys (in insertion order). Each
/// dataset is filled at 22% and stroked at 90% opacity, both scaled by reveal
/// `progress`; vertices grow outward from the center as `progress` advances.
public struct RadarChartRenderer: ChartRenderer {
  public let data: [RadarChartData]
  public let colors: [Color]

  public init(data: [RadarChartData], colors: [Color] = DrafterColors.palette) {
    self.data = data
    self.colors = colors
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard let first = data.first else { return }
    let axisLabels = Self.orderedKeys(first.values)
    let axisCount = axisLabels.count
    guard axisCount >= 3 else { return }

    let layout = RadialLayout(in: size, scale: 0.8)

    drawGridAndAxes(in: &context, layout: layout, axisLabels: axisLabels, theme: theme)

    for (index, dataset) in data.enumerated() {
      let color = colors.isEmpty ? theme.color(at: index) : colors[index % colors.count]
      drawDataPolygon(
        in: &context,
        layout: layout,
        axisLabels: axisLabels,
        dataset: dataset,
        color: color,
        progress: progress
      )
    }
  }

  // Concentric grid rings (5), one axis line per dimension, and axis labels.
  private func drawGridAndAxes(
    in context: inout GraphicsContext,
    layout: RadialLayout,
    axisLabels: [String],
    theme: DrafterThemeColors
  ) {
    let center = layout.center
    let radius = layout.radius
    let axisCount = axisLabels.count

    // Concentric rings.
    for ring in 1...5 {
      let r = radius * CGFloat(ring) / 5
      let circle = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
      context.stroke(circle, with: .color(theme.grid), lineWidth: 1)
    }

    // Axes + labels.
    for i in 0..<axisCount {
      let angle = Self.axisAngle(index: i, count: axisCount)
      let end = layout.point(angle: angle, distance: radius)

      var axis = Path()
      axis.move(to: center)
      axis.addLine(to: end)
      context.stroke(axis, with: .color(theme.grid), lineWidth: 1)

      let labelPoint = layout.point(angle: angle, distance: radius * 1.1)
      let label = Text(axisLabels[i]).font(.system(size: 12)).foregroundColor(theme.label)
      context.draw(label, at: labelPoint, anchor: .center)
    }
  }

  // Filled + stroked polygon for one dataset, vertices scaled by progress.
  private func drawDataPolygon(
    in context: inout GraphicsContext,
    layout: RadialLayout,
    axisLabels: [String],
    dataset: RadarChartData,
    color: Color,
    progress: Double
  ) {
    let axisCount = axisLabels.count
    let p = CGFloat(min(max(progress, 0), 1))

    let points: [CGPoint] = axisLabels.enumerated().map { index, key in
      let value = CGFloat(dataset.values[key] ?? 0)
      let angle = Self.axisAngle(index: index, count: axisCount)
      let distance = layout.radius * value * p
      return layout.point(angle: angle, distance: distance)
    }
    guard let firstPoint = points.first else { return }

    var path = Path()
    path.move(to: firstPoint)
    for point in points.dropFirst() { path.addLine(to: point) }
    path.closeSubpath()

    context.fill(path, with: .color(color.opacity(0.22 * progress)))
    context.stroke(
      path,
      with: .color(color.opacity(0.9 * progress)),
      style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)
    )

    // Haloed vertex dots once the polygon has expanded enough.
    if progress > 0.6 {
      for point in points {
        drawVertexDot(in: &context, center: point, color: color, radius: 4)
      }
    }
  }

  // Angle for axis `index`, starting at the top (-90 deg) and stepping clockwise.
  private static func axisAngle(index: Int, count: Int) -> CGFloat {
    CGFloat(index) * 2 * .pi / CGFloat(count) - .pi / 2
  }

  // Keys in insertion order where available, otherwise sorted for stability.
  private static func orderedKeys(_ values: [String: Float]) -> [String] {
    values.keys.sorted()
  }
}

/// A multi-axis radar chart with grid rings, per-axis labels, and an animated
/// expand-from-center reveal for each overlaid dataset.
public struct RadarChart: View {
  public let data: [RadarChartData]
  public let colors: [Color]
  public var animate: Bool
  public var replay: Int

  public init(
    data: [RadarChartData],
    colors: [Color] = DrafterColors.palette,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.data = data
    self.colors = colors
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: RadarChartRenderer(data: data, colors: colors),
      animate: animate,
      duration: 1.0,
      replay: replay
    )
  }
}
