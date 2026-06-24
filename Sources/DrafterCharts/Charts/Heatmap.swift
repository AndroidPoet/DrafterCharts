//
//  Heatmap.swift
//  DrafterCharts
//
//  GitHub-style contribution calendar: 53 week columns by 7 day rows of small
//  rounded cells. Each cell's color is bucketed from its contribution count
//  (empty cells fall back to the background square color), and the whole grid
//  fades in with the reveal progress. Mirrors the Compose `Heatmap` renderer.
//

import Foundation
import SwiftUI

/// A single day's contribution count, keyed by its calendar date.
public struct ContributionData: Equatable, Sendable {
  public var date: Date
  public var count: Int

  public init(date: Date, count: Int) {
    self.date = date
    self.count = count
  }
}

/// Data for a `Heatmap`: the per-day contributions plus the base (filled) color
/// and the color used for empty cells.
public struct ContributionHeatmapData: Equatable, Sendable {
  public var contributions: [ContributionData]
  public var baseColor: Color
  public var backgroundSquareColor: Color

  public init(
    contributions: [ContributionData],
    baseColor: Color = Color(hex: 0x40C463),
    backgroundSquareColor: Color = Color(hex: 0x2D333B)
  ) {
    self.contributions = contributions
    self.baseColor = baseColor
    self.backgroundSquareColor = backgroundSquareColor
  }
}

/// Lays out and draws a `ContributionHeatmapData` as a contribution calendar.
public struct HeatmapDataRenderer: ChartRenderer {
  public let data: ContributionHeatmapData

  /// Cell edge length in points (~8pt, like the Compose `8.dp`).
  private let cellSize: CGFloat = 8
  /// Gap between adjacent cells (~2pt, like the Compose `2.dp`).
  private let cellPadding: CGFloat = 2
  /// Number of week columns (a full year ≈ 53 weeks).
  private let weeks = 53

  public init(data: ContributionHeatmapData) { self.data = data }

  /// Buckets a day's count into a GitHub-style intensity color. Empty days use a
  /// faint square (light gray on light themes, the configured dark square on dark
  /// themes); non-empty days fade the base color through four alpha steps.
  private func contributionColor(count: Int, theme: DrafterThemeColors) -> Color {
    switch count {
    case ..<1: return theme.isDark ? data.backgroundSquareColor : Color(hex: 0xEBEDF0)
    case 1...3: return data.baseColor.opacity(0.35)
    case 4...6: return data.baseColor.opacity(0.6)
    case 7...9: return data.baseColor.opacity(0.8)
    default: return data.baseColor
    }
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    let calendar = Calendar.current

    // Anchor the trailing-year window to the DATA's own latest day (falling back
    // to today when empty), so supplied contributions always land in-range.
    var countsByDay: [Date: Int] = [:]
    var latest = calendar.startOfDay(for: Date())
    for contribution in data.contributions {
      let day = calendar.startOfDay(for: contribution.date)
      countsByDay[day, default: 0] += contribution.count
    }
    if let dataLatest = countsByDay.keys.max() { latest = dataLatest }

    // Start `weeks*7` days back, aligned to the start of that week (Sunday).
    guard let rawStart = calendar.date(byAdding: .day, value: -(weeks * 7 - 1), to: latest) else { return }
    let weekdayIndex = calendar.component(.weekday, from: rawStart) - 1 // 0 = Sunday
    let startDate = calendar.date(byAdding: .day, value: -weekdayIndex, to: rawStart) ?? rawStart

    // Size the grid to fit the card with square, centered cells.
    let cols = CGFloat(weeks)
    let step = max(cellSize, min(size.width / cols, size.height / 7))
    let cell = max(2, step - cellPadding)
    let cornerRadius = min(2, cell * 0.25)
    let gridWidth = step * cols
    let gridHeight = step * 7
    let originX = (size.width - gridWidth) / 2
    let originY = (size.height - gridHeight) / 2

    // Fade the whole grid in with the reveal progress.
    let alpha = min(max(progress, 0), 1)

    var currentDate = startDate
    outer: for week in 0..<weeks {
      for dayOfWeek in 0...6 {
        if currentDate > latest { break outer }

        let count = countsByDay[currentDate] ?? 0
        let color = contributionColor(count: count, theme: theme)

        let x = originX + CGFloat(week) * step
        let y = originY + CGFloat(dayOfWeek) * step
        let rect = CGRect(x: x, y: y, width: cell, height: cell)
        context.fill(Path(roundedRect: rect, cornerRadius: cornerRadius), with: .color(color.opacity(alpha)))

        guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break outer }
        currentDate = next
      }
    }
  }
}

/// A GitHub-style contribution heatmap with an animated fade-in reveal.
public struct Heatmap: View {
  public let data: ContributionHeatmapData
  public var animate: Bool
  public var replay: Int

  public init(data: ContributionHeatmapData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: HeatmapDataRenderer(data: data), animate: animate, duration: 1.0, replay: replay)
  }
}
