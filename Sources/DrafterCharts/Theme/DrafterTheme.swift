//
//  DrafterTheme.swift
//  DrafterCharts
//
//  Theme propagation via the SwiftUI environment. Charts read the resolved
//  `DrafterThemeColors` once from the environment instead of recomputing it.
//  This is the SwiftUI equivalent of Compose's `LocalDrafterTheme`.
//

import SwiftUI

private struct DrafterThemeKey: EnvironmentKey {
  // Stable default value (no per-access allocation) — required for @Environment.
  static let defaultValue: DrafterThemeColors = .light
}

public extension EnvironmentValues {
  /// The active Drafter chart theme. Defaults to `.light`.
  var drafterTheme: DrafterThemeColors {
    get { self[DrafterThemeKey.self] }
    set { self[DrafterThemeKey.self] = newValue }
  }
}

public extension View {
  /// Sets the Drafter chart theme for this subtree.
  func drafterTheme(_ theme: DrafterThemeColors) -> some View {
    environment(\.drafterTheme, theme)
  }

  /// Convenience: pick light/dark by a boolean (e.g. `colorScheme == .dark`).
  func drafterTheme(dark: Bool) -> some View {
    environment(\.drafterTheme, dark ? .dark : .light)
  }
}
