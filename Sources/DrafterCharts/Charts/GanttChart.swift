//
//  GanttChart.swift
//  DrafterCharts
//
//  Horizontal Gantt timeline: a left margin reserved for task-name labels, a
//  month axis inferred from the task ranges, and one rounded horizontal bar per
//  task placed at (startMonth, duration). Each bar's width (and opacity) grows
//  with the reveal progress. Ported from the Kotlin Compose `GanttChart`.
//
//  Follows the canonical chart pattern: an immutable data struct, a pure
//  `ChartRenderer`, and a thin view that hosts it in `ChartCanvas`.
//

import SwiftUI

/// One row of a `GanttChart`: a `name`, its `startMonth` on the timeline, and a
/// `duration` in months.
public struct GanttTask: Equatable, Sendable {
  public var name: String
  public var startMonth: Float
  public var duration: Float

  public init(name: String, startMonth: Float, duration: Float) {
    self.name = name
    self.startMonth = startMonth
    self.duration = duration
  }
}

/// Data for a `GanttChart`: the ordered `tasks` plus a parallel list of bar
/// `taskColors` (cycled/defaulted when shorter than `tasks`).
public struct GanttChartData: Equatable, Sendable {
  public var tasks: [GanttTask]
  public var taskColors: [Color]

  public init(tasks: [GanttTask], taskColors: [Color]? = nil) {
    self.tasks = tasks
    self.taskColors = taskColors ?? Array(repeating: DrafterColors.blue, count: tasks.count)
  }
}

/// Draws a `GanttChartData` into a canvas as a horizontal timeline of bars.
public struct GanttChartRenderer: ChartRenderer {
  public let data: GanttChartData
  public init(data: GanttChartData) { self.data = data }

  /// Largest `startMonth + duration` across all tasks, clamped to at least 1.
  private var maxMonth: Float {
    let m = data.tasks.map { $0.startMonth + $0.duration }.max() ?? 1
    return max(m, 1)
  }

  public func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double) {
    guard size.width >= 1, size.height >= 1, !data.tasks.isEmpty else { return }

    // Compose layout: 20% left margin, 70% width, 10% top inset, 80% height.
    let chartHeight = size.height * 0.8
    let chartWidth = size.width * 0.7
    let chartTop = size.height * 0.1
    let chartBottom = chartTop + chartHeight
    let chartLeft = size.width * 0.2

    let safeMaxMonth = CGFloat(maxMonth)
    let tasks = data.tasks

    drawAxes(in: &context, left: chartLeft, top: chartTop, bottom: chartBottom, width: chartWidth, theme: theme)
    drawYAxisLabels(in: &context, left: chartLeft, top: chartTop, bottom: chartBottom, tasks: tasks, theme: theme)
    drawXAxisLabels(
      in: &context,
      left: chartLeft,
      bottom: chartBottom,
      width: chartWidth,
      safeMaxMonth: safeMaxMonth,
      canvasSize: size,
      tasks: tasks,
      theme: theme
    )

    // Bars.
    let taskHeight = max(chartHeight / CGFloat(tasks.count), 1)
    let p = CGFloat(min(max(progress, 0), 1))
    for (index, task) in tasks.enumerated() {
      let startX = chartLeft + (CGFloat(task.startMonth) / safeMaxMonth) * chartWidth
      let width = max((CGFloat(task.duration) / safeMaxMonth) * chartWidth * p, 1)
      let y = chartTop + CGFloat(index) * taskHeight
      // Bars are driven by `tasks`; a shorter/longer `taskColors` can never add or
      // drop a bar. Bounds-check the color and fall back to the theme palette.
      let color = data.taskColors.indices.contains(index) ? data.taskColors[index] : theme.color(at: index)
      let barHeight = max(taskHeight * 0.8, 1)
      let rect = CGRect(x: startX, y: y + taskHeight * 0.1, width: width, height: barHeight)
      let bar = Path(roundedRect: rect, cornerRadius: min(6, barHeight / 2))
      context.fill(bar, with: .color(color.opacity(progress)))
    }
  }

  // MARK: - Axes & labels

  private func drawAxes(
    in context: inout GraphicsContext,
    left: CGFloat, top: CGFloat, bottom: CGFloat, width: CGFloat,
    theme: DrafterThemeColors
  ) {
    let axisColor = theme.label
    var yAxis = Path()
    yAxis.move(to: CGPoint(x: left, y: top))
    yAxis.addLine(to: CGPoint(x: left, y: bottom))
    context.stroke(yAxis, with: .color(axisColor), lineWidth: 2)

    var xAxis = Path()
    xAxis.move(to: CGPoint(x: left, y: bottom))
    xAxis.addLine(to: CGPoint(x: left + width, y: bottom))
    context.stroke(xAxis, with: .color(axisColor), lineWidth: 2)
  }

  private func drawYAxisLabels(
    in context: inout GraphicsContext,
    left: CGFloat, top: CGFloat, bottom: CGFloat,
    tasks: [GanttTask], theme: DrafterThemeColors
  ) {
    let taskHeight = max((bottom - top) / CGFloat(tasks.count), 1)
    for (index, task) in tasks.enumerated() {
      let yCenter = top + CGFloat(index) * taskHeight + taskHeight / 2
      // Truncate so long names stay inside the narrow left margin.
      let name = task.name.count > 9 ? String(task.name.prefix(8)) + "…" : task.name
      let text = Text(name).font(.system(size: 9)).foregroundColor(theme.label)
      context.draw(text, at: CGPoint(x: left - 4, y: yCenter), anchor: .trailing)
    }
  }

  private func drawXAxisLabels(
    in context: inout GraphicsContext,
    left: CGFloat, bottom: CGFloat, width: CGFloat,
    safeMaxMonth: CGFloat, canvasSize: CGSize,
    tasks: [GanttTask], theme: DrafterThemeColors
  ) {
    // Distinct integer months spanned by the tasks, plus 0 and the max month.
    var months = Set<Int>()
    for task in tasks {
      let start = Int(task.startMonth)
      let end = Int(task.startMonth + task.duration)
      if start <= end { months.formUnion(start...end) }
    }
    months.insert(0)
    months.insert(Int(safeMaxMonth))

    // Thin out ticks so labels don't overlap at small widths (~14pt each).
    let sorted = months.sorted()
    let maxTicks = max(2, Int(width / 18))
    let step = max(1, Int(ceil(Double(sorted.count) / Double(maxTicks))))
    for (i, monthInt) in sorted.enumerated() {
      let isLast = monthInt == sorted.last
      guard i % step == 0 || isLast else { continue }
      let fraction = CGFloat(monthInt) / safeMaxMonth
      // Clamp the x so the rightmost tick stays inside the canvas.
      let x = min(left + fraction * width, canvasSize.width - 6)
      let text = Text("\(monthInt)").font(.system(size: 9)).foregroundColor(theme.label)
      let anchor: UnitPoint = isLast ? .topTrailing : .top
      context.draw(text, at: CGPoint(x: x, y: bottom + 6), anchor: anchor)
    }
  }
}

/// A horizontal Gantt timeline with rounded task bars and an animated reveal.
public struct GanttChart: View {
  public let data: GanttChartData
  public var animate: Bool
  public var replay: Int

  public init(data: GanttChartData, animate: Bool = true, replay: Int = 0) {
    self.data = data
    self.animate = animate
    self.replay = replay
  }

  public var body: some View {
    ChartCanvas(renderer: GanttChartRenderer(data: data), animate: animate, duration: 2.0, replay: replay)
  }
}
