//
//  ChartFormatting.swift
//  DrafterCharts
//
//  Deterministic, platform-independent number formatting for axis labels and
//  value read-outs. Ported from the Compose library's `core/NumberFormat.kt`:
//  integer arithmetic avoids float-precision drift and drops trailing zeros
//  (3.0 -> "3", 3.10 -> "3.1").
//

import Foundation

public enum ChartFormatting {
  /// Formats `value` with up to `decimals` fractional digits, trimming trailing
  /// zeros. Handles NaN / infinity gracefully.
  public static func format(_ value: Float, decimals: Int = 1) -> String {
    if value.isNaN { return "NaN" }
    if value.isInfinite { return value > 0 ? "∞" : "-∞" }

    let negative = value < 0
    let magnitude = abs(Double(value))
    var scale = 1
    for _ in 0..<max(0, decimals) { scale *= 10 }

    let scaled = (magnitude * Double(scale)).rounded()
    let whole = Int(scaled) / scale
    var frac = Int(scaled) % scale

    if frac == 0 || decimals <= 0 {
      return (negative && (whole != 0 || scaled != 0) ? "-" : "") + "\(whole)"
    }

    // Build the fractional part, trimming trailing zeros.
    var digits = String(frac)
    while digits.count < decimals { digits = "0" + digits }
    while digits.hasSuffix("0") { digits.removeLast() }
    frac = Int(digits) ?? 0
    if digits.isEmpty {
      return (negative ? "-" : "") + "\(whole)"
    }
    return (negative ? "-" : "") + "\(whole).\(digits)"
  }
}
