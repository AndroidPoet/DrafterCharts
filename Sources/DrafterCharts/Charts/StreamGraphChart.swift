//
//  StreamGraphChart.swift
//  DrafterCharts
//
//  A stream graph (themeriver): several series stacked as smooth flowing bands
//  centred around the chart midline so the whole thing reads like a river. The
//  stack grows symmetrically outward from its centre as it reveals. Mirrors the
//  Compose `stream/` renderer: shared `ChartSeries` data, a pure `ChartRenderer`,
//  and a thin view that hosts it in `ChartCanvas`.
//

import SwiftUI

/// Renders `[ChartSeries]` as a themeriver: each series flows as a smooth band,
/// the stack centred symmetrically around the chart midline. Each band uses its
/// series' own `color`, so a colour can never desync from its data. `categories`
/// supplies the optional x-axis labels.
public struct StreamGraphChartRenderer: ChartRenderer {
  public let series: [ChartSeries]
  public let categories: [String]

  public init(series: [ChartSeries], categories: [String] = []) {
    self.series = series
    self.categories = categories
  }

  /// Number of x points shared by every series. Driven by the series' own value
  /// arrays — the common minimum length across all series so the stack only
  /// samples indices that every series actually has — never by `categories.count`.
  /// Ragged or over-long category arrays can't introduce phantom samples this way.
  private var pointCount: Int {
    series.map { $0.values.count }.min() ?? 0
  }

  /// The largest total stacked value across all x points (drives the y scale).
  private func maxTotal(_ count: Int) -> Float {
    var maxV: Float = 0
    for i in 0..<count {
      var total: Float = 0
      for s in series { total += s.value(at: i) }
      if total > maxV { maxV = total }
    }
    return maxV
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let count = pointCount
    guard count >= 2, !series.isEmpty else { return }

    let p = CGFloat(min(max(progress, 0), 1))

    // 8% horizontal inset; small vertical inset to keep labels readable.
    let chartLeft = size.width * 0.08
    let chartWidth = size.width * 0.84
    let chartTop = size.height * 0.06
    let chartHeight = size.height * 0.84

    let centerY = chartTop + chartHeight / 2
    let maxTotal = maxTotal(count)
    guard maxTotal > 0 else { return }

    // Fit the tallest total stack into ~80% of the available height.
    let yScale = CGFloat(chartHeight * 0.8) / CGFloat(maxTotal)
    let stepX = count > 1 ? chartWidth / CGFloat(count - 1) : chartWidth
    let xs: [CGFloat] = (0..<count).map { chartLeft + CGFloat($0) * stepX }

    // Per-series thickness (in pixels, pre-progress) at each x.
    let thickness: [[CGFloat]] = series.map { s in
      (0..<count).map { CGFloat(s.value(at: $0)) * yScale }
    }

    // Centred baseline (top edge of the whole stack) at each x. Scale the
    // half-height by progress so the stack grows outward from the centre
    // baseline rather than dropping in from a fixed top edge. Mirrors the
    // Compose renderer exactly (a symmetric, centred stack — not a wiggle).
    var stackTop = [CGFloat](repeating: 0, count: count)
    for i in 0..<count {
      var total: CGFloat = 0
      for layer in thickness { total += layer[i] }
      let halfHeight = (total * p) / 2
      stackTop[i] = centerY - halfHeight
    }

    // Running cumulative top per x; each series stacks below the previous one.
    var runningTop = stackTop
    for (idx, s) in series.enumerated() {
      let layer = thickness[idx]
      var topEdge = [CGPoint]()
      var bottomEdge = [CGPoint]()
      topEdge.reserveCapacity(count)
      bottomEdge.reserveCapacity(count)

      for i in 0..<count {
        let h = layer[i] * p
        let top = runningTop[i]
        let bottom = top + h
        topEdge.append(CGPoint(x: xs[i], y: top))
        bottomEdge.append(CGPoint(x: xs[i], y: bottom))
        runningTop[i] = bottom
      }

      drawBand(in: &context, topEdge: topEdge, bottomEdge: bottomEdge, color: s.color)
    }

    drawXLabels(in: &context, theme: theme, xs: xs, baseline: chartTop + chartHeight)
  }

  // MARK: - Bands

  /// Builds a closed band from a smooth top edge and a smooth bottom edge, fills
  /// it with a soft vertical gradient, then strokes a thin lighter top edge for
  /// separation between stacked bands.
  private func drawBand(in context: inout GraphicsContext, topEdge: [CGPoint], bottomEdge: [CGPoint], color: Color) {
    guard topEdge.count >= 2 else { return }

    let topPath = smoothPath(topEdge)

    // Closed band: smooth top edge L->R, then smooth bottom edge R->L, close.
    var band = smoothPath(topEdge)
    appendSmoothInto(&band, Array(bottomEdge.reversed()))
    band.closeSubpath()

    let minY = topEdge.map { $0.y }.min() ?? 0
    let maxY = bottomEdge.map { $0.y }.max() ?? 0

    // Opaque-ish base so the band reads solid over busy backgrounds, then a
    // soft top->bottom gradient on top (mirrors the Compose renderer).
    context.fill(band, with: .color(color.opacity(0.85)))
    context.fill(
      band,
      with: .linearGradient(
        Gradient(colors: [color.opacity(0.92), color.opacity(0.78)]),
        startPoint: CGPoint(x: 0, y: minY),
        endPoint: CGPoint(x: 0, y: maxY)
      )
    )

    // Thin lighter stroke along the top edge for separation between bands.
    context.stroke(
      topPath,
      with: .color(.white.opacity(0.22)),
      style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
    )
  }

  /// Appends a Catmull-Rom smooth curve through `points` into `path`, continuing
  /// the existing subpath (lines to the first point, then cubic segments through
  /// the rest). Mirrors `smoothPath` but without starting a new subpath.
  private func appendSmoothInto(_ path: inout Path, _ points: [CGPoint]) {
    guard let first = points.first else { return }
    path.addLine(to: first)
    if points.count < 3 {
      for i in 1..<points.count { path.addLine(to: points[i]) }
      return
    }
    for i in 0..<(points.count - 1) {
      let p0 = points[i - 1 < 0 ? i : i - 1]
      let p1 = points[i]
      let p2 = points[i + 1]
      let p3 = points[i + 2 > points.count - 1 ? i + 1 : i + 2]
      let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
      let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
      path.addCurve(to: p2, control1: c1, control2: c2)
    }
  }

  // MARK: - Labels

  /// Draws a sparse set of x labels (at most 6) along the bottom of the chart.
  /// Reads from `categories`, only drawing a label when the index exists in both
  /// the category array and the mapped x positions.
  private func drawXLabels(in context: inout GraphicsContext, theme: DrafterThemeColors, xs: [CGFloat], baseline: CGFloat) {
    guard !categories.isEmpty else { return }
    let maxLabels = 6
    let labelCount = categories.count
    let stride = max(1, (labelCount + maxLabels - 1) / maxLabels)

    var i = 0
    while i < labelCount {
      if i >= xs.count { break }
      let text = Text(categories[i]).font(.system(size: 10)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: xs[i], y: baseline + 6 + 6), anchor: .center)
      i += stride
    }
  }
}

private extension ChartSeries {
  /// The value at `index`, or 0 when this series is shorter than the stack.
  func value(at index: Int) -> Float {
    index >= 0 && index < values.count ? values[index] : 0
  }
}

/// A stream graph (themeriver): stacked series that flow as smooth bands centred
/// around the chart midline, growing symmetrically outward from the centre as
/// they animate in. Each band's colour is bound to its `ChartSeries`; `categories`
/// supplies the optional x-axis labels.
public struct StreamGraphChart: View {
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
      renderer: StreamGraphChartRenderer(series: series, categories: categories),
      animate: animate,
      duration: 0.9,
      replay: replay
    )
  }
}
