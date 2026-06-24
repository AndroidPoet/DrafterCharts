//
//  SankeyChart.swift
//  DrafterCharts
//
//  A Sankey flow diagram: layered node bars connected by smooth, gradient-filled
//  cubic-bezier bands whose thickness encodes each flow's value. Bands reveal
//  left -> right and node bars grow in height on first composition.
//
//  Layout is pure value-type math: nodes are grouped by column, each node's
//  height is proportional to its throughput (max of total inflow vs outflow),
//  columns are center-stacked with vertical gaps, and links are allocated
//  stacked, non-overlapping offsets along each node edge.
//

import SwiftUI

/// A single node in a `SankeyChart`.
///
/// - `id`: stable identifier referenced by `SankeyLink.from` / `SankeyLink.to`.
/// - `label`: human-readable text drawn beside the node bar.
/// - `column`: the layer (0, 1, 2, ...) the node belongs to; columns spread
///   evenly across the chart width from left to right.
/// - `color`: the colour of the node bar and the tint of its outgoing bands.
public struct SankeyNode: Equatable, Sendable {
  public var id: String
  public var label: String
  public var column: Int
  public var color: Color

  public init(id: String, label: String, column: Int, color: Color) {
    self.id = id
    self.label = label
    self.column = column
    self.color = color
  }
}

/// A flow between two nodes. Its `value` determines the band thickness at both
/// endpoints.
public struct SankeyLink: Equatable, Sendable {
  public var from: String
  public var to: String
  public var value: Float

  public init(from: String, to: String, value: Float) {
    self.from = from
    self.to = to
    self.value = value
  }
}

/// The full dataset for a Sankey diagram: a set of `nodes` and the `links`
/// between them.
public struct SankeyData: Equatable, Sendable {
  public var nodes: [SankeyNode]
  public var links: [SankeyLink]

  public init(nodes: [SankeyNode], links: [SankeyLink]) {
    self.nodes = nodes
    self.links = links
  }
}

/// Draws a `SankeyData` flow diagram into a canvas.
public struct SankeyChartRenderer: ChartRenderer {
  public let data: SankeyData
  public init(data: SankeyData) { self.data = data }

  /// A node positioned in pixel space, ready to draw.
  private struct PlacedNode {
    let node: SankeyNode
    let x: CGFloat
    let top: CGFloat
    let width: CGFloat
    let fullHeight: CGFloat
    let isFirst: Bool
    let isLast: Bool
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let nodes = data.nodes
    guard !nodes.isEmpty else { return }

    let prog = CGFloat(min(max(progress, 0), 1))

    // 8% inset on each side for node labels (mirrors the Compose host).
    let inset: CGFloat = 0.08
    let chartLeft = size.width * inset
    let chartTop = size.height * inset
    let chartWidth = size.width * (1 - inset * 2)
    let chartHeight = size.height * (1 - inset * 2)
    guard chartWidth > 0, chartHeight > 0 else { return }

    // Index nodes by id; skip links that reference unknown nodes.
    var nodeById: [String: SankeyNode] = [:]
    for node in nodes { nodeById[node.id] = node }

    // Per-node throughput = max(total inflow, total outflow).
    var inflow: [String: Float] = [:]
    var outflow: [String: Float] = [:]
    for link in data.links where nodeById[link.from] != nil && nodeById[link.to] != nil {
      outflow[link.from, default: 0] += link.value
      inflow[link.to, default: 0] += link.value
    }
    func throughput(_ id: String) -> CGFloat {
      CGFloat(max(max(inflow[id] ?? 0, outflow[id] ?? 0), 0))
    }

    // Group by column and order columns left -> right.
    var columns: [Int: [SankeyNode]] = [:]
    for node in nodes { columns[node.column, default: []].append(node) }
    let columnKeys = columns.keys.sorted()
    guard let maxColumn = columnKeys.last else { return }

    let nodeWidth = min(max(chartWidth * 0.045, 6), 26)
    let verticalGap = max(chartHeight * 0.04, 6)

    // Scale node heights so the tallest column's stack fits the chart height.
    let maxThroughputSum = max(
      columnKeys.map { key in
        (columns[key] ?? []).reduce(CGFloat(0)) { $0 + throughput($1.id) }
      }.max() ?? 0,
      1
    )
    let maxColumnCount = columnKeys.map { (columns[$0] ?? []).count }.max() ?? 0
    let availableForBars = max(
      chartHeight - CGFloat(max(maxColumnCount - 1, 0)) * verticalGap,
      1
    )
    let valueToPx = availableForBars / maxThroughputSum

    // Place every node.
    var placed: [String: PlacedNode] = [:]
    for (colIndex, colKey) in columnKeys.enumerated() {
      let group = (columns[colKey] ?? []).sorted { $0.label < $1.label }
      let heights = group.map { max(throughput($0.id) * valueToPx, 2) }
      let stackHeight = heights.reduce(0, +) + CGFloat(max(group.count - 1, 0)) * verticalGap
      let startY = chartTop + (chartHeight - stackHeight) / 2

      let x: CGFloat =
        maxColumn == 0
          ? chartLeft + (chartWidth - nodeWidth) / 2
          : chartLeft + (chartWidth - nodeWidth) * (CGFloat(colKey) / CGFloat(maxColumn))

      var cursorY = startY
      for (i, node) in group.enumerated() {
        let h = heights[i]
        placed[node.id] = PlacedNode(
          node: node,
          x: x,
          top: cursorY,
          width: nodeWidth,
          fullHeight: h,
          isFirst: colIndex == 0,
          isLast: colIndex == columnKeys.count - 1
        )
        cursorY += h + verticalGap
      }
    }

    // Running offsets so multiple links share each edge without overlapping.
    var outOffset: [String: CGFloat] = [:]
    var inOffset: [String: CGFloat] = [:]
    let revealRight = chartLeft + chartWidth * prog

    // Draw the bands first (behind node bars).
    for link in data.links {
      guard let from = placed[link.from], let to = placed[link.to] else { continue }

      let fromTotal = max(throughput(from.node.id), 0.0001)
      let toTotal = max(throughput(to.node.id), 0.0001)
      let fromThickness = from.fullHeight * (CGFloat(link.value) / fromTotal)
      let toThickness = to.fullHeight * (CGFloat(link.value) / toTotal)

      let oStart = outOffset[link.from] ?? 0
      let iStart = inOffset[link.to] ?? 0
      outOffset[link.from] = oStart + fromThickness
      inOffset[link.to] = iStart + toThickness

      let startX = from.x + from.width
      let endX = to.x
      let startTop = from.top + oStart
      let startBottom = startTop + fromThickness
      let endTop = to.top + iStart
      let endBottom = endTop + toThickness

      drawBand(
        in: &context,
        startX: startX,
        endX: endX,
        startTop: startTop,
        startBottom: startBottom,
        endTop: endTop,
        endBottom: endBottom,
        fromColor: from.node.color,
        toColor: to.node.color,
        revealRight: revealRight,
        canvasHeight: size.height
      )
    }

    // Draw node bars (animated growth in height) + labels.
    for pn in placed.values {
      let animHeight = pn.fullHeight * prog
      let centerY = pn.top + pn.fullHeight / 2
      let barTop = centerY - animHeight / 2
      let corner = pn.width / 2.5
      let barRect = CGRect(x: pn.x, y: barTop, width: pn.width, height: animHeight)
      let barPath = Path(roundedRect: barRect, cornerRadius: corner)

      context.fill(barPath, with: .color(pn.node.color))
      // Soft white inner stroke for a crisp, premium edge.
      context.stroke(barPath, with: .color(Color.white.opacity(0.25)), lineWidth: 1.25)

      drawNodeLabel(
        in: &context,
        node: pn.node,
        labelColor: theme.label,
        canvasWidth: size.width,
        x: pn.x,
        width: pn.width,
        barTop: barTop,
        chartTop: chartTop,
        progress: prog
      )
    }
  }

  /// Draws one flow band as a filled cubic S-curve with a horizontal from->to
  /// gradient, revealed by clipping to the left of `revealRight`.
  private func drawBand(
    in context: inout GraphicsContext,
    startX: CGFloat,
    endX: CGFloat,
    startTop: CGFloat,
    startBottom: CGFloat,
    endTop: CGFloat,
    endBottom: CGFloat,
    fromColor: Color,
    toColor: Color,
    revealRight: CGFloat,
    canvasHeight: CGFloat
  ) {
    let midX = (startX + endX) / 2
    var path = Path()
    path.move(to: CGPoint(x: startX, y: startTop))
    path.addCurve(
      to: CGPoint(x: endX, y: endTop),
      control1: CGPoint(x: midX, y: startTop),
      control2: CGPoint(x: midX, y: endTop)
    )
    path.addLine(to: CGPoint(x: endX, y: endBottom))
    path.addCurve(
      to: CGPoint(x: startX, y: startBottom),
      control1: CGPoint(x: midX, y: endBottom),
      control2: CGPoint(x: midX, y: startBottom)
    )
    path.closeSubpath()

    let gradient = Gradient(colors: [fromColor.opacity(0.5), toColor.opacity(0.5)])

    var clip = context
    clip.clip(to: Path(CGRect(x: 0, y: 0, width: revealRight, height: canvasHeight)))
    clip.fill(
      path,
      with: .linearGradient(
        gradient,
        startPoint: CGPoint(x: startX, y: 0),
        endPoint: CGPoint(x: endX, y: 0)
      )
    )
  }

  /// Draws a node's label centered above its bar, clamped to the canvas so it
  /// stays fully on-screen at small sizes. Fades in with the reveal progress.
  private func drawNodeLabel(
    in context: inout GraphicsContext,
    node: SankeyNode,
    labelColor: Color,
    canvasWidth: CGFloat,
    x: CGFloat,
    width: CGFloat,
    barTop: CGFloat,
    chartTop: CGFloat,
    progress: CGFloat
  ) {
    guard !node.label.isEmpty else { return }
    let text = Text(node.label)
      .font(.system(size: 10))
      .foregroundColor(labelColor.opacity(Double(progress)))

    // At small sizes the 8% side inset is too narrow to hold edge-column labels,
    // so anchoring them outside the bar (.trailing left of the first node /
    // .leading right of the last node) pushes the text past the canvas and clips
    // it. Draw every label centered above its bar instead, and clamp the center
    // by the resolved text's half-width so the WHOLE label stays on-canvas (not
    // just its center), then keep it below the chart top so a near-full-height
    // bar never clips the label off the top edge.
    let resolved = context.resolve(text)
    let half = resolved.measure(in: CGSize(width: canvasWidth, height: .infinity)).width / 2
    let lower = min(half + 2, canvasWidth / 2)
    let upper = max(canvasWidth - half - 2, canvasWidth / 2)
    let cx = min(max(x + width / 2, lower), upper)
    let ly = max(barTop - 4, chartTop + 4)
    context.draw(text, at: CGPoint(x: cx, y: ly), anchor: .bottom)
  }
}

/// A Sankey flow diagram with gradient flow bands and an animated left-to-right
/// reveal.
public struct SankeyChart: View {
  public let data: SankeyData
  public var animate: Bool
  public var replay: Int

  public init(data: SankeyData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: SankeyChartRenderer(data: data), animate: animate, duration: 0.9, replay: replay)
  }
}
