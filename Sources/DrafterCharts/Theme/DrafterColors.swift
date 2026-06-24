//
//  DrafterColors.swift
//  DrafterCharts
//
//  The Drafter palette and theme color sets. Ported 1:1 from the Compose
//  library's `theme/DrafterColors.kt` so the two stay visually identical.
//

import SwiftUI

public extension Color {
  /// Creates a `Color` from a 24-bit RGB hex value, e.g. `Color(hex: 0x4C8DF6)`.
  init(hex: UInt32, alpha: Double = 1.0) {
    let r = Double((hex >> 16) & 0xFF) / 255.0
    let g = Double((hex >> 8) & 0xFF) / 255.0
    let b = Double(hex & 0xFF) / 255.0
    self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
  }
}

/// Immutable Drafter color constants — the 8-color series palette plus the
/// light/dark surface, grid, and label colors.
public enum DrafterColors {
  // Series palette (deliberately calm, premium tones — no harsh red).
  public static let blue = Color(hex: 0x4C8DF6)
  public static let teal = Color(hex: 0x2FC4C0)
  public static let violet = Color(hex: 0x7C6BF2)
  public static let amber = Color(hex: 0xF6B24C)
  public static let green = Color(hex: 0x49C17A)
  public static let coral = Color(hex: 0xF2766B)
  public static let pink = Color(hex: 0xEC6B9A)
  public static let indigo = Color(hex: 0x5B6BF0)

  /// The ordered series palette used to color slices/series by index.
  public static let palette: [Color] = [blue, teal, violet, amber, green, coral, pink, indigo]

  // Light theme.
  public static let gridLight = Color(hex: 0xEDF0F5)
  public static let labelLight = Color(hex: 0x9AA3B2)
  public static let surfaceLight = Color(hex: 0xFFFFFF)

  // Dark theme.
  public static let gridDark = Color(hex: 0x2A2E37)
  public static let labelDark = Color(hex: 0x8A92A2)
  public static let surfaceDark = Color(hex: 0x1B1E25)
}

/// The resolved color set a chart draws with. Value type — pass by value.
public struct DrafterThemeColors: Equatable, Sendable {
  public var palette: [Color]
  public var grid: Color
  public var label: Color
  public var surface: Color
  public var isDark: Bool

  public init(palette: [Color], grid: Color, label: Color, surface: Color, isDark: Bool) {
    self.palette = palette
    self.grid = grid
    self.label = label
    self.surface = surface
    self.isDark = isDark
  }

  /// The light theme color set.
  public static let light = DrafterThemeColors(
    palette: DrafterColors.palette,
    grid: DrafterColors.gridLight,
    label: DrafterColors.labelLight,
    surface: DrafterColors.surfaceLight,
    isDark: false
  )

  /// The dark theme color set.
  public static let dark = DrafterThemeColors(
    palette: DrafterColors.palette,
    grid: DrafterColors.gridDark,
    label: DrafterColors.labelDark,
    surface: DrafterColors.surfaceDark,
    isDark: true
  )

  /// Cycles the palette by index, wrapping around.
  public func color(at index: Int) -> Color {
    palette[((index % palette.count) + palette.count) % palette.count]
  }
}
