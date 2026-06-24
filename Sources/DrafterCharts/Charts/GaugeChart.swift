//
//  GaugeChart.swift
//  DrafterCharts
//
//  Radial gauge: a 240° background track arc with an animated foreground arc
//  that sweeps to the value's fraction of the range, a knob at the arc tip, a
//  big centered value with an optional label, and min/max end labels. Ported
//  1:1 from the Compose `GaugeChartRenderer` geometry and animation.
//

import SwiftUI

/// Draws a gauge into a canvas: static track arc + animated value arc.
/// Holds a `value` within `[min, max]`, an optional `label`, and the accent
/// `color` used for the knob ring.
public struct GaugeChartRenderer: ChartRenderer {
  public let value: Float
  public let min: Float
  public let max: Float
  public let label: String
  public let color: Color

  public init(
    value: Float,
    min: Float = 0,
    max: Float = 100,
    label: String = "",
    color: Color = DrafterColors.teal
  ) {
    self.value = value
    self.min = min
    self.max = max
    self.label = label
    self.color = color
  }

  // Compose arc geometry: 0° = +x, clockwise (y down). 240° sweep starting at 150°.
  private let startAngleDeg: Double = 150
  private let sweepAngleDeg: Double = 240

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let layout = RadialLayout(in: size, scale: 0.82)
    let center = layout.center
    let radius = layout.radius
    guard radius > 0 else { return }

    let strokeWidth = radius * 0.16
    let arcRadius = radius - strokeWidth / 2
    let stroke = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)

    // Background track arc.
    var track = Path()
    track.addArc(
      center: center,
      radius: arcRadius,
      startAngle: .degrees(startAngleDeg),
      endAngle: .degrees(startAngleDeg + sweepAngleDeg),
      clockwise: false
    )
    context.stroke(track, with: .color(theme.grid), style: stroke)

    // Value fraction clamped to [0, 1], scaled by the reveal progress.
    let span = (max - min) == 0 ? 1 : (max - min)
    let rawFraction = clamp01(Double((value - min) / span))
    let fraction = rawFraction * clamp01(progress)
    let valueSweep = sweepAngleDeg * fraction

    if valueSweep > 0 {
      var valueArc = Path()
      valueArc.addArc(
        center: center,
        radius: arcRadius,
        startAngle: .degrees(startAngleDeg),
        endAngle: .degrees(startAngleDeg + valueSweep),
        clockwise: false
      )
      // Sweep gradient across the full palette for a premium multi-tone arc.
      let palette = DrafterColors.palette + [DrafterColors.palette.first ?? color]
      let gradient = GraphicsContext.Shading.conicGradient(
        Gradient(colors: palette),
        center: center,
        angle: .degrees(0)
      )
      context.stroke(valueArc, with: gradient, style: stroke)
    }

    // Knob at the tip of the value arc (white fill + colored ring).
    let tipAngle = CGFloat((startAngleDeg + valueSweep) * .pi / 180)
    let tip = layout.point(angle: tipAngle, distance: arcRadius)
    let knobRadius = strokeWidth * 0.42
    let knobRect = CGRect(x: tip.x - knobRadius, y: tip.y - knobRadius, width: knobRadius * 2, height: knobRadius * 2)
    context.fill(Path(ellipseIn: knobRect), with: .color(.white))
    context.stroke(Path(ellipseIn: knobRect), with: .color(color), lineWidth: 2)

    // Center value (big) + optional label below it, vertically centered as a block.
    let valueText = format(value)
    let valueFontSize = clamp(Double(radius) * 0.04, 20, 44)
    let valueColor: Color = theme.isDark ? .white : Color(hex: 0x1B1E25)
    let labelColor: Color = theme.isDark
      ? Color.white.opacity(0.72)
      : Color(hex: 0x1B1E25).opacity(0.6)

    let valueResolved = context.resolve(
      Text(valueText).font(.system(size: valueFontSize)).foregroundColor(valueColor)
    )
    let valueMeasured = valueResolved.measure(in: size)

    let hasLabel = !label.isEmpty
    var labelMeasured = CGSize.zero
    var labelResolved: GraphicsContext.ResolvedText?
    if hasLabel {
      let r = context.resolve(
        Text(label).font(.system(size: 13)).foregroundColor(labelColor)
      )
      labelResolved = r
      labelMeasured = r.measure(in: size)
    }

    let gap: CGFloat = 6
    let totalH = valueMeasured.height + (hasLabel ? labelMeasured.height + gap : 0)
    let blockTop = center.y - totalH / 2

    context.draw(
      valueResolved,
      at: CGPoint(x: center.x, y: blockTop + valueMeasured.height / 2),
      anchor: .center
    )
    if let labelResolved {
      context.draw(
        labelResolved,
        at: CGPoint(x: center.x, y: blockTop + valueMeasured.height + gap + labelMeasured.height / 2),
        anchor: .center
      )
    }

    // Min / max end labels just outside the arc ends.
    drawEndLabel(
      in: &context, text: format(min), angleDeg: startAngleDeg,
      center: center, arcRadius: arcRadius, strokeWidth: strokeWidth, color: theme.label
    )
    drawEndLabel(
      in: &context, text: format(max), angleDeg: startAngleDeg + sweepAngleDeg,
      center: center, arcRadius: arcRadius, strokeWidth: strokeWidth, color: theme.label
    )
  }

  /// VoiceOver: names this as a gauge.
  public var accessibilityLabel: String { "Gauge" }

  /// VoiceOver: the value and its position within the range.
  public var accessibilityValue: String {
    "\(label.isEmpty ? "value" : label) \(AccessibilityFormat.number(value)) of \(AccessibilityFormat.number(min)) to \(AccessibilityFormat.number(max))"
  }

  private func drawEndLabel(
    in context: inout GraphicsContext,
    text: String,
    angleDeg: Double,
    center: CGPoint,
    arcRadius: CGFloat,
    strokeWidth: CGFloat,
    color: Color
  ) {
    let rad = CGFloat(angleDeg * .pi / 180)
    let r = arcRadius + strokeWidth * 0.9
    let p = CGPoint(x: center.x + r * cos(rad), y: center.y + r * sin(rad))
    let label = Text(text).font(.system(size: 11)).foregroundColor(color)
    context.draw(label, at: p, anchor: .center)
  }

  private func format(_ value: Float) -> String {
    ChartFormatting.format(value, decimals: 2)
  }

  private func clamp01(_ v: Double) -> Double { clamp(v, 0, 1) }

  private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
    Swift.min(Swift.max(v, lo), hi)
  }
}

/// A radial gauge with a static track, an animated value arc, a tip knob, and
/// a centered value/label.
public struct GaugeChart: View {
  public let value: Float
  public let min: Float
  public let max: Float
  public let label: String
  public let color: Color
  public var animate: Bool
  public var replay: Int

  public init(
    value: Float,
    min: Float = 0,
    max: Float = 100,
    label: String = "",
    color: Color = DrafterColors.teal,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.value = value
    self.min = min
    self.max = max
    self.label = label
    self.color = color
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: GaugeChartRenderer(value: value, min: min, max: max, label: label, color: color),
      animate: animate,
      duration: 0.9,
      replay: replay
    )
  }
}
