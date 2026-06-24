//
//  BoxPlotChart.swift
//  DrafterCharts
//
//  Box-and-whisker chart: one column per group showing min/q1/median/q3/max.
//  Each group draws a vertical whisker (min..max) with end caps, a translucent
//  rounded box (q1..q3) with a stroked outline, and a bold median line. The
//  whiskers and box grow outward from the median line on reveal; the Y axis is
//  auto-scaled across all groups and group labels run along the X axis.
//

import SwiftUI

/// A single box-and-whisker group: five-number summary plus a draw color.
public struct BoxGroup: Equatable, Sendable {
  public var label: String
  public var min: Float
  public var q1: Float
  public var median: Float
  public var q3: Float
  public var max: Float
  public var color: Color

  public init(
    label: String,
    min: Float,
    q1: Float,
    median: Float,
    q3: Float,
    max: Float,
    color: Color = DrafterColors.violet
  ) {
    self.label = label
    self.min = min
    self.q1 = q1
    self.median = median
    self.q3 = q3
    self.max = max
    self.color = color
  }
}

/// Data for a `BoxPlotChart`: a list of box-and-whisker `groups`.
public struct BoxPlotData: Equatable, Sendable {
  public var groups: [BoxGroup]

  public init(groups: [BoxGroup]) {
    self.groups = groups
  }
}

/// Draws a `BoxPlotData` into a canvas.
public struct BoxPlotChartRenderer: ChartRenderer {
  public let data: BoxPlotData
  public init(data: BoxPlotData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let groups = data.groups
    guard !groups.isEmpty else { return }

    // Match the Compose layout: ~10% inset on every side, but floor the left
    // inset so Y axis labels never clip off the left edge at small sizes.
    let leftInset = Swift.max(size.width * 0.1, 34)
    let edgeY = size.height * 0.1
    let bounds = ChartBounds(in: size, left: leftInset, top: edgeY, right: size.width * 0.1, bottom: edgeY)
    let chartBottom = bounds.bottom

    // Global value range across all groups.
    let globalMin = Double(groups.map { $0.min }.min() ?? 0)
    let globalMax = Double(groups.map { $0.max }.max() ?? 1)
    let range = max(globalMax - globalMin, 0.0001)

    func valueToY(_ value: Float) -> CGFloat {
      chartBottom - CGFloat((Double(value) - globalMin) / range) * bounds.height
    }

    // Gridlines + y labels.
    let gridLines = 5
    for i in 0...gridLines {
      let fraction = Double(i) / Double(gridLines)
      let value = globalMin + fraction * range
      let y = chartBottom - CGFloat(fraction) * bounds.height
      var line = Path()
      line.move(to: CGPoint(x: bounds.left, y: y))
      line.addLine(to: CGPoint(x: bounds.right, y: y))
      context.stroke(line, with: .color(theme.grid), lineWidth: 1)

      let text = Text(ChartFormatting.format(Float(value)))
        .font(.system(size: 10))
        .foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: bounds.left - 6, y: y), anchor: .trailing)
    }

    // Distribute group columns evenly across the width.
    let columnWidth = bounds.width / CGFloat(groups.count)
    let boxWidth = Swift.min(columnWidth * 0.45, 70)

    let p = CGFloat(Swift.min(Swift.max(progress, 0), 1))

    for (index, group) in groups.enumerated() {
      let centerX = bounds.left + columnWidth * (CGFloat(index) + 0.5)

      let yMin = valueToY(group.min)
      let yMedian = valueToY(group.median)
      let yQ1 = valueToY(group.q1)
      let yQ3 = valueToY(group.q3)
      let yMax = valueToY(group.max)

      // Whiskers extend out from the median line.
      let whiskerTopY = yMedian + (yMax - yMedian) * p
      let whiskerBottomY = yMedian + (yMin - yMedian) * p
      var whisker = Path()
      whisker.move(to: CGPoint(x: centerX, y: whiskerTopY))
      whisker.addLine(to: CGPoint(x: centerX, y: whiskerBottomY))
      context.stroke(whisker, with: .color(group.color), lineWidth: 2)

      // Caps at min and max.
      let capHalf = boxWidth * 0.3
      var caps = Path()
      caps.move(to: CGPoint(x: centerX - capHalf, y: whiskerTopY))
      caps.addLine(to: CGPoint(x: centerX + capHalf, y: whiskerTopY))
      caps.move(to: CGPoint(x: centerX - capHalf, y: whiskerBottomY))
      caps.addLine(to: CGPoint(x: centerX + capHalf, y: whiskerBottomY))
      context.stroke(caps, with: .color(group.color), lineWidth: 2)

      // Box grows vertically out from the median line.
      let boxTopY = yMedian + (yQ3 - yMedian) * p
      let boxBottomY = yMedian + (yQ1 - yMedian) * p
      let boxLeft = centerX - boxWidth / 2
      let boxTop = Swift.min(boxTopY, boxBottomY)
      let boxHeight = abs(boxBottomY - boxTopY)
      let boxRect = CGRect(x: boxLeft, y: boxTop, width: boxWidth, height: boxHeight)
      let boxPath = Path(roundedRect: boxRect, cornerRadius: 8)

      context.fill(boxPath, with: .color(group.color.opacity(0.35)))
      context.stroke(boxPath, with: .color(group.color), lineWidth: 2)

      // Bold median line across the box (always at the median position).
      var median = Path()
      median.move(to: CGPoint(x: boxLeft, y: yMedian))
      median.addLine(to: CGPoint(x: boxLeft + boxWidth, y: yMedian))
      context.stroke(median, with: .color(group.color), lineWidth: 3.5)

      // X label under each box.
      let label = Text(group.label)
        .font(.system(size: 10))
        .foregroundColor(theme.label)
      context.draw(label, at: CGPoint(x: centerX, y: chartBottom + 12), anchor: .top)
    }
  }
}

/// A box-and-whisker chart with whiskers, translucent boxes, and median lines
/// that grow out from the median on an animated reveal.
public struct BoxPlotChart: View {
  public let data: BoxPlotData
  public var animate: Bool
  public var replay: Int

  public init(data: BoxPlotData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: BoxPlotChartRenderer(data: data), animate: animate, duration: 0.9, replay: replay)
  }
}
