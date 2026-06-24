//
//  CandlestickChart.swift
//  DrafterCharts
//
//  Candlestick (K-line) chart: each candle draws a high-low wick and an
//  open-close body (green when close >= open, coral otherwise), both growing
//  from the body center. Optional simple-moving-average overlays are drawn as
//  smooth Catmull-Rom curves revealed left-to-right. Mirrors the Compose
//  `CandlestickChartRenderer` geometry, colors, and entrance animation.
//

import SwiftUI

/// One candle: a label plus the open/high/low/close prices.
public struct Candle: Equatable, Sendable {
  public var label: String
  public var open: Float
  public var high: Float
  public var low: Float
  public var close: Float

  public init(label: String, open: Float, high: Float, low: Float, close: Float) {
    self.label = label
    self.open = open
    self.high = high
    self.low = low
    self.close = close
  }
}

/// A simple moving-average overlay (the classic MA5 / MA10 / MA20 study):
/// the trailing average of closing prices over `period` candles, drawn as a
/// smooth line in `color`.
public struct MovingAverage: Equatable, Sendable {
  public var period: Int
  public var color: Color

  public init(period: Int, color: Color) {
    self.period = period
    self.color = color
  }
}

/// Draws a candlestick chart into a canvas.
public struct CandlestickChartRenderer: ChartRenderer {
  public let candles: [Candle]
  public let movingAverages: [MovingAverage]
  public init(candles: [Candle], movingAverages: [MovingAverage] = []) {
    self.candles = candles
    self.movingAverages = movingAverages
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard !candles.isEmpty else { return }

    // Plot rect: ~10% inset on every side (matches Compose 0.1 fractions), but
    // floor the left inset so Y axis price labels don't clip at small sizes.
    let chartLeft = Swift.max(size.width * 0.1, 34)
    let chartTop = size.height * 0.1
    let chartWidth = size.width * 0.9 - chartLeft
    let chartHeight = size.height * 0.8
    let chartBottom = chartTop + chartHeight

    let minLow = CGFloat(candles.map(\.low).min() ?? 0)
    let maxHigh = CGFloat(candles.map(\.high).max() ?? 1)
    let range = max(maxHigh - minLow, 0.0001)

    let p = CGFloat(min(max(progress, 0), 1))

    func yFor(_ value: Float) -> CGFloat {
      chartBottom - (CGFloat(value) - minLow) / range * chartHeight
    }
    let slot = chartWidth / CGFloat(candles.count)
    func centerXFor(_ index: Int) -> CGFloat {
      chartLeft + slot * CGFloat(index) + slot / 2
    }

    // Axes (left + bottom).
    var axes = Path()
    axes.move(to: CGPoint(x: chartLeft, y: chartTop))
    axes.addLine(to: CGPoint(x: chartLeft, y: chartBottom))
    axes.move(to: CGPoint(x: chartLeft, y: chartBottom))
    axes.addLine(to: CGPoint(x: chartLeft + chartWidth, y: chartBottom))
    context.stroke(axes, with: .color(theme.grid), lineWidth: 1.5)

    // Y gridlines + labels from min(low)..max(high).
    let ySteps = 4
    for i in 0...ySteps {
      let value = minLow + range * (CGFloat(i) / CGFloat(ySteps))
      let y = chartBottom - (value - minLow) / range * chartHeight
      var line = Path()
      line.move(to: CGPoint(x: chartLeft, y: y))
      line.addLine(to: CGPoint(x: chartLeft + chartWidth, y: y))
      context.stroke(line, with: .color(theme.grid), lineWidth: 1)

      let text = Text(ChartFormatting.format(Float(value), decimals: 1))
        .font(.system(size: 10)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: chartLeft - 6, y: y), anchor: .trailing)
    }

    let count = candles.count
    let bodyWidth = max(slot * 0.6, 2)
    let labelEvery = max(1, count / 8)

    for (index, candle) in candles.enumerated() {
      let centerX = centerXFor(index)
      let isUp = candle.close >= candle.open
      let color = isUp ? DrafterColors.green : DrafterColors.coral

      // Body span + center, used as the animation origin.
      let bodyTopValue = max(candle.open, candle.close)
      let bodyBottomValue = min(candle.open, candle.close)
      let bodyCenterValue = (bodyTopValue + bodyBottomValue) / 2
      let centerY = yFor(bodyCenterValue)

      // Wick (low -> high), grown from the body center.
      let highY = yFor(candle.high)
      let lowY = yFor(candle.low)
      let animHighY = centerY + (highY - centerY) * p
      let animLowY = centerY + (lowY - centerY) * p
      var wick = Path()
      wick.move(to: CGPoint(x: centerX, y: animHighY))
      wick.addLine(to: CGPoint(x: centerX, y: animLowY))
      context.stroke(wick, with: .color(color.opacity(0.9)), lineWidth: 2)

      // Body rect (open<->close), grown from the center.
      let fullTopY = yFor(bodyTopValue)
      let fullBottomY = yFor(bodyBottomValue)
      let fullBodyHeight = max(fullBottomY - fullTopY, 2)
      let animBodyHeight = fullBodyHeight * p
      let bodyTopY = centerY - animBodyHeight / 2

      // Soft translucent halo behind the body for a premium feel.
      let halo = Path(
        roundedRect: CGRect(
          x: centerX - bodyWidth / 2 - 2, y: bodyTopY - 2,
          width: bodyWidth + 4, height: animBodyHeight + 4
        ),
        cornerRadius: 3
      )
      context.fill(halo, with: .color(color.opacity(0.18 * Double(p))))

      let body = Path(
        roundedRect: CGRect(
          x: centerX - bodyWidth / 2, y: bodyTopY,
          width: bodyWidth, height: animBodyHeight
        ),
        cornerRadius: 3
      )
      context.fill(body, with: .color(color.opacity(Double(p))))

      // Sparse X labels to avoid crowding.
      if index % labelEvery == 0 {
        let text = Text(candle.label).font(.system(size: 10)).foregroundColor(theme.label)
        context.draw(text, at: CGPoint(x: centerX, y: chartBottom + 6), anchor: .top)
      }
    }

    // Moving-average overlays (MA5 / MA10 / MA20 ...) as smooth curves,
    // revealed left-to-right with the candles' entrance animation.
    let reveal = chartLeft + chartWidth * p
    for ma in movingAverages {
      let points = movingAveragePoints(ma, centerXFor: centerXFor, yFor: yFor)
      guard points.count >= 2 else { continue }
      var clip = context
      clip.clip(to: Path(CGRect(x: 0, y: 0, width: reveal, height: size.height)))
      clip.stroke(
        smoothPath(points),
        with: .color(ma.color),
        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
      )
    }

    // Compact legend (MAn in each line's color), top-left inside the plot.
    var legendX = chartLeft + 4
    for ma in movingAverages {
      let label = "MA\(ma.period)"
      let text = Text(label).font(.system(size: 10)).foregroundColor(ma.color)
      context.draw(text, at: CGPoint(x: legendX, y: chartTop + 2), anchor: .topLeading)
      legendX += approxTextWidth(label, fontSize: 10) + 10
    }
  }

  public var accessibilityLabel: String { "Candlestick chart" }
  public var accessibilityValue: String {
    candles.isEmpty ? "No data" : "\(candles.count) candles, close \(AccessibilityFormat.range(candles.map { $0.close }))"
  }

  /// Builds the smoothed point list for a single moving-average line: the
  /// trailing average of closing prices over `ma.period` candles.
  private func movingAveragePoints(
    _ ma: MovingAverage,
    centerXFor: (Int) -> CGFloat,
    yFor: (Float) -> CGFloat
  ) -> [CGPoint] {
    let count = candles.count
    guard ma.period > 0, ma.period <= count else { return [] }
    var points: [CGPoint] = []
    points.reserveCapacity(count)
    for i in (ma.period - 1)..<count {
      var sum: Float = 0
      for j in (i - ma.period + 1)...i { sum += candles[j].close }
      points.append(CGPoint(x: centerXFor(i), y: yFor(sum / Float(ma.period))))
    }
    return points
  }
}

/// Rough advance width for legend layout (no UIKit/AppKit text metrics in pure SwiftUI).
private func approxTextWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
  CGFloat(text.count) * fontSize * 0.62
}

/// A candlestick (K-line) chart with high-low wicks, open-close bodies, and
/// optional moving-average overlays, with an animated entrance.
public struct CandlestickChart: View {
  public let candles: [Candle]
  public let movingAverages: [MovingAverage]
  public var animate: Bool
  public var replay: Int

  public init(candles: [Candle], movingAverages: [MovingAverage] = [], animate: Bool = true, replay: Int = 0) {
    self.candles = candles
    self.movingAverages = movingAverages
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: CandlestickChartRenderer(candles: candles, movingAverages: movingAverages), animate: animate, duration: 0.9, replay: replay)
  }
}
