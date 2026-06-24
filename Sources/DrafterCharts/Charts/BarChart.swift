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

/// Pads or truncates `labels` to exactly `count` entries, so a mismatched label
/// array can never drive a different number of columns than the data. Missing
/// labels become empty strings; extra labels are dropped.
func normalizedLabels(_ labels: [String], count: Int) -> [String] {
  guard count > 0 else { return [] }
  if labels.count == count { return labels }
  return (0..<count).map { $0 < labels.count ? labels[$0] : "" }
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

/// Draws `[BarItem]` as single rounded, gradient-filled bars. Each bar binds its
/// own label, value, and optional color (palette fallback by position).
public struct SimpleBarChartRenderer: ChartRenderer {
  public let bars: [BarItem]
  public init(bars: [BarItem]) { self.bars = bars }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(bars: bars, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let bars: [BarItem]
    let theme: DrafterThemeColors
    var labels: [String] { bars.map { $0.label } }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float { bars.map { $0.value }.max() ?? 0 }

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
      guard index < bars.count else { return }
      let bar = bars[index]
      let barHeight = CGFloat(bar.value / maxValue) * chartHeight * CGFloat(progress)
      guard barHeight > 0 else { return }
      let color = bar.color ?? theme.color(at: index)
      // Slim the bar for breathing room and round the top corners.
      let inset = barWidth * 0.16
      let drawWidth = barWidth - inset * 2
      let rect = CGRect(x: left + inset, y: chartBottom - barHeight, width: drawWidth, height: barHeight)
      drawBar(in: &context, rect: rect, color: color, cornerRadius: drawWidth * 0.4)
    }
  }
}

/// A simple bar chart: one rounded, gradient-filled bar per `BarItem`.
public struct SimpleBarChart: View {
  public let bars: [BarItem]
  public var animate: Bool
  public var replay: Int

  public init(bars: [BarItem], animate: Bool = true, replay: Int = 0) {
    self.bars = bars
    self.animate = animate
    self.replay = replay
  }

  /// Convenience for unlabeled data: one value per bar, palette-colored.
  public init(values: [Float], animate: Bool = true, replay: Int = 0) {
    self.init(bars: values.map { BarItem($0) }, animate: animate, replay: replay)
  }

  public var body: some View {
    ChartCanvas(renderer: SimpleBarChartRenderer(bars: bars), animate: animate, duration: 1.0, replay: replay)
  }
}

// MARK: - Grouped

/// Draws side-by-side bars per category from `[ChartSeries]`. Each series is one
/// colored item; `series[s].values[i]` is that item's bar in category `i`.
/// `categories` supplies the x-axis labels.
public struct GroupedBarChartRenderer: ChartRenderer {
  public let series: [ChartSeries]
  public let categories: [String]
  public init(series: [ChartSeries], categories: [String] = []) {
    self.series = series
    self.categories = categories
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(series: series, categories: categories, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let series: [ChartSeries]
    let categories: [String]
    let theme: DrafterThemeColors
    private static let innerSpacing: CGFloat = 4
    private var groupCount: Int { series.map { $0.values.count }.max() ?? 0 }
    var labels: [String] { normalizedLabels(categories, count: groupCount) }
    var barsPerGroup: Int { max(series.count, 1) }
    func maxValue() -> Float { series.flatMap { $0.values }.max() ?? 0 }

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
      var currentLeft = left
      for item in series {
        let value = item.values.indices.contains(index) ? item.values[index] : 0
        let barHeight = CGFloat(value / maxValue) * chartHeight * CGFloat(progress)
        let rect = CGRect(x: currentLeft, y: chartBottom - barHeight, width: barWidth, height: barHeight)
        drawBar(in: &context, rect: rect, color: item.color, cornerRadius: barWidth * 0.3)
        currentLeft += barWidth + Self.innerSpacing
      }
    }
  }
}

/// A grouped bar chart: side-by-side bars for each category.
public struct GroupedBarChart: View {
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
      renderer: GroupedBarChartRenderer(series: series, categories: categories),
      animate: animate, duration: 1.0, replay: replay
    )
  }
}

// MARK: - Stacked

/// Draws a vertical stack of segments per category from `[ChartSeries]`. Each
/// series is one colored segment-level; `series[s].values[i]` is that level's
/// height in category `i`. `categories` supplies the x-axis labels.
public struct StackedBarChartRenderer: ChartRenderer {
  public let series: [ChartSeries]
  public let categories: [String]
  public init(series: [ChartSeries], categories: [String] = []) {
    self.series = series
    self.categories = categories
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    drawBarChart(Variant(series: series, categories: categories, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let series: [ChartSeries]
    let categories: [String]
    let theme: DrafterThemeColors
    private var groupCount: Int { series.map { $0.values.count }.max() ?? 0 }
    var labels: [String] { normalizedLabels(categories, count: groupCount) }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float {
      (0..<groupCount).map { i in
        series.reduce(Float(0)) { $0 + ($1.values.indices.contains(i) ? $1.values[i] : 0) }
      }.max() ?? 0
    }

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
      var currentBottom = chartBottom
      for level in series {
        let value = level.values.indices.contains(index) ? level.values[index] : 0
        let barHeight = CGFloat(value / max(maxValue, 1e-6)) * chartHeight * CGFloat(progress)
        let rect = CGRect(x: left, y: currentBottom - barHeight, width: barWidth, height: barHeight)
        // Square segments so stacks read as a continuous bar.
        if barHeight > 0, barWidth > 0 {
          context.fill(Path(rect), with: .color(level.color))
        }
        currentBottom -= barHeight
      }
    }
  }
}

/// A stacked bar chart: each category's bar stacks its series segments vertically.
public struct StackedBarChart: View {
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
      renderer: StackedBarChartRenderer(series: series, categories: categories),
      animate: animate, duration: 1.0, replay: replay
    )
  }
}

// MARK: - Histogram

/// Draws a frequency distribution: bins raw `values` into `binCount` bars. A
/// single array of points — there are no parallel arrays to mismatch.
public struct HistogramRenderer: ChartRenderer {
  public let values: [Float]
  public let binCount: Int
  public let color: Color
  private let binLabels: [String]
  private let frequencies: [Float]

  public init(values: [Float], binCount: Int, color: Color = DrafterColors.blue) {
    self.values = values
    self.binCount = binCount
    self.color = color
    let (labels, freqs) = Self.bin(values, binCount: binCount)
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
      Variant(labels: binLabels, frequencies: frequencies, color: color),
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

/// A histogram: bins raw `values` into a frequency-distribution bar chart.
public struct Histogram: View {
  public let values: [Float]
  public let binCount: Int
  public let color: Color
  public var animate: Bool
  public var replay: Int

  public init(values: [Float], binCount: Int, color: Color = DrafterColors.blue, animate: Bool = true, replay: Int = 0) {
    self.values = values
    self.binCount = binCount
    self.color = color
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: HistogramRenderer(values: values, binCount: binCount, color: color),
      animate: animate, duration: 1.0, replay: replay
    )
  }
}

// MARK: - Waterfall

/// Draws a waterfall from `[WaterfallStep]`: each step is a labeled incremental
/// change applied to `initialValue`. Set `startLabel` to draw a leading bar at
/// the initial value, and `totalLabel` to draw a trailing bar at the final
/// running total — the classic Start … Total waterfall. Connectors are drawn
/// horizontally at each running total.
public struct WaterfallChartRenderer: ChartRenderer {
  public let steps: [WaterfallStep]
  public let initialValue: Float
  public let startLabel: String?
  public let totalLabel: String?

  public init(steps: [WaterfallStep], initialValue: Float = 0, startLabel: String? = nil, totalLabel: String? = nil) {
    self.steps = steps
    self.initialValue = initialValue
    self.startLabel = startLabel
    self.totalLabel = totalLabel
  }

  /// One rendered column: a bar spanning `[start, end]` with a label and color.
  private struct Column: Equatable {
    let start: Float
    let end: Float
    let label: String
    let color: Color?
  }

  /// Builds the ordered columns: optional Start bar, one bar per step, optional
  /// Total bar. This count — not any label array — drives the chart.
  private func buildColumns() -> [Column] {
    var result: [Column] = []
    if let startLabel {
      result.append(Column(start: 0, end: initialValue, label: startLabel, color: nil))
    }
    var running = initialValue
    for step in steps {
      let start = running
      running += step.value
      result.append(Column(start: start, end: running, label: step.label, color: step.color))
    }
    if let totalLabel {
      result.append(Column(start: 0, end: running, label: totalLabel, color: nil))
    }
    return result
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let columns = buildColumns()
    guard !columns.isEmpty else { return }
    drawBarChart(Variant(columns: columns, theme: theme), in: &context, size: size, theme: theme, progress: progress)
  }

  private struct Variant: BarVariant {
    let columns: [Column]
    let theme: DrafterThemeColors
    var labels: [String] { columns.map { $0.label } }
    var barsPerGroup: Int { 1 }
    func maxValue() -> Float {
      columns.flatMap { [abs($0.start), abs($0.end)] }.max() ?? 0
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
      guard index < columns.count, maxValue > 0 else { return }
      let column = columns[index]
      let yStart = chartBottom - CGFloat(column.start / maxValue) * chartHeight
      let yEnd = chartBottom - CGFloat(column.end / maxValue) * chartHeight
      let top = min(yStart, yEnd)
      let height = abs(yEnd - yStart) * CGFloat(progress)
      let color = column.color ?? theme.color(at: index)
      let rect = CGRect(x: left, y: top, width: barWidth, height: height)
      drawBar(in: &context, rect: rect, color: color, cornerRadius: barWidth * 0.2)

      // Horizontal connector at the previous column's running total.
      if index > 0 {
        let prevY = chartBottom - CGFloat(columns[index - 1].end / maxValue) * chartHeight
        var line = Path()
        line.move(to: CGPoint(x: left - groupSpacing, y: prevY))
        line.addLine(to: CGPoint(x: left, y: prevY))
        context.stroke(line, with: .color(theme.label.opacity(0.55)), lineWidth: 1.5)
      }
    }
  }
}

/// A waterfall chart: bars span the running total's change from an initial value.
public struct WaterfallChart: View {
  public let steps: [WaterfallStep]
  public let initialValue: Float
  public let startLabel: String?
  public let totalLabel: String?
  public var animate: Bool
  public var replay: Int

  public init(
    steps: [WaterfallStep],
    initialValue: Float = 0,
    startLabel: String? = nil,
    totalLabel: String? = nil,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.steps = steps
    self.initialValue = initialValue
    self.startLabel = startLabel
    self.totalLabel = totalLabel
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(
      renderer: WaterfallChartRenderer(steps: steps, initialValue: initialValue, startLabel: startLabel, totalLabel: totalLabel),
      animate: animate, duration: 1.0, replay: replay
    )
  }
}
