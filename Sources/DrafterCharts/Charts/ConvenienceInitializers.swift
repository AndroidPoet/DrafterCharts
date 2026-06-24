//
//  ConvenienceInitializers.swift
//  DrafterCharts
//
//  Ergonomic, values-first initializers for the simplest single-series charts.
//  The data-struct initializers remain the primary, fully-featured API; these
//  just let trivial cases skip the nested struct, e.g. `LineChart(values: [1, 2])`
//  instead of `LineChart(data: SimpleLineChartData(labels: [], values: [1, 2]))`.
//

import SwiftUI

public extension AreaChart {
  /// Builds an area chart straight from `values`, with optional `labels`/`color`.
  init(
    values: [Float],
    labels: [String] = [],
    color: Color = DrafterColors.blue,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.init(
      data: AreaChartData(labels: labels, values: values, color: color),
      animate: animate,
      replay: replay
    )
  }
}

public extension LineChart {
  /// Builds a line chart straight from `values`, with optional `labels`/`color`.
  init(
    values: [Float],
    labels: [String] = [],
    color: Color = DrafterColors.blue,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.init(
      data: SimpleLineChartData(labels: labels, values: values, color: color),
      animate: animate,
      replay: replay
    )
  }
}

public extension StepLineChart {
  /// Builds a step-line chart straight from `values`, with optional `labels`/`color`.
  init(
    values: [Float],
    labels: [String] = [],
    color: Color = DrafterColors.teal,
    animate: Bool = true,
    replay: Int = 0
  ) {
    self.init(
      data: StepLineChartData(labels: labels, values: values, color: color),
      animate: animate,
      replay: replay
    )
  }
}

public extension SimpleBarChart {
  /// Builds a bar chart straight from `values`, with optional `labels`/`colors`
  /// (defaulting to the Drafter palette so bars are distinctly colored).
  init(
    values: [Float],
    labels: [String] = [],
    colors: [Color] = DrafterColors.palette,
    animate: Bool = true,
    replay: Int = 0
  ) {
    // The bar renderer derives one bar per label, so synthesize blank labels to
    // match the values when the caller doesn't supply any.
    let resolvedLabels = labels.isEmpty ? Array(repeating: "", count: values.count) : labels
    self.init(
      data: SimpleBarChartData(labels: resolvedLabels, values: values, colors: colors),
      animate: animate,
      replay: replay
    )
  }
}
