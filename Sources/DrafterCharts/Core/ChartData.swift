//
//  ChartData.swift
//  DrafterCharts
//
//  The shared, point-based data primitives. Every chart consumes these instead
//  of parallel `labels` / `values` / `colors` arrays, so a label can never
//  desync from its value and a color can never index past its data — the
//  mismatch is unrepresentable rather than handled at runtime.
//

import SwiftUI

/// A single labeled data point: one label bound to one value.
///
/// ```swift
/// ChartPoint("Jan", 40)   // labeled
/// ChartPoint(40)          // unlabeled
/// ```
public struct ChartPoint: Equatable, Sendable {
  public var label: String
  public var value: Float

  public init(_ label: String, _ value: Float) {
    self.label = label
    self.value = value
  }

  /// An unlabeled point (blank x-axis label).
  public init(_ value: Float) {
    self.label = ""
    self.value = value
  }
}

/// A named, colored series of values for multi-series charts (grouped/stacked
/// lines and bars, stream graphs). The color is bound to the series, so there is
/// no separate `colors` array to fall out of sync.
public struct ChartSeries: Equatable, Sendable {
  public var name: String
  public var color: Color
  public var values: [Float]

  public init(name: String = "", color: Color, values: [Float]) {
    self.name = name
    self.color = color
    self.values = values
  }
}

/// A single bar with an optional explicit color (falls back to the theme palette
/// by position when `nil`).
public struct BarItem: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color?

  public init(_ label: String, _ value: Float, color: Color? = nil) {
    self.label = label
    self.value = value
    self.color = color
  }

  /// An unlabeled bar.
  public init(_ value: Float, color: Color? = nil) {
    self.label = ""
    self.value = value
    self.color = color
  }
}

/// A single waterfall step: a labeled incremental change with an optional color.
public struct WaterfallStep: Equatable, Sendable {
  public var label: String
  public var value: Float
  public var color: Color?

  public init(_ label: String, _ value: Float, color: Color? = nil) {
    self.label = label
    self.value = value
    self.color = color
  }
}

/// A single scatter point with an optional explicit color.
public struct ScatterPoint: Equatable, Sendable {
  public var x: Float
  public var y: Float
  public var color: Color?

  public init(x: Float, y: Float, color: Color? = nil) {
    self.x = x
    self.y = y
    self.color = color
  }
}

/// A radar series: a color bound to a set of axis → value readings. Axes are
/// keyed by name, so a value can never bind to the wrong axis.
public struct RadarSeries: Equatable, Sendable {
  public var color: Color
  public var values: [String: Float]

  public init(color: Color, values: [String: Float]) {
    self.color = color
    self.values = values
  }
}
