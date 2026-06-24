//
//  SmoothShapes.swift
//  DrafterCharts
//
//  Reusable, native SwiftUI `Shape` building blocks for the line/area family.
//
//  Why Shapes (and not only Canvas): a `Shape` participates in SwiftUI's layout
//  and animation system directly. The reveal animation is just `.trim(from:to:)`
//  interpolated on the render side — no per-frame view-body rebuild — and callers
//  get `.fill`, `.stroke`, `.trim`, and gradients for free. `path(in:)` is pure
//  and `Sendable`, so SwiftUI may evaluate it off the main thread.
//
//  Points are normalized to the unit square (x,y in 0...1, y pointing down) and
//  mapped into the draw rect, so the same shape is reusable at any size without
//  the caller re-scaling.
//

import SwiftUI

/// A smooth (Catmull-Rom) or straight polyline through normalized `points`.
///
/// ```swift
/// SmoothLineShape(points: normalized)
///   .trim(from: 0, to: reveal)              // animatable reveal
///   .stroke(.tint, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
/// ```
public struct SmoothLineShape: Shape {
  /// Unit-square points (x,y in 0...1, y down), left to right.
  public var points: [CGPoint]
  /// Curve with a Catmull-Rom spline when true; straight segments when false.
  public var smooth: Bool

  public init(points: [CGPoint], smooth: Bool = true) {
    self.points = points
    self.smooth = smooth
  }

  public func path(in rect: CGRect) -> Path {
    let mapped = points.map {
      CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
    }
    return smooth ? smoothPath(mapped) : polylinePath(mapped)
  }
}

/// A filled area under a smooth/straight line through normalized `points`,
/// closed down to the bottom of the draw rect. Pair with `areaGradient` for the
/// signature soft fade.
///
/// ```swift
/// SmoothAreaShape(points: normalized)
///   .fill(areaGradient(.tint))
/// ```
public struct SmoothAreaShape: Shape {
  /// Unit-square points (x,y in 0...1, y down), left to right.
  public var points: [CGPoint]
  /// Curve with a Catmull-Rom spline when true; straight segments when false.
  public var smooth: Bool

  public init(points: [CGPoint], smooth: Bool = true) {
    self.points = points
    self.smooth = smooth
  }

  public func path(in rect: CGRect) -> Path {
    guard points.count >= 2 else { return Path() }
    let mapped = points.map {
      CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
    }
    var path = smooth ? smoothPath(mapped) : polylinePath(mapped)
    path.addLine(to: CGPoint(x: mapped[mapped.count - 1].x, y: rect.maxY))
    path.addLine(to: CGPoint(x: mapped[0].x, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}
