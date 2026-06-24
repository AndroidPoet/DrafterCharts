//
//  BarChart.swift
//  DrafterCharts
//
//  The bar chart family ported from the Kotlin Compose library: Simple,
//  Grouped (side-by-side), Stacked, Histogram, and Waterfall. Each variant has
//  an immutable data struct, a `ChartRenderer` that owns its geometry, and a
//  thin view that hosts it in `ChartCanvas`. Bars grow from the baseline with
//  the reveal (`height * progress`), share a 5-tick Y grid + axis labels, and
//  center X labels under each group. Layout mirrors the Compose `BarChart`
//  scaffold: a 15% horizontal padding plot box, a per-renderer bar/spacing
//  algorithm, and rounded-corner bars with a soft vertical gradient.
//

import SwiftUI

// MARK: - Shared layout

/// The plot geometry shared by every bar variant, mirroring the Compose
/// `calculateChartDimensions`: 15% horizontal padding, 70% tall plot box.
private struct BarLayout {
  let chartLeft: CGFloat
  let chartTop: CGFloat
  let chartBottom: CGFloat
  let chartWidth: CGFloat
  let chartHeight: CGFloat

  init(size: CGSize) {
    let padding = size.width * 0.15
    chartHeight = size.height * 0.7
    chartTop = size.height * 0.15
    chartBottom = size.height * 0.15 + chartHeight
    chartLeft = padding
    chartWidth = size.width - padding * 2
  }
}

/// The per-variant bar layout + drawing strategy. Mirrors the Kotlin
/// `BarChartDataRenderer` interface so each variant supplies labels, scaling,
/// and a `drawGroup` for its own grouped/stacked/waterfall logic.
private protocol BarVariant {
  var labels: [String] { get }
  var barsPerGroup: Int { get }
  func maxValue() -> Float
  /// Returns (barWidth, groupSpacing) clamped to be non-negative.
  func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat)
  /// The on-screen width of a single group (bars + their internal spacing).
  func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat
  func drawGroup(
    in context: inout GraphicsContext,
    index: Int,
    left: CGFloat,
    barWidth: CGFloat,
    groupSpacing: CGFloat,
    chartBottom: CGFloat,
    chartHeight: CGFloat,
    maxValue: Float,
    progress: Double
  )
}

/// Draws a rounded-top bar with a soft top-to-bottom gradient (the premium
/// look from the Compose simple-bar renderer), used by every variant for
/// visual consistency.
private func drawBar(
  in context: inout GraphicsContext,
  rect: CGRect,
  color: Color,
  cornerRadius: CGFloat
) {
  guard rect.height > 0, rect.width > 0 else { return }
  let path = Path(roundedRect: rect, cornerRadius: min(cornerRadius, rect.width / 2))
  let gradient = Gradient(colors: [color, color.opacity(0.72)])
  context.fill(
    path,
    with: .linearGradient(
      gradient,
      startPoint: CGPoint(x: rect.midX, y: rect.minY),
      endPoint: CGPoint(x: rect.midX, y: rect.maxY)
    )
  )
}

/// The shared scaffold that draws the Y grid (5 ticks) + Y labels, walks the
/// groups, and centers X labels under each group. Pure SwiftUI; the variant
/// supplies all data-specific geometry.
private func drawBarChart(
  _ variant: BarVariant,
  in context: inout GraphicsContext,
  size: CGSize,
  theme: DrafterThemeColors,
  progress: Double
) {
  guard size.width >= 1, size.height >= 1 else { return }
  let labels = variant.labels
  guard !labels.isEmpty else { return }

  let layout = BarLayout(size: size)
  let barsPerGroup = variant.barsPerGroup
  let maxValue = max(variant.maxValue(), 1e-6)

  // Baseline axis.
  var axis = Path()
  axis.move(to: CGPoint(x: layout.chartLeft, y: layout.chartBottom))
  axis.addLine(to: CGPoint(x: layout.chartLeft + layout.chartWidth, y: layout.chartBottom))
  context.stroke(axis, with: .color(theme.grid), lineWidth: 1.5)

  // Y grid + labels (5 steps).
  let steps = 5
  for i in 0...steps {
    let value = maxValue / Float(steps) * Float(i)
    let y = layout.chartBottom - CGFloat(value / maxValue) * layout.chartHeight
    var grid = Path()
    grid.move(to: CGPoint(x: layout.chartLeft, y: y))
    grid.addLine(to: CGPoint(x: size.width, y: y))
    context.stroke(grid, with: .color(theme.grid), lineWidth: 1)

    let rounded = Float(Int(value * 10)) / 10
    let label = Text(rounded.description).font(.system(size: 9)).foregroundColor(theme.label)
    context.draw(label, at: CGPoint(x: layout.chartLeft - 6, y: y), anchor: .trailing)
  }

  // Bar/spacing geometry.
  let (barWidth, groupSpacing) = variant.barAndSpacing(
    chartWidth: layout.chartWidth,
    dataSize: labels.count,
    barsPerGroup: barsPerGroup
  )
  let groupWidth = variant.groupWidth(barWidth: barWidth, barsPerGroup: barsPerGroup)

  // Bars, group by group, growing from the baseline with the reveal.
  var currentLeft = layout.chartLeft
  for index in labels.indices {
    variant.drawGroup(
      in: &context,
      index: index,
      left: currentLeft,
      barWidth: barWidth,
      groupSpacing: groupSpacing,
      chartBottom: layout.chartBottom,
      chartHeight: layout.chartHeight,
      maxValue: maxValue,
      progress: progress
    )
    currentLeft += groupWidth + groupSpacing
  }

  // X labels, centered under each group. At small sizes, thin out dense labels
  // and truncate long ones so they don't overlap or clip past the canvas.
  currentLeft = layout.chartLeft
  // Budget ~36pt per label; show every Nth label if they'd collide.
  let slot = groupWidth + groupSpacing
  let stride = slot > 0 ? max(1, Int(ceil(36 / slot))) : 1
  for (i, label) in labels.enumerated() {
    let centerX = currentLeft + groupWidth / 2
    currentLeft += slot
    guard i % stride == 0 else { continue }
    let shown = label.count > 8 ? String(label.prefix(7)) + "…" : label
    let text = Text(shown).font(.system(size: 9)).foregroundColor(theme.label)
    context.draw(text, at: CGPoint(x: centerX, y: layout.chartBottom + 6), anchor: .top)
  }
}

// MARK: - Simple

/// Data for a `SimpleBarChart`: one bar per label, parallel `values`/`colors`.
public struct SimpleBarChartData: Equatable, Sendable {
  public var labels: [String]
  public var values: [Float]
  public var colors: [Color]

  public init(labels: [String], values: [Float], colors: [Color] = DrafterColors.palette) {
    self.labels = labels
    self.values = values
    self.colors = colors
  }
}

/// Draws a `SimpleBarChartData`: single rounded, gradient-filled bars.
public struct SimpleBarChartRenderer: ChartRenderer {
  public let data: SimpleBarChartData
  public init(data: SimpleBarChartData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(data: data, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let data: SimpleBarChartData
    let theme: DrafterThemeColors
    var labels: [String] { data.labels }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float { data.values.max() ?? 0 }

    func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat) {
      guard dataSize > 0 else { return (0, 0) }
      let totalSpacing = chartWidth * 0.1
      let groupSpacing = totalSpacing / CGFloat(dataSize + 1)
      let availableWidth = chartWidth - totalSpacing
      let barWidth = availableWidth / CGFloat(dataSize)
      return (max(barWidth, 0), max(groupSpacing, 0))
    }

    func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat { barWidth }

    func drawGroup(
      in context: inout GraphicsContext, index: Int, left: CGFloat, barWidth: CGFloat,
      groupSpacing: CGFloat, chartBottom: CGFloat, chartHeight: CGFloat, maxValue: Float, progress: Double
    ) {
      guard index < data.values.count else { return }
      let value = data.values[index]
      let barHeight = CGFloat(value / maxValue) * chartHeight * CGFloat(progress)
      guard barHeight > 0 else { return }
      let color = data.colors.indices.contains(index) ? data.colors[index] : theme.color(at: index)
      // Slim the bar for breathing room and round the top corners.
      let inset = barWidth * 0.16
      let drawWidth = barWidth - inset * 2
      let rect = CGRect(x: left + inset, y: chartBottom - barHeight, width: drawWidth, height: barHeight)
      drawBar(in: &context, rect: rect, color: color, cornerRadius: drawWidth * 0.4)
    }
  }
}

/// A simple bar chart: one rounded, gradient-filled bar per label.
public struct SimpleBarChart: View {
  public let data: SimpleBarChartData
  public var animate: Bool
  public var replay: Int

  public init(data: SimpleBarChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: SimpleBarChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Grouped

/// Data for a `GroupedBarChart`: side-by-side bars per label.
///
/// - `groupedValues[i]` holds one value per item for group `i`.
/// - `colors` are indexed by item (column), not by group.
public struct GroupedBarChartData: Equatable, Sendable {
  public var labels: [String]
  public var itemNames: [String]
  public var groupedValues: [[Float]]
  public var colors: [Color]

  public init(labels: [String], itemNames: [String], groupedValues: [[Float]], colors: [Color] = DrafterColors.palette) {
    self.labels = labels
    self.itemNames = itemNames
    self.groupedValues = groupedValues
    self.colors = colors
  }
}

/// Draws a `GroupedBarChartData`: multiple bars side by side per group.
public struct GroupedBarChartRenderer: ChartRenderer {
  public let data: GroupedBarChartData
  public init(data: GroupedBarChartData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(data: data, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let data: GroupedBarChartData
    let theme: DrafterThemeColors
    private static let innerSpacing: CGFloat = 4
    var labels: [String] { data.labels }
    var barsPerGroup: Int { max(data.itemNames.count, 1) }
    func maxValue() -> Float { data.groupedValues.flatMap { $0 }.max() ?? 0 }

    func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat) {
      guard dataSize > 0, barsPerGroup > 0 else { return (0, 0) }
      let totalGroupSpacing = chartWidth * 0.1
      let groupSpacing = totalGroupSpacing / CGFloat(dataSize + 1)
      let availableWidth = chartWidth - totalGroupSpacing
      let totalBarSpacingPerGroup = CGFloat(barsPerGroup - 1) * Self.innerSpacing
      let barWidth = (availableWidth / CGFloat(dataSize) - totalBarSpacingPerGroup) / CGFloat(barsPerGroup)
      return (max(barWidth, 0), max(groupSpacing, 0))
    }

    func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat {
      barWidth * CGFloat(barsPerGroup) + CGFloat(barsPerGroup - 1) * Self.innerSpacing
    }

    func drawGroup(
      in context: inout GraphicsContext, index: Int, left: CGFloat, barWidth: CGFloat,
      groupSpacing: CGFloat, chartBottom: CGFloat, chartHeight: CGFloat, maxValue: Float, progress: Double
    ) {
      guard index < data.groupedValues.count else { return }
      var currentLeft = left
      for (barIndex, value) in data.groupedValues[index].enumerated() {
        let barHeight = CGFloat(value / maxValue) * chartHeight * CGFloat(progress)
        let color = data.colors.indices.contains(barIndex) ? data.colors[barIndex] : theme.color(at: barIndex)
        let rect = CGRect(x: currentLeft, y: chartBottom - barHeight, width: barWidth, height: barHeight)
        drawBar(in: &context, rect: rect, color: color, cornerRadius: barWidth * 0.3)
        currentLeft += barWidth + Self.innerSpacing
      }
    }
  }
}

/// A grouped bar chart: side-by-side bars for each label.
public struct GroupedBarChart: View {
  public let data: GroupedBarChartData
  public var animate: Bool
  public var replay: Int

  public init(data: GroupedBarChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: GroupedBarChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Stacked

/// Data for a `StackedBarChart`: each bar is a vertical stack of segments.
public struct StackedBarChartData: Equatable, Sendable {
  public var labels: [String]
  public var stacks: [[Float]]
  public var colors: [Color]

  public init(labels: [String], stacks: [[Float]], colors: [Color] = DrafterColors.palette) {
    self.labels = labels
    self.stacks = stacks
    self.colors = colors
  }
}

/// Draws a `StackedBarChartData`: segments stacked vertically per bar.
public struct StackedBarChartRenderer: ChartRenderer {
  public let data: StackedBarChartData
  public init(data: StackedBarChartData) { self.data = data }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(data: data, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let data: StackedBarChartData
    let theme: DrafterThemeColors
    // Numeric labels are formatted to one decimal, matching the Compose renderer.
    var labels: [String] {
      data.labels.map { label in
        if let f = Float(label) { return ChartFormatting.format(f, decimals: 1) }
        return label
      }
    }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float { data.stacks.map { $0.reduce(0, +) }.max() ?? 0 }

    func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat) {
      guard dataSize > 0 else { return (0, 0) }
      // Stacked uses a wider 20% gap budget for extra breathing room.
      let totalGapSpace = chartWidth * 0.2
      let groupSpacing = totalGapSpace / CGFloat(dataSize + 1)
      let availableWidth = chartWidth - totalGapSpace
      let barWidth = availableWidth / CGFloat(dataSize)
      return (max(barWidth, 0), max(groupSpacing, 0))
    }

    func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat { barWidth }

    func drawGroup(
      in context: inout GraphicsContext, index: Int, left: CGFloat, barWidth: CGFloat,
      groupSpacing: CGFloat, chartBottom: CGFloat, chartHeight: CGFloat, maxValue: Float, progress: Double
    ) {
      guard index < data.stacks.count else { return }
      var currentBottom = chartBottom
      for (stackIndex, value) in data.stacks[index].enumerated() {
        let barHeight = CGFloat(value / max(maxValue, 1e-6)) * chartHeight * CGFloat(progress)
        let color = data.colors.indices.contains(stackIndex) ? data.colors[stackIndex] : theme.color(at: stackIndex)
        let rect = CGRect(x: left, y: currentBottom - barHeight, width: barWidth, height: barHeight)
        // Square segments so stacks read as a continuous bar.
        if barHeight > 0, barWidth > 0 {
          context.fill(Path(rect), with: .color(color))
        }
        currentBottom -= barHeight
      }
    }
  }
}

/// A stacked bar chart: each label's bar stacks its segment values vertically.
public struct StackedBarChart: View {
  public let data: StackedBarChartData
  public var animate: Bool
  public var replay: Int

  public init(data: StackedBarChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: StackedBarChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Histogram

/// Data for a `Histogram`: raw points binned into a frequency distribution.
public struct HistogramData: Equatable, Sendable {
  public var dataPoints: [Float]
  public var binCount: Int
  public var color: Color

  public init(dataPoints: [Float], binCount: Int, color: Color = DrafterColors.blue) {
    self.dataPoints = dataPoints
    self.binCount = binCount
    self.color = color
  }
}

/// Draws a `HistogramData`: bins `dataPoints` into `binCount` frequency bars.
public struct HistogramRenderer: ChartRenderer {
  public let data: HistogramData
  private let binLabels: [String]
  private let frequencies: [Float]

  public init(data: HistogramData) {
    self.data = data
    let (labels, freqs) = Self.bin(data.dataPoints, binCount: data.binCount)
    self.binLabels = labels
    self.frequencies = freqs
  }

  /// Bins raw points into `binCount` buckets, returning range labels and counts.
  private static func bin(_ points: [Float], binCount: Int) -> ([String], [Float]) {
    guard binCount > 0 else { return ([], []) }
    let minVal = points.min() ?? 0
    let maxVal = points.max() ?? minVal
    let binSize = maxVal > minVal ? (maxVal - minVal) / Float(binCount) : 1
    var freqs = [Float](repeating: 0, count: binCount)
    for point in points {
      let raw = Int((point - minVal) / binSize)
      let idx = min(max(raw, 0), binCount - 1)
      freqs[idx] += 1
    }
    let labels = (0..<binCount).map { i -> String in
      let start = minVal + Float(i) * binSize
      let end = start + binSize
      return "\(ChartFormatting.format(start, decimals: 1))-\(ChartFormatting.format(end, decimals: 1))"
    }
    return (labels, freqs)
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(
      Variant(labels: binLabels, frequencies: frequencies, color: data.color),
      in: &context, size: size, theme: theme, progress: progress
    )
  }

  private struct Variant: BarVariant {
    let labels: [String]
    let frequencies: [Float]
    let color: Color
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float {
      let m = frequencies.max() ?? 0
      return m > 0 ? m : 1
    }

    func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat) {
      guard dataSize > 0, chartWidth > 0 else { return (0, 0) }
      let totalSpacing = chartWidth * 0.1
      let groupSpacing = totalSpacing / CGFloat(dataSize + 1)
      let availableWidth = chartWidth - totalSpacing
      let barWidth = availableWidth / CGFloat(dataSize)
      return (max(barWidth, 0), max(groupSpacing, 0))
    }

    func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat { barWidth }

    func drawGroup(
      in context: inout GraphicsContext, index: Int, left: CGFloat, barWidth: CGFloat,
      groupSpacing: CGFloat, chartBottom: CGFloat, chartHeight: CGFloat, maxValue: Float, progress: Double
    ) {
      guard index < frequencies.count else { return }
      let freq = frequencies[index]
      let barHeight = CGFloat(freq / max(maxValue, 1)) * chartHeight * CGFloat(progress)
      let rect = CGRect(x: left, y: chartBottom - barHeight, width: barWidth, height: barHeight)
      drawBar(in: &context, rect: rect, color: color, cornerRadius: barWidth * 0.2)
    }
  }
}

/// A histogram: bins raw data points into a frequency-distribution bar chart.
public struct Histogram: View {
  public let data: HistogramData
  public var animate: Bool
  public var replay: Int

  public init(data: HistogramData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: HistogramRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Waterfall

/// Data for a `WaterfallChart`: incremental `values` from an `initialValue`.
public struct WaterfallChartData: Equatable, Sendable {
  public var labels: [String]
  public var values: [Float]
  public var colors: [Color]
  public var initialValue: Float

  public init(labels: [String], values: [Float], colors: [Color] = DrafterColors.palette, initialValue: Float = 0) {
    self.labels = labels
    self.values = values
    self.colors = colors
    self.initialValue = initialValue
  }
}

/// Draws a `WaterfallChartData`: each bar spans the running total's change,
/// with connector lines between steps.
public struct WaterfallChartRenderer: ChartRenderer {
  public let data: WaterfallChartData
  public init(data: WaterfallChartData) { self.data = data }

  /// Running totals: `[initial, initial+v0, initial+v0+v1, ...]`.
  private func cumulative() -> [Float] {
    var result: [Float] = [data.initialValue]
    var sum = data.initialValue
    for value in data.values {
      sum += value
      result.append(sum)
    }
    return result
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(
      Variant(data: data, cumulative: cumulative(), theme: theme),
      in: &context, size: size, theme: theme, progress: progress
    )
  }

  private struct Variant: BarVariant {
    let data: WaterfallChartData
    let cumulative: [Float]
    let theme: DrafterThemeColors
    var labels: [String] { data.labels }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float {
      let absValues = cumulative.map { abs($0) }
      return absValues.max() ?? 0
    }

    func barAndSpacing(chartWidth: CGFloat, dataSize: Int, barsPerGroup: Int) -> (CGFloat, CGFloat) {
      guard dataSize > 0 else { return (0, 0) }
      let totalSpacing = chartWidth * 0.1
      let groupSpacing = totalSpacing / CGFloat(dataSize + 1)
      let availableWidth = chartWidth - totalSpacing
      let barWidth = availableWidth / CGFloat(dataSize)
      return (max(barWidth, 0), max(groupSpacing, 0))
    }

    func groupWidth(barWidth: CGFloat, barsPerGroup: Int) -> CGFloat { barWidth }

    func drawGroup(
      in context: inout GraphicsContext, index: Int, left: CGFloat, barWidth: CGFloat,
      groupSpacing: CGFloat, chartBottom: CGFloat, chartHeight: CGFloat, maxValue: Float, progress: Double
    ) {
      guard index < data.values.count, index + 1 < cumulative.count else { return }
      let startValue = cumulative[index]
      let endValue = cumulative[index + 1]
      let yStart = chartBottom - CGFloat(startValue / maxValue) * chartHeight
      let yEnd = chartBottom - CGFloat(endValue / maxValue) * chartHeight
      let top = min(yStart, yEnd)
      let height = abs(yEnd - yStart) * CGFloat(progress)
      let color = data.colors.indices.contains(index) ? data.colors[index] : theme.color(at: index)
      let rect = CGRect(x: left, y: top, width: barWidth, height: height)
      drawBar(in: &context, rect: rect, color: color, cornerRadius: barWidth * 0.2)

      // Connector from the previous bar's end to this bar's start.
      if index > 0 {
        let previousY = chartBottom - CGFloat(cumulative[index] / maxValue) * chartHeight
        var line = Path()
        line.move(to: CGPoint(x: left - barWidth - groupSpacing, y: previousY))
        line.addLine(to: CGPoint(x: left, y: yStart))
        context.stroke(line, with: .color(theme.label), lineWidth: 2)
      }
    }
  }
}

/// A waterfall chart: bars span the running total's change from an initial value.
public struct WaterfallChart: View {
  public let data: WaterfallChartData
  public var animate: Bool
  public var replay: Int

  public init(data: WaterfallChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: WaterfallChartRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}
