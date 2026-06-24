//
//  LineChart.swift
//  DrafterCharts
//
//  The line-chart family ported from the Kotlin Compose `lines` package:
//
//    • Simple  — one smooth Catmull-Rom series with a soft gradient fill, a
//                left-to-right tracing reveal, and white-haloed vertex dots.
//    • Grouped — several overlaid smooth series, no fill so overlaps stay
//                legible, with vertex dots revealed in step with the trace.
//    • Stacked — cumulative filled bands drawn back-to-front with smooth
//                curves and soft gradients that grow vertically on reveal.
//
//  Single series take `[ChartPoint]` (label bound to value); multi-series take
//  `[ChartSeries]` (color bound to the series) plus optional x-axis `categories`,
//  so a label or color can never desync from its data. Mirrors `AreaChart.swift`.
//

import SwiftUI

// MARK: - Shared geometry

/// Plot rect using the Compose 10% inset on every edge (`size * 0.1`).
private func lineBounds(_ size: CGSize) -> ChartBounds {
  let left = size.width * 0.1
  let top = size.height * 0.1
  let chartWidth = size.width * 0.8
  let chartHeight = size.height * 0.8
  return ChartBounds(
    in: size,
    left: left,
    top: top,
    right: size.width - (left + chartWidth),
    bottom: size.height - (top + chartHeight)
  )
}

/// "Nice" grid step from a max value — the Compose `calculateGridStep`.
private func lineGridStep(_ maxValue: Double) -> Double {
  guard maxValue > 0 else { return 1 }
  let magnitude = floor(log10(maxValue))
  let baseStep = pow(10.0, magnitude)
  if maxValue / baseStep > 5 { return baseStep * 2 }
  if maxValue / baseStep > 2 { return baseStep }
  return baseStep / 2
}

/// Draws the faint Y grid + value labels and the X-axis labels, matching the
/// Compose `drawGridAndLabels` / `drawXAxisLabel` chrome. Shared by all variants.
private func drawLineChrome(
  in context: inout GraphicsContext,
  bounds: ChartBounds,
  categories rawLabels: [String],
  pointCount: Int,
  maxValue: Double,
  theme: DrafterThemeColors
) {
  // Pad/truncate categories to the number of plotted x-points so the x-axis
  // labels line up with the vertices regardless of how many were supplied.
  let labels = normalizedLabels(rawLabels, count: pointCount)
  // Y grid + value labels: one line per "nice" step up to maxValue.
  if maxValue > 0 {
    let step = lineGridStep(maxValue)
    let numSteps = Int(maxValue / step)
    if numSteps >= 0 {
      for i in 0...max(numSteps, 0) {
        let value = Double(i) * step
        let ratio = value / maxValue
        let y = bounds.bottom - CGFloat(ratio) * bounds.height

        var line = Path()
        line.move(to: CGPoint(x: bounds.left, y: y))
        line.addLine(to: CGPoint(x: bounds.left + bounds.width, y: y))
        context.stroke(line, with: .color(theme.grid), lineWidth: 1)

        let label = Text(String(Int(value))).font(.system(size: 9)).foregroundColor(theme.label)
        context.draw(label, at: CGPoint(x: bounds.left - 6, y: y), anchor: .trailing)
      }
    }
  }

  // X-axis labels, evenly spaced across the plot width — thinned so they stay
  // legible at small sizes (at most ~6).
  guard labels.count > 1 else { return }
  let maxLabels = 6
  let labelStride = max(1, (labels.count + maxLabels - 1) / maxLabels)
  for (index, label) in labels.enumerated() where index % labelStride == 0 && !label.isEmpty {
    let x = bounds.left + CGFloat(index) * (bounds.width / CGFloat(labels.count - 1))
    let text = Text(label).font(.system(size: 9)).foregroundColor(theme.label)
    context.draw(text, at: CGPoint(x: x, y: bounds.bottom + 14), anchor: .center)
  }
}

// MARK: - Simple

/// Draws a single smooth series from `[ChartPoint]`: curve, gradient fill, reveal, dots.
public struct LineChartRenderer: ChartRenderer {
  public let points: [ChartPoint]
  public let color: Color

  public init(points: [ChartPoint], color: Color = DrafterColors.blue) {
    self.points = points
    self.color = color
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let values = points.map { $0.value }
    let maxValue = Double(values.max() ?? 0)
    let bounds = lineBounds(size)

    drawLineChrome(in: &context, bounds: bounds, categories: points.map { $0.label }, pointCount: values.count, maxValue: maxValue, theme: theme)

    guard values.count >= 2, maxValue > 0 else { return }

    let pixelPoints: [CGPoint] = values.enumerated().map { index, value in
      let x = bounds.left + bounds.width * CGFloat(index) / CGFloat(values.count - 1)
      let y = bounds.bottom - CGFloat(Double(value) / maxValue) * bounds.height
      return CGPoint(x: x, y: y)
    }

    drawSmoothLine(
      in: &context,
      points: pixelPoints,
      color: color,
      baseline: bounds.bottom,
      progress: progress,
      strokeWidth: 6,
      fill: true,
      endDot: true,
      smooth: true
    )
  }
}

// MARK: - Grouped (overlaid multi-series)

/// Draws overlaid smooth series with no fill; vertex dots reveal with the trace.
public struct GroupedLineChartRenderer: ChartRenderer {
  public let series: [ChartSeries]
  public let categories: [String]

  public init(series: [ChartSeries], categories: [String] = []) {
    self.series = series
    self.categories = categories
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let maxValue = Double(series.flatMap { $0.values }.max() ?? 0)
    let bounds = lineBounds(size)

    // x-points are driven by the series' value arrays (widest series), not labels.
    let numPoints = series.map { $0.values.count }.max() ?? 0
    drawLineChrome(in: &context, bounds: bounds, categories: categories, pointCount: numPoints, maxValue: maxValue, theme: theme)

    guard numPoints >= 2, maxValue > 0, !series.isEmpty else { return }

    let xPositions: [CGFloat] = (0..<numPoints).map { index in
      bounds.left + CGFloat(index) * (bounds.width / CGFloat(numPoints - 1))
    }
    let clamped = CGFloat(min(max(progress, 0), 1))
    let span = (xPositions.last ?? 0) - (xPositions.first ?? 0)
    let revealRight = (xPositions.first ?? 0) + span * clamped

    for line in series {
      let color = line.color
      let pixelPoints: [CGPoint] = (0..<numPoints).map { index in
        let value = line.values.indices.contains(index) ? line.values[index] : 0
        let y = bounds.bottom - CGFloat(Double(value) / maxValue) * bounds.height
        return CGPoint(x: xPositions[index], y: y)
      }

      drawSmoothLine(
        in: &context,
        points: pixelPoints,
        color: color,
        baseline: bounds.bottom,
        progress: progress,
        strokeWidth: 5,
        fill: false,
        endDot: false,
        smooth: true
      )

      for point in pixelPoints where point.x <= revealRight + 0.5 {
        drawVertexDot(in: &context, center: point, color: color, radius: 5)
      }
    }
  }
}

// MARK: - Stacked (stacked filled areas)

/// Draws cumulative smooth filled bands that grow vertically with the reveal.
/// Each `ChartSeries` is one stacked level (bottom-to-top in array order).
public struct StackedLineChartRenderer: ChartRenderer {
  public let series: [ChartSeries]
  public let categories: [String]

  public init(series: [ChartSeries], categories: [String] = []) {
    self.series = series
    self.categories = categories
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let numPoints = series.map { $0.values.count }.max() ?? 0
    // Per-x totals across all levels give the max stacked height.
    let totals: [Float] = (0..<numPoints).map { i in
      series.reduce(0) { $0 + ($1.values.indices.contains(i) ? $1.values[i] : 0) }
    }
    let maxValue = Double(totals.max() ?? 0)
    let bounds = lineBounds(size)

    drawLineChrome(in: &context, bounds: bounds, categories: categories, pointCount: numPoints, maxValue: maxValue, theme: theme)

    guard numPoints >= 2, maxValue > 0, !series.isEmpty else { return }
    let baseline = bounds.bottom
    let stackCount = series.count

    let xPositions: [CGFloat] = (0..<numPoints).map { index in
      bounds.left + CGFloat(index) * (bounds.width / CGFloat(numPoints - 1))
    }

    // cumulative[k][i] = sum of levels 0...k at x-index i.
    let cumulative: [[Float]] = (0..<stackCount).map { k in
      (0..<numPoints).map { i in
        var sum: Float = 0
        for s in 0...k {
          let values = series[s].values
          if values.indices.contains(i) { sum += values[i] }
        }
        return sum
      }
    }

    // Back-to-front: top level first so each band shows above the one below.
    for stackIndex in stride(from: stackCount - 1, through: 0, by: -1) {
      let color = series[stackIndex].color
      let topPoints: [CGPoint] = (0..<numPoints).map { i in
        let ratio = (Double(cumulative[stackIndex][i]) * progress) / maxValue
        let y = baseline - CGFloat(ratio) * bounds.height
        return CGPoint(x: xPositions[i], y: y)
      }

      let curve = smoothPath(topPoints)
      var fillPath = curve
      fillPath.addLine(to: CGPoint(x: topPoints[topPoints.count - 1].x, y: baseline))
      fillPath.addLine(to: CGPoint(x: topPoints[0].x, y: baseline))
      fillPath.closeSubpath()

      let topY = topPoints.map(\.y).min() ?? baseline
      context.fill(
        fillPath,
        with: .linearGradient(
          Gradient(stops: [
            .init(color: color.opacity(0.85), location: 0),
            .init(color: color.opacity(0.85 * 0.45), location: 0.5),
            .init(color: color.opacity(0), location: 1),
          ]),
          startPoint: CGPoint(x: 0, y: topY),
          endPoint: CGPoint(x: 0, y: baseline)
        )
      )
      context.stroke(
        curve,
        with: .color(color),
        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
      )
    }
  }
}

// MARK: - Views

/// A smooth single-series line chart with a soft gradient fill and reveal.
public struct LineChart: View {
  public let points: [ChartPoint]
  public let color: Color
  public var animate: Bool
  public var replay: Int

  public init(points: [ChartPoint], color: Color = DrafterColors.blue, animate: Bool = true, replay: Int = 0) {
    self.points = points
    self.color = color
    self.animate = animate
    self.replay = replay
  }

  /// Convenience for unlabeled data: one value per point, blank x-axis labels.
  public init(values: [Float], color: Color = DrafterColors.blue, animate: Bool = true, replay: Int = 0) {
    self.init(points: values.map(ChartPoint.init), color: color, animate: animate, replay: replay)
  }

  public var body: some View {
    ChartCanvas(renderer: LineChartRenderer(points: points, color: color), animate: animate, duration: 1.1, replay: replay)
  }
}

/// Overlaid multi-series smooth lines with revealed vertex dots.
public struct GroupedLineChart: View {
  public let series: [ChartSeries]
  public let categories: [String]
  public var animate: Bool
  public var replay: Int

  public init(series: [ChartSeries], categories: [String] = [], animate: Bool = true, replay: Int = 0) {
    self.series = series
    self.categories = categories
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: GroupedLineChartRenderer(series: series, categories: categories),
      animate: animate, duration: 1.1, replay: replay
    )
  }
}

/// Stacked filled areas that grow vertically with the reveal.
public struct StackedLineChart: View {
  public let series: [ChartSeries]
  public let categories: [String]
  public var animate: Bool
  public var replay: Int

  public init(series: [ChartSeries], categories: [String] = [], animate: Bool = true, replay: Int = 0) {
    self.series = series
    self.categories = categories
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: StackedLineChartRenderer(series: series, categories: categories),
      animate: animate, duration: 1.1, replay: replay
    )
  }
}
