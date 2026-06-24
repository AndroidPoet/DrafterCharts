//
//  FunnelChart.swift
//  DrafterCharts
//
//  Stacked horizontal funnel: each stage is a trapezoid whose top width is
//  proportional to its value and whose bottom width matches the next stage,
//  so the bands converge toward the center top-to-bottom. Fills expand outward
//  from the center as the reveal progresses, with a vertical gradient and a soft
//  white top highlight; centered label + value fade in past the midpoint.
//

import SwiftUI

/// One stage (band) of a `FunnelChart`: a `label`, a `value`, and a fill `color`.
public struct FunnelStage: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color

  public init(label: String, value: Float, color: Color) {
    self.label = label
    self.value = value
    self.color = color
  }
}

/// Draws an ordered list of `FunnelStage`s as stacked, center-converging
/// trapezoids into a canvas.
public struct FunnelChartRenderer: ChartRenderer {
  public let stages: [FunnelStage]
  public init(stages: [FunnelStage]) { self.stages = stages }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard !stages.isEmpty else { return }

    // Matches Compose FunnelChart host insets (0.1 / 0.08 / 0.8 / 0.84).
    let chartLeft = size.width * 0.1
    let chartTop = size.height * 0.08
    let chartWidth = size.width * 0.8
    let chartHeight = size.height * 0.84

    let maxValue = CGFloat(stages.map(\.value).max() ?? 1)
    let safeMax = maxValue > 0 ? maxValue : 1
    let centerX = chartLeft + chartWidth / 2
    let gap = chartHeight * 0.02
    let count = stages.count
    let bandHeight = (chartHeight - gap * CGFloat(count - 1)) / CGFloat(count)
    // The narrowest band keeps a sensible minimum width so it never pinches to nothing.
    let minWidthFraction: CGFloat = 0.12

    func widthFor(_ value: Float) -> CGFloat {
      let fraction = minWidthFraction + (1 - minWidthFraction) * (CGFloat(value) / safeMax)
      return chartWidth * fraction
    }

    let prog = CGFloat(min(max(progress, 0), 1))
    let labelColor = theme.label

    for (index, stage) in stages.enumerated() {
      let topFull = widthFor(stage.value)
      let bottomValue = index < count - 1 ? stages[index + 1].value : stage.value
      let bottomFull = widthFor(bottomValue)

      // Widths expand outward from the center with the reveal.
      let topHalf = (topFull / 2) * prog
      let bottomHalf = (bottomFull / 2) * prog

      let bandTop = chartTop + CGFloat(index) * (bandHeight + gap)
      let bandBottom = bandTop + bandHeight

      var path = Path()
      path.move(to: CGPoint(x: centerX - topHalf, y: bandTop))
      path.addLine(to: CGPoint(x: centerX + topHalf, y: bandTop))
      path.addLine(to: CGPoint(x: centerX + bottomHalf, y: bandBottom))
      path.addLine(to: CGPoint(x: centerX - bottomHalf, y: bandBottom))
      path.closeSubpath()

      let gradient = Gradient(colors: [
        stage.color.opacity(0.95 * progress),
        stage.color.opacity(0.7 * progress),
      ])
      context.fill(
        path,
        with: .linearGradient(
          gradient,
          startPoint: CGPoint(x: centerX, y: bandTop),
          endPoint: CGPoint(x: centerX, y: bandBottom)
        )
      )

      // Soft top highlight for a rounded, premium feel.
      var highlight = Path()
      highlight.move(to: CGPoint(x: centerX - topHalf, y: bandTop))
      highlight.addLine(to: CGPoint(x: centerX + topHalf, y: bandTop))
      context.stroke(highlight, with: .color(Color.white.opacity(0.22 * progress)), lineWidth: 1.5)

      if progress > 0.55 {
        let centerY = bandTop + bandHeight / 2
        let labelText = Text(stage.label).font(.system(size: 13)).foregroundColor(labelColor)
        let valueText = Text(ChartFormatting.format(stage.value, decimals: 2))
          .font(.system(size: 11))
          .foregroundColor(labelColor.opacity(0.74))

        let labelSize = context.resolve(labelText).measure(in: size)
        let valueSize = context.resolve(valueText).measure(in: size)
        let totalH = labelSize.height + valueSize.height + 2
        let topY = centerY - totalH / 2

        context.draw(labelText, at: CGPoint(x: centerX, y: topY + labelSize.height / 2), anchor: .center)
        context.draw(
          valueText,
          at: CGPoint(x: centerX, y: topY + labelSize.height + 2 + valueSize.height / 2),
          anchor: .center
        )
      }
    }
  }

  /// VoiceOver: names this as a funnel chart.
  public var accessibilityLabel: String { "Funnel chart" }

  /// VoiceOver: the stage count and each stage's label/value.
  public var accessibilityValue: String {
    stages.isEmpty ? "No data" : "\(stages.count) stages, \(AccessibilityFormat.points(stages.map { ($0.label, $0.value) }))"
  }
}

/// A stacked, center-converging funnel chart with an animated outward reveal.
public struct FunnelChart: View {
  public let stages: [FunnelStage]
  public var animate: Bool
  public var replay: Int

  public init(stages: [FunnelStage], animate: Bool = true, replay: Int = 0) {
    self.stages = stages
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: FunnelChartRenderer(stages: stages), animate: animate, duration: 0.9, replay: replay)
  }
}
