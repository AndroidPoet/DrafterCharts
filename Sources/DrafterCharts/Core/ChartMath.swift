//
//  ChartMath.swift
//  DrafterCharts
//
//  Cross-chart math & layout helpers the inventory flagged for extraction so no
//  chart re-implements them: axis tick steps, cartesian/radial bounds, and text
//  alignment offsets. Pure value math — no SwiftUI state.
//

import CoreGraphics
import SwiftUI

// MARK: - Axis ticks

public enum ChartAxis {
  /// A "nice" grid step for a max value, chosen on a log-magnitude basis so
  /// ticks land on 1/2/5 multiples. Mirrors the Compose `calculateGridStep`.
  public static func gridStep(forMax maxValue: Double) -> Double {
    guard maxValue > 0, maxValue.isFinite else { return 1 }
    let magnitude = floor(log10(maxValue))
    let base = pow(10, magnitude)
    if maxValue / base > 5 { return base * 2 }
    if maxValue / base > 2 { return base }
    return base / 2
  }

  /// Evenly spaced tick values from 0...maxValue, inclusive, with `count` steps.
  public static func ticks(max maxValue: Double, count: Int) -> [Double] {
    guard count > 0 else { return [] }
    return (0...count).map { maxValue * Double($0) / Double(count) }
  }
}

// MARK: - Cartesian bounds

/// The inset plotting rectangle for a cartesian chart (line/bar/scatter).
public struct ChartBounds {
  public let rect: CGRect

  /// Insets `size` by a fractional `padding` on every edge (default 10%).
  public init(in size: CGSize, padding: CGFloat = 0.1) {
    let px = size.width * padding
    let py = size.height * padding
    rect = CGRect(x: px, y: py, width: size.width - px * 2, height: size.height - py * 2)
  }

  /// Insets `size` by explicit edge insets (use when axis labels need room).
  public init(in size: CGSize, left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {
    rect = CGRect(x: left, y: top, width: size.width - left - right, height: size.height - top - bottom)
  }

  public var left: CGFloat { rect.minX }
  public var top: CGFloat { rect.minY }
  public var right: CGFloat { rect.maxX }
  public var bottom: CGFloat { rect.maxY }
  public var width: CGFloat { rect.width }
  public var height: CGFloat { rect.height }
}

// MARK: - Radial layout

/// Center + radius for a radial chart (pie/gauge/radar/polar/sunburst).
public struct RadialLayout {
  public let center: CGPoint
  public let radius: CGFloat

  /// - Parameter scale: fraction of `min(width,height)/2` the radius fills.
  public init(in size: CGSize, scale: CGFloat = 0.8) {
    center = CGPoint(x: size.width / 2, y: size.height / 2)
    radius = min(size.width, size.height) / 2 * scale
  }

  /// The point on a ray at `angle` (radians, 0 = +x, clockwise as y grows down)
  /// at the given `distance` from center.
  public func point(angle: CGFloat, distance: CGFloat) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
  }
}

// MARK: - Text alignment

public enum ChartText {
  /// Horizontal anchor for a label drawn at an origin x.
  public enum HAlign { case start, center, end }

  /// The dx offset to apply to `origin.x` so a label of `textWidth` is anchored.
  public static func dx(_ align: HAlign, textWidth: CGFloat) -> CGFloat {
    switch align {
    case .start: return 0
    case .center: return -textWidth / 2
    case .end: return -textWidth
    }
  }
}
