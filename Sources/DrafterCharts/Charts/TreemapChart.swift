//
//  TreemapChart.swift
//  DrafterCharts
//
//  A squarified treemap: area-proportional tiles laid out to keep each tile's
//  aspect ratio close to 1. Items are sorted by value descending, greedily
//  grouped into rows that minimize the worst aspect ratio, and the remainder is
//  recursed into the leftover rectangle. Tiles are drawn as rounded-corner rects
//  with a slight vertical gradient, a glassy inner highlight, and a centered
//  label/value, scaling up from their center as the reveal progresses.
//
//  Ported from the Compose `TreemapChartRenderer`. Follows the chart pattern: an
//  immutable data struct, a pure `ChartRenderer`, and a thin hosting view.
//

import SwiftUI

/// One tile of a treemap: a label, its (positive) magnitude, and a fill color.
public struct TreemapItem: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color

  public init(label: String, value: Float, color: Color) {
    self.label = label
    self.value = value
    self.color = color
  }
}

/// Data for a `TreemapChart`: the tiles to lay out. Tiles are area-proportional
/// to `value`; non-positive values are dropped before layout.
public struct TreemapData: Equatable, Sendable {
  public var items: [TreemapItem]

  public init(items: [TreemapItem]) {
    self.items = items
  }
}

// MARK: - Layout

/// A laid-out tile: the source item plus the pixel rectangle it occupies.
private struct TreemapTile {
  let item: TreemapItem
  let rect: CGRect
}

/// Draws a `TreemapData` into a canvas using the squarify layout algorithm.
public struct TreemapChartRenderer: ChartRenderer {
  public let data: TreemapData
  public init(data: TreemapData) { self.data = data }

  private static let gap: CGFloat = 4
  private static let corner: CGFloat = 8

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard size.width > 0, size.height > 0 else { return }

    let sorted = data.items
      .filter { $0.value > 0 }
      .sorted { $0.value > $1.value }
    guard !sorted.isEmpty else { return }

    // Small inset so tiles don't bleed to the very edge.
    let inset = min(size.width, size.height) * 0.04
    let bounds = CGRect(
      x: inset,
      y: inset,
      width: size.width - inset * 2,
      height: size.height - inset * 2
    )
    guard bounds.width > 0, bounds.height > 0 else { return }

    var tiles: [TreemapTile] = []
    tiles.reserveCapacity(sorted.count)
    Self.squarify(sorted, in: bounds, out: &tiles)

    for (index, tile) in tiles.enumerated() {
      drawTile(
        tile,
        index: index,
        count: tiles.count,
        in: &context,
        theme: theme,
        progress: progress
      )
    }
  }

  /// Slice-and-dice / squarify layout. Recursively peels a "row" of the largest
  /// items off the shorter side of the remaining rectangle so each tile's aspect
  /// ratio stays close to 1, then recurses into the leftover rectangle.
  private static func squarify(_ items: [TreemapItem], in rect: CGRect, out: inout [TreemapTile]) {
    if items.isEmpty || rect.width <= 0 || rect.height <= 0 { return }
    if items.count == 1 {
      out.append(TreemapTile(item: items[0], rect: rect))
      return
    }

    let total = Float(items.reduce(0.0) { $0 + Double($1.value) })
    if total <= 0 { return }

    // Lay tiles along the shorter side so rows stay close to square.
    let horizontal = rect.width >= rect.height
    let sideLength = horizontal ? rect.height : rect.width

    // Greedily grow a row, stopping when adding the next item worsens the ratio.
    var rowEnd = 1
    var rowSum = items[0].value
    var bestRatio = worstAspectRatio(Array(items[0..<1]), sideLength: sideLength, rowSum: rowSum, rect: rect, total: total)
    while rowEnd < items.count {
      let candidate = Array(items[0..<(rowEnd + 1)])
      let candidateSum = rowSum + items[rowEnd].value
      let candidateRatio = worstAspectRatio(candidate, sideLength: sideLength, rowSum: candidateSum, rect: rect, total: total)
      if candidateRatio > bestRatio { break }
      bestRatio = candidateRatio
      rowSum = candidateSum
      rowEnd += 1
    }

    let row = Array(items[0..<rowEnd])
    let rest = Array(items[rowEnd..<items.count])

    // Fraction of the whole rect's area consumed by this row.
    let rowAreaFraction = CGFloat(rowSum / total)

    if horizontal {
      let rowWidth = rect.width * rowAreaFraction
      let rowRect = CGRect(x: rect.minX, y: rect.minY, width: rowWidth, height: rect.height)
      out.append(contentsOf: placeRow(row, in: rowRect, horizontal: false))
      let restRect = CGRect(x: rect.minX + rowWidth, y: rect.minY, width: rect.width - rowWidth, height: rect.height)
      squarify(rest, in: restRect, out: &out)
    } else {
      let rowHeight = rect.height * rowAreaFraction
      let rowRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rowHeight)
      out.append(contentsOf: placeRow(row, in: rowRect, horizontal: true))
      let restRect = CGRect(x: rect.minX, y: rect.minY + rowHeight, width: rect.width, height: rect.height - rowHeight)
      squarify(rest, in: restRect, out: &out)
    }
  }

  /// Lay `row` items out evenly across `rowRect`, stacking along its length.
  private static func placeRow(_ row: [TreemapItem], in rowRect: CGRect, horizontal: Bool) -> [TreemapTile] {
    let rowTotal = Float(row.reduce(0.0) { $0 + Double($1.value) })
    if rowTotal <= 0 { return [] }
    var tiles: [TreemapTile] = []
    tiles.reserveCapacity(row.count)
    var cursor = horizontal ? rowRect.minX : rowRect.minY
    for item in row {
      let frac = CGFloat(item.value / rowTotal)
      if horizontal {
        let w = rowRect.width * frac
        tiles.append(TreemapTile(item: item, rect: CGRect(x: cursor, y: rowRect.minY, width: w, height: rowRect.height)))
        cursor += w
      } else {
        let h = rowRect.height * frac
        tiles.append(TreemapTile(item: item, rect: CGRect(x: rowRect.minX, y: cursor, width: rowRect.width, height: h)))
        cursor += h
      }
    }
    return tiles
  }

  /// Worst (max) aspect ratio among the row if it were placed, for the heuristic.
  private static func worstAspectRatio(_ row: [TreemapItem], sideLength: CGFloat, rowSum: Float, rect: CGRect, total: Float) -> CGFloat {
    if rowSum <= 0 || sideLength <= 0 { return .greatestFiniteMagnitude }
    let rectArea = rect.width * rect.height
    let rowArea = rectArea * CGFloat(rowSum / total)
    let rowThickness = rowArea / sideLength
    if rowThickness <= 0 { return .greatestFiniteMagnitude }
    var worst: CGFloat = 0
    for item in row {
      let itemArea = rectArea * CGFloat(item.value / total)
      let itemLength = itemArea / rowThickness
      if itemLength > 0 {
        let ratio = max(rowThickness / itemLength, itemLength / rowThickness)
        if ratio > worst { worst = ratio }
      }
    }
    return worst
  }

  // MARK: - Drawing

  private func drawTile(
    _ tile: TreemapTile,
    index: Int,
    count: Int,
    in context: inout GraphicsContext,
    theme: DrafterThemeColors,
    progress: Double
  ) {
    let rect = tile.rect
    let gap = Self.gap
    let innerLeft = rect.minX + gap
    let innerTop = rect.minY + gap
    let innerWidth = rect.width - gap * 2
    let innerHeight = rect.height - gap * 2
    if innerWidth <= 1 || innerHeight <= 1 { return }

    // Staggered fade + scale-from-center reveal.
    let stagger = count > 1 ? (Double(index) / Double(count)) * 0.4 : 0
    let local = max(0, min(1, (progress - stagger) / (1 - stagger)))
    if local <= 0 { return }
    let scale = CGFloat(0.6 + 0.4 * local)
    let alpha = local

    let drawW = innerWidth * scale
    let drawH = innerHeight * scale
    let centerX = innerLeft + innerWidth / 2
    let centerY = innerTop + innerHeight / 2
    let tileRect = CGRect(
      x: centerX - drawW / 2,
      y: centerY - drawH / 2,
      width: drawW,
      height: drawH
    )
    let path = Path(roundedRect: tileRect, cornerRadius: Self.corner)

    // Slight vertical gradient: full color at top, slightly dimmed at the bottom.
    let base = tile.item.color
    let gradient = Gradient(colors: [
      base.opacity(alpha),
      base.opacity(alpha * 0.78),
    ])
    context.fill(
      path,
      with: .linearGradient(
        gradient,
        startPoint: CGPoint(x: tileRect.midX, y: tileRect.minY),
        endPoint: CGPoint(x: tileRect.midX, y: tileRect.maxY)
      )
    )

    // Subtle inner highlight stroke for a premium, glassy edge.
    context.stroke(path, with: .color(.white.opacity(0.12 * alpha)), lineWidth: 1)

    drawLabel(tile.item, in: tileRect, alpha: alpha, context: &context)
  }

  private func drawLabel(_ item: TreemapItem, in rect: CGRect, alpha: Double, context: inout GraphicsContext) {
    // Skip text when the tile is too small to read.
    if rect.width < 48 || rect.height < 32 { return }

    let label = Text(item.label)
      .font(.system(size: 12, weight: .semibold))
      .foregroundColor(.white.opacity(alpha))

    let center = CGPoint(x: rect.midX, y: rect.midY)

    if rect.height >= 48 {
      // Room for two centered lines: label above center, value below.
      let value = Text(ChartFormatting.format(item.value))
        .font(.system(size: 10))
        .foregroundColor(.white.opacity(alpha * 0.85))
      context.draw(label, at: CGPoint(x: center.x, y: center.y - 7), anchor: .center)
      context.draw(value, at: CGPoint(x: center.x, y: center.y + 8), anchor: .center)
    } else {
      context.draw(label, at: center, anchor: .center)
    }
  }
}

/// A squarified treemap with rounded, gradient tiles and a staggered
/// scale-from-center reveal.
public struct TreemapChart: View {
  public let data: TreemapData
  public var animate: Bool
  public var replay: Int

  public init(data: TreemapData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: TreemapChartRenderer(data: data), animate: animate, duration: 0.9, replay: replay)
  }
}
