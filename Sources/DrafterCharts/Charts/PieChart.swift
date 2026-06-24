//
//  PieChart.swift
//  DrafterCharts
//
//  The pie chart family: a filled `Pie` of wedge slices that meet at the center,
//  and a `Donut` of stroked arcs around a hollow core. Both sweep their arcs in
//  proportionally to each slice's share of the total, draw a surface-colored
//  separator between slices, and label slices that own at least 5% of the total.
//  Mirrors the `AreaChart` pattern: an immutable data struct, pure
//  `ChartRenderer`s, and thin views that host them in `ChartCanvas`.
//

import SwiftUI

/// Data for a `PieChart` / `DonutChart`: a list of weighted, colored slices.
public struct PieChartData: Equatable, Sendable {
  /// One wedge of the pie: its weight, fill color, and a legend label.
  public struct Slice: Equatable, Sendable {
    public var value: Float
    public var color: Color
    public var label: String

    public init(value: Float, color: Color, label: String) {
      self.value = value
      self.color = color
      self.label = label
    }
  }

  public var slices: [Slice]

  public init(slices: [Slice]) {
    self.slices = slices
  }
}

// MARK: - Shared geometry

/// The total of all slice values, floored at 1 so a single empty dataset can't
/// divide by zero (matches the Compose `max(sum, 1f)`).
private func pieTotal(_ slices: [PieChartData.Slice]) -> Float {
  max(slices.reduce(Float(0)) { $0 + $1.value }, 1)
}

/// Degrees → radians.
private func radians(_ degrees: CGFloat) -> CGFloat { degrees * .pi / 180 }

/// The wedge label: an integer percent, white-on-dark or black-on-light.
private func percentLabel(_ percent: Double, color: Color) -> Text {
  Text("\(Int(percent))%").font(.system(size: 12, weight: .bold)).foregroundColor(color)
}

// MARK: - Pie

/// Draws a `PieChartData` as solid wedges that meet at the center.
public struct PieChartRenderer: ChartRenderer {
  public let data: PieChartData
  public let labelThreshold: Float

  public init(data: PieChartData, labelThreshold: Float = 5) {
    self.data = data
    self.labelThreshold = labelThreshold
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let slices = data.slices
    guard !slices.isEmpty else { return }

    let total = pieTotal(slices)
    let layout = RadialLayout(in: size, scale: 0.7)
    let center = layout.center
    let radius = layout.radius
    // The separator carving slices apart picks up the surrounding surface color.
    let separator = theme.surface
    // Labels sit on the fill, so they invert against it.
    let labelColor: Color = theme.isDark ? .black : .white

    var startAngle: CGFloat = -90  // 12 o'clock, sweeping clockwise.

    for slice in slices {
      let fraction = slice.value / total
      let sweep = CGFloat(fraction) * 360 * CGFloat(progress)
      guard sweep > 0 else { startAngle += sweep; continue }

      let a0 = radians(startAngle)
      let a1 = radians(startAngle + sweep)

      // Wedge: arc out to the rim and back to the center.
      var wedge = Path()
      wedge.move(to: center)
      wedge.addArc(center: center, radius: radius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
      wedge.closeSubpath()
      context.fill(wedge, with: .color(slice.color))

      // Thin surface-colored outline carves a clean gap between slices.
      context.stroke(wedge, with: .color(separator), lineWidth: 2.5)

      let percent = Double(fraction) * 100
      if percent >= Double(labelThreshold) {
        let mid = radians(startAngle + sweep / 2)
        let p = layout.point(angle: mid, distance: radius * 0.7)
        context.draw(percentLabel(percent, color: labelColor), at: p, anchor: .center)
      }

      startAngle += sweep
    }
  }
}

/// A solid pie chart whose wedges sweep in proportionally on reveal.
public struct PieChart: View {
  public let data: PieChartData
  public var animate: Bool
  public var replay: Int

  public init(data: PieChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: PieChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Donut

/// Draws a `PieChartData` as stroked arcs around a hollow center.
public struct DonutChartRenderer: ChartRenderer {
  public let data: PieChartData
  public let labelThreshold: Float
  public let holeRadiusFraction: CGFloat

  public init(data: PieChartData, labelThreshold: Float = 5, holeRadiusFraction: CGFloat = 0.5) {
    self.data = data
    self.labelThreshold = labelThreshold
    self.holeRadiusFraction = holeRadiusFraction
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let slices = data.slices
    guard !slices.isEmpty else { return }

    let total = pieTotal(slices)
    let layout = RadialLayout(in: size, scale: 0.6)
    let center = layout.center
    let outerRadius = layout.radius
    let innerRadius = outerRadius * holeRadiusFraction
    // The band is stroked along the mid-line of the ring at this width.
    let bandRadius = (outerRadius + innerRadius) / 2
    let bandWidth = outerRadius - innerRadius
    // Labels sit outside the ring, on the surface, so they match foreground chrome.
    let labelColor: Color = theme.isDark ? .white : .black

    let gap: CGFloat = 2
    var startAngle: CGFloat = -90

    for slice in slices {
      let fraction = slice.value / total
      let sweep = CGFloat(fraction) * 360 * CGFloat(progress)
      // Inset each arc by a small gap and round its caps for a modern donut.
      let drawSweep = max(sweep - gap, 0)
      if drawSweep > 0 {
        let a0 = radians(startAngle + gap / 2)
        let a1 = radians(startAngle + gap / 2 + drawSweep)
        var arc = Path()
        arc.addArc(center: center, radius: bandRadius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
        context.stroke(arc, with: .color(slice.color), style: StrokeStyle(lineWidth: bandWidth, lineCap: .round))
      }

      let percent = Double(fraction) * 100
      if percent >= Double(labelThreshold) && sweep > 0 {
        let mid = radians(startAngle + sweep / 2)
        // Sit the label just outside the ring. The demo card is short (~200pt),
        // so keep the label ring well inside the canvas to avoid top/bottom
        // clipping while still clearing the band (outer ring ends at 1.0).
        let pushed = outerRadius * 1.22
        let p = layout.point(angle: mid, distance: pushed)
        context.draw(percentLabel(percent, color: labelColor), at: p, anchor: .center)
      }

      startAngle += sweep
    }
  }
}

/// A donut chart: stroked arcs around a hollow center, sweeping in on reveal.
public struct DonutChart: View {
  public let data: PieChartData
  public var animate: Bool
  public var replay: Int

  public init(data: PieChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: DonutChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}
