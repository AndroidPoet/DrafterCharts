//
//  PolarAreaChart.swift
//  DrafterCharts
//
//  Polar area (rose) chart: equal-angle radial wedges where the RADIUS encodes
//  magnitude — every wedge shares the same angular width, and a larger value
//  reaches farther from the center. Concentric grid rings + radial spokes sit
//  behind the wedges, the radius grows with the reveal `progress`, and labels
//  are placed just outside the wedges. Mirrors `AreaChart` in structure: an
//  immutable data struct, a pure `ChartRenderer`, and a thin hosting view.
//

import SwiftUI

/// A single wedge in a `PolarAreaChart`: its `label`, magnitude `value`, and `color`.
public struct PolarSlice: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color

  public init(label: String, value: Float, color: Color) {
    self.label = label
    self.value = value
    self.color = color
  }
}

/// Draws polar-area wedges into a canvas as equal-angle, value-radius wedges.
public struct PolarAreaChartRenderer: ChartRenderer {
  public let slices: [PolarSlice]
  public init(slices: [PolarSlice]) { self.slices = slices }

  /// The largest slice value, used to normalize radii.
  public func maxValue() -> Float { slices.map(\.value).max() ?? 0 }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard !slices.isEmpty else { return }

    // Leave room for the outside labels: the demo card is short (~200pt tall),
    // so the constraining half-dimension is small. A 0.72 scale keeps the
    // label ring (maxRadius + 14) inside the canvas top/bottom edges.
    let layout = RadialLayout(in: size, scale: 0.72)
    let center = layout.center
    let maxRadius = layout.radius
    guard maxRadius > 0 else { return }

    let maxVal = CGFloat(max(maxValue(), 0.0001))
    let sweepPer = 360.0 / Double(slices.count)

    drawGrid(in: &context, center: center, maxRadius: maxRadius, sliceCount: slices.count, sweepPer: sweepPer, color: theme.grid)

    // Wedges: equal angle, radius proportional to value, radius animates with progress.
    for (index, slice) in slices.enumerated() {
      let startAngle = -90.0 + Double(index) * sweepPer
      let targetRadius = CGFloat(slice.value) / maxVal * maxRadius
      let radius = targetRadius * CGFloat(min(max(progress, 0), 1))
      if radius <= 0 { continue }

      let wedge = wedgePath(center: center, radius: radius, startDeg: startAngle, sweepDeg: sweepPer)
      context.fill(wedge, with: .color(slice.color.opacity(0.7)))
      context.stroke(wedge, with: .color(Color.white.opacity(0.55)), lineWidth: 1.5)
    }

    drawLabels(in: &context, center: center, maxRadius: maxRadius, slices: slices, sweepPer: sweepPer, color: theme.label)
  }

  public var accessibilityLabel: String { "Polar area chart" }
  public var accessibilityValue: String {
    slices.isEmpty ? "No data" : "\(slices.count) slices, \(AccessibilityFormat.points(slices.map { ($0.label, $0.value) }))"
  }

  // MARK: - Geometry

  /// A pie-style wedge (center → arc → center) spanning `sweepDeg` from `startDeg`.
  private func wedgePath(center: CGPoint, radius: CGFloat, startDeg: Double, sweepDeg: Double) -> Path {
    var path = Path()
    path.move(to: center)
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .degrees(startDeg),
      endAngle: .degrees(startDeg + sweepDeg),
      clockwise: false
    )
    path.closeSubpath()
    return path
  }

  // MARK: - Chrome

  /// Concentric grid rings plus radial spokes along each wedge boundary.
  private func drawGrid(in context: inout GraphicsContext, center: CGPoint, maxRadius: CGFloat, sliceCount: Int, sweepPer: Double, color: Color) {
    let rings = 4
    for ring in 1...rings {
      let r = maxRadius * CGFloat(ring) / CGFloat(rings)
      let circle = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
      context.stroke(circle, with: .color(color), lineWidth: 1)
    }
    for i in 0..<sliceCount {
      let angle = CGFloat((-90.0 + Double(i) * sweepPer) * .pi / 180.0)
      var spoke = Path()
      spoke.move(to: center)
      spoke.addLine(to: CGPoint(x: center.x + cos(angle) * maxRadius, y: center.y + sin(angle) * maxRadius))
      context.stroke(spoke, with: .color(color), lineWidth: 1)
    }
  }

  /// Wedge labels placed just outside the outer ring, at each wedge's mid-angle.
  private func drawLabels(in context: inout GraphicsContext, center: CGPoint, maxRadius: CGFloat, slices: [PolarSlice], sweepPer: Double, color: Color) {
    let labelRadius = maxRadius + 14
    for (index, slice) in slices.enumerated() {
      let midDeg = -90.0 + Double(index) * sweepPer + sweepPer / 2.0
      let mid = CGFloat(midDeg * .pi / 180.0)
      let x = center.x + cos(mid) * labelRadius
      let y = center.y + sin(mid) * labelRadius
      let text = Text(slice.label).font(.system(size: 10)).foregroundColor(color)
      context.draw(text, at: CGPoint(x: x, y: y), anchor: .center)
    }
  }
}

/// A polar area (rose) chart: equal-angle wedges whose radius encodes magnitude,
/// revealed by an animated outward growth.
public struct PolarAreaChart: View {
  public let slices: [PolarSlice]
  public var animate: Bool
  public var replay: Int

  public init(slices: [PolarSlice], animate: Bool = true, replay: Int = 0) {
    self.slices = slices
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: PolarAreaChartRenderer(slices: slices), animate: animate, duration: 0.9, replay: replay)
  }
}
