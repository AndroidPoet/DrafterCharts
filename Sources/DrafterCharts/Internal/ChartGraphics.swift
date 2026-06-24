//
//  ChartGraphics.swift
//  DrafterCharts
//
//  Internal drawing helpers shared across every chart renderer. This is the
//  SwiftUI twin of the Compose library's `internal/ChartGraphics.kt` — it gives
//  every chart the same "smooth, premium" character: Catmull-Rom cubic-bezier
//  curves instead of jagged segments, soft fade-to-transparent gradient fills,
//  and a left-to-right reveal animation that traces the curve.
//

import SwiftUI

// MARK: - Smooth paths

/// Builds a smooth cubic-bezier `Path` that passes through every vertex in
/// `points` using a Catmull-Rom spline (tension 0.5). Falls back to straight
/// segments when there are fewer than three points, where a curve is undefined.
///
/// Pure and `Sendable` — safe to call from `Shape.path(in:)`, which SwiftUI may
/// run off the main thread.
func smoothPath(_ points: [CGPoint]) -> Path {
  var path = Path()
  guard let first = points.first else { return path }

  path.move(to: first)
  if points.count < 3 {
    for i in 1..<points.count { path.addLine(to: points[i]) }
    return path
  }

  for i in 0..<(points.count - 1) {
    let p0 = points[i - 1 < 0 ? i : i - 1]
    let p1 = points[i]
    let p2 = points[i + 1]
    let p3 = points[i + 2 > points.count - 1 ? i + 1 : i + 2]

    // Catmull-Rom -> cubic bezier control points (tension 0.5).
    let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
    let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
    path.addCurve(to: p2, control1: c1, control2: c2)
  }
  return path
}

/// A straight-segment polyline path, used when a series opts out of smoothing.
func polylinePath(_ points: [CGPoint]) -> Path {
  var path = Path()
  guard let first = points.first else { return path }
  path.move(to: first)
  for i in 1..<points.count { path.addLine(to: points[i]) }
  return path
}

// MARK: - Gradients

/// A soft vertical gradient fading from `color` near the curve to transparent at
/// the baseline. Mirrors `areaGradient` in the Compose library.
func areaGradient(_ color: Color, topAlpha: Double = 0.32) -> LinearGradient {
  LinearGradient(
    stops: [
      .init(color: color.opacity(topAlpha), location: 0.0),
      .init(color: color.opacity(topAlpha * 0.45), location: 0.5),
      .init(color: color.opacity(0.0), location: 1.0),
    ],
    startPoint: .top,
    endPoint: .bottom
  )
}

// MARK: - Smooth line drawing (with reveal animation)

/// Draws a single smooth line series with an optional gradient area fill, a
/// tracing left-to-right reveal animation, and an optional highlighted end dot.
///
/// This is the SwiftUI equivalent of `DrawScope.drawSmoothLine`. Call it from
/// inside a `Canvas` draw closure.
///
/// - Parameters:
///   - context: the live `GraphicsContext`.
///   - points: data vertices in pixel space, left to right.
///   - color: stroke color for the line.
///   - baseline: y-coordinate the area fill drops down to (chart bottom).
///   - progress: reveal progress in `0...1`.
///   - strokeWidth: line thickness in points.
///   - fill: when true, paints the soft gradient area under the curve.
///   - endDot: when true, draws a glowing dot at the leading edge of the reveal.
///   - smooth: when true, curves the line with a Catmull-Rom spline.
func drawSmoothLine(
  in context: inout GraphicsContext,
  points: [CGPoint],
  color: Color,
  baseline: CGFloat,
  progress: Double,
  strokeWidth: CGFloat = 6,
  fill: Bool = true,
  endDot: Bool = true,
  smooth: Bool = true
) {
  guard points.count >= 2, let firstPoint = points.first, let lastPoint = points.last else { return }
  let clamped = min(max(progress, 0), 1)
  let linePath = smooth ? smoothPath(points) : polylinePath(points)

  let startX = firstPoint.x
  let endX = lastPoint.x
  let revealRight = startX + (endX - startX) * clamped

  // Soft gradient area fill, clipped to the reveal frontier.
  if fill {
    let topY = points.map(\.y).min() ?? baseline
    var fillPath = linePath
    fillPath.addLine(to: CGPoint(x: endX, y: baseline))
    fillPath.addLine(to: CGPoint(x: startX, y: baseline))
    fillPath.closeSubpath()

    var clip = context
    clip.clip(to: Path(CGRect(x: startX, y: topY, width: revealRight - startX, height: baseline - topY)))
    clip.fill(
      fillPath,
      with: .linearGradient(
        Gradient(stops: [
          .init(color: color.opacity(0.32), location: 0),
          .init(color: color.opacity(0.144), location: 0.5),
          .init(color: color.opacity(0), location: 1),
        ]),
        startPoint: CGPoint(x: 0, y: topY),
        endPoint: CGPoint(x: 0, y: baseline)
      )
    )
  }

  // Trace the stroke exactly up to the reveal frontier for a clean "drawing" feel.
  let drawn = linePath.trimmedPath(from: 0, to: clamped)
  context.stroke(
    drawn,
    with: .color(color),
    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
  )

  // Glowing dot at the leading edge of the reveal. Reuse the trimmed path's
  // own end point — no second `trimmedPath`/`CGPath` walk per frame.
  if endDot, clamped > 0.001, let pos = drawn.currentPoint {
    context.fill(Path(ellipseIn: dotRect(pos, strokeWidth * 1.5)), with: .color(.white))
    context.fill(Path(ellipseIn: dotRect(pos, strokeWidth * 0.95)), with: .color(color))
  }
}

/// Draws a small filled dot with a white halo — used to mark line vertices.
func drawVertexDot(in context: inout GraphicsContext, center: CGPoint, color: Color, radius: CGFloat) {
  context.fill(Path(ellipseIn: dotRect(center, radius * 1.7)), with: .color(.white))
  context.fill(Path(ellipseIn: dotRect(center, radius)), with: .color(color))
}

private func dotRect(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
  CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
}
