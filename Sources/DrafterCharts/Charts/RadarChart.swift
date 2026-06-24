//
//  RadarChart.swift
//  DrafterCharts
//
//  Multi-axis radar (spider) chart: five concentric grid rings, one axis
//  radiating per dimension, and a filled + stroked polygon per series whose
//  vertices grow from the center as the reveal `progress` advances. Mirrors the
//  Kotlin `RadarChartRenderer` geometry. Follows the canonical chart pattern: a
//  color-bearing series type, a pure `ChartRenderer`, and a thin hosting view.
//

import SwiftUI

/// Draws one or more overlaid `RadarSeries` polygons into a canvas.
///
/// Axes are taken from the first non-empty series' keys, with any extra keys
/// from later series unioned in so no series loses an axis. Each series carries
/// its own `color`, is filled at 22% and stroked at 90% opacity, both scaled by
/// reveal `progress`; vertices grow outward from the center as `progress` advances.
public struct RadarChartRenderer: ChartRenderer {
  public let series: [RadarSeries]

  public init(series: [RadarSeries]) {
    self.series = series
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    // Element count is driven by `series`; axes are derived defensively so series
    // with differing (or empty) key sets can never crash or drop the whole chart.
    guard !series.isEmpty else { return }
    let axisLabels = Self.orderedAxisLabels(series)
    let axisCount = axisLabels.count
    guard axisCount >= 3 else { return }

    let layout = RadialLayout(in: size, scale: 0.8)

    drawGridAndAxes(in: &context, layout: layout, axisLabels: axisLabels, theme: theme)

    for entry in series {
      drawDataPolygon(
        in: &context,
        layout: layout,
        axisLabels: axisLabels,
        series: entry,
        color: entry.color,
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

  // Filled + stroked polygon for one series, vertices scaled by progress.
  private func drawDataPolygon(
    in context: inout GraphicsContext,
    layout: RadialLayout,
    axisLabels: [String],
    series: RadarSeries,
    color: Color,
    progress: Double
  ) {
    let axisCount = axisLabels.count
    let p = CGFloat(min(max(progress, 0), 1))

    let points: [CGPoint] = axisLabels.enumerated().map { index, key in
      let value = CGFloat(series.values[key] ?? 0)
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

  // Stable axis ordering across (possibly mismatched) series. Seeds from the
  // first non-empty series' sorted keys, then appends any extra keys from other
  // series (also sorted) so a richer series never silently loses an axis. For
  // matching input this is identical to sorting the first series' keys.
  private static func orderedAxisLabels(_ series: [RadarSeries]) -> [String] {
    guard let seed = series.first(where: { !$0.values.isEmpty }) else { return [] }
    var labels = orderedKeys(seed.values)
    var seen = Set(labels)
    for entry in series {
      for key in orderedKeys(entry.values) where !seen.contains(key) {
        labels.append(key)
        seen.insert(key)
      }
    }
    return labels
  }
}

/// A multi-axis radar chart with grid rings, per-axis labels, and an animated
/// expand-from-center reveal for each overlaid series.
public struct RadarChart: View {
  public let series: [RadarSeries]
  public var animate: Bool
  public var replay: Int

  public init(
    series: [RadarSeries],
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.series = series
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: RadarChartRenderer(series: series),
      animate: animate,
      duration: 1.0,
      replay: replay
    )
  }
}
