//
//  SunburstChart.swift
//  DrafterCharts
//
//  Hierarchical radial chart: an inner ring of root nodes plus an outer ring of
//  children that subdivide each parent's angular span. Wedges are drawn as thick
//  stroked arcs along each ring's mid-line, sweep open with the reveal progress,
//  start at -90deg and advance clockwise, and carry centered mid-radius labels.
//

import SwiftUI

/// One node in a `SunburstChart` hierarchy. Root nodes form the inner ring; their
/// `children` form the outer ring, each subdividing the parent's angular span.
public struct SunburstNode: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color
  public var children: [SunburstNode]

  public init(label: String, value: Float, color: Color, children: [SunburstNode] = []) {
    self.label = label
    self.value = value
    self.color = color
    self.children = children
  }
}

/// Draws a sunburst hierarchy into a canvas as two concentric rings.
public struct SunburstChartRenderer: ChartRenderer {
  public let roots: [SunburstNode]
  public init(roots: [SunburstNode]) { self.roots = roots }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard !roots.isEmpty else { return }

    let layout = RadialLayout(in: size, scale: 0.92)
    let center = layout.center
    let maxRadius = layout.radius
    guard maxRadius > 0 else { return }

    let total = max(roots.reduce(Float(0)) { $0 + $1.value }, 0.0001)

    // Geometry: small center hole, inner ring (roots), outer ring (children).
    let holeRadius = maxRadius * 0.22
    let innerOuter = maxRadius * 0.60
    let outerOuter = maxRadius

    let labelColor: Color = theme.isDark ? .white : .black

    var cursor: CGFloat = -90
    for root in roots {
      let rootSweep = CGFloat(root.value / total) * 360 * CGFloat(progress)
      let rootStart = cursor

      // Inner ring wedge.
      drawRingWedge(
        in: &context,
        center: center,
        innerRadius: holeRadius,
        outerRadius: innerOuter,
        startAngle: rootStart,
        sweepAngle: rootSweep,
        color: root.color
      )
      drawRingLabel(
        in: &context,
        center: center,
        radius: (holeRadius + innerOuter) / 2,
        startAngle: rootStart,
        sweepAngle: rootSweep,
        label: root.label,
        color: labelColor
      )

      // Outer ring: children subdivide the parent's full angular span.
      let childTotal = max(root.children.reduce(Float(0)) { $0 + $1.value }, 0.0001)
      let fullRootSweep = CGFloat(root.value / total) * 360
      var childCursor = rootStart
      for child in root.children {
        let childSweep = CGFloat(child.value / childTotal) * fullRootSweep * CGFloat(progress)
        // Lighten the child toward white by 30% (matches Compose `lerp(color, White, 0.30)`)
        // by compositing a 30%-opacity white wash over the child color.
        drawRingWedge(
          in: &context,
          center: center,
          innerRadius: innerOuter,
          outerRadius: outerOuter,
          startAngle: childCursor,
          sweepAngle: childSweep,
          color: child.color,
          tint: .white.opacity(0.30)
        )
        drawRingLabel(
          in: &context,
          center: center,
          radius: (innerOuter + outerOuter) / 2,
          startAngle: childCursor,
          sweepAngle: childSweep,
          label: child.label,
          color: labelColor
        )
        childCursor += childSweep
      }

      cursor += rootSweep
    }
  }

  public var accessibilityLabel: String { "Sunburst chart" }
  public var accessibilityValue: String {
    roots.isEmpty ? "No data" : "\(roots.count) root segments"
  }
}

/// Draws an annular wedge as a thick stroked arc along the ring's mid-line, plus
/// a soft white separator stroke at the wedge for crisp segmentation.
private func drawRingWedge(
  in context: inout GraphicsContext,
  center: CGPoint,
  innerRadius: CGFloat,
  outerRadius: CGFloat,
  startAngle: CGFloat,
  sweepAngle: CGFloat,
  color: Color,
  tint: Color? = nil
) {
  guard sweepAngle > 0 else { return }
  let midRadius = (innerRadius + outerRadius) / 2
  let thickness = outerRadius - innerRadius

  var arc = Path()
  arc.addArc(
    center: center,
    radius: midRadius,
    startAngle: .degrees(startAngle),
    endAngle: .degrees(startAngle + sweepAngle),
    clockwise: false
  )

  context.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: thickness))
  // Optional lightening wash composited over the wedge.
  if let tint {
    context.stroke(arc, with: .color(tint), style: StrokeStyle(lineWidth: thickness))
  }
  // Soft white separator stroke along the wedge for crisp segmentation.
  context.stroke(arc, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 1))
}

/// Draws a centered label at the wedge's mid-angle / mid-radius, but only when
/// the segment is wide enough (>= 18deg) to fit text.
private func drawRingLabel(
  in context: inout GraphicsContext,
  center: CGPoint,
  radius: CGFloat,
  startAngle: CGFloat,
  sweepAngle: CGFloat,
  label: String,
  color: Color
) {
  guard sweepAngle >= 18 else { return }
  let midDeg = startAngle + sweepAngle / 2
  let midRad = midDeg * .pi / 180
  let lx = center.x + cos(midRad) * radius
  let ly = center.y + sin(midRad) * radius
  let text = Text(label).font(.system(size: 9)).foregroundColor(color)
  context.draw(text, at: CGPoint(x: lx, y: ly), anchor: .center)
}

/// A hierarchical sunburst chart: inner ring of roots, outer ring of children,
/// drawn clockwise from the top with an animated sweep reveal.
public struct SunburstChart: View {
  public let roots: [SunburstNode]
  public var animate: Bool
  public var replay: Int

  public init(roots: [SunburstNode], animate: Bool = true, replay: Int = 0) {
    self.roots = roots
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: SunburstChartRenderer(roots: roots), animate: animate, duration: 0.9, replay: replay)
  }
}
