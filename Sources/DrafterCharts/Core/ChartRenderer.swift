//
//  ChartRenderer.swift
//  DrafterCharts
//
//  The shared rendering contract. Every chart separates its geometry/drawing
//  (a `ChartRenderer`) from its SwiftUI view, mirroring the Compose library's
//  renderer pattern. A renderer is a pure value: given a `GraphicsContext`, the
//  draw rect, the theme, and a reveal `progress`, it draws itself. Keeping the
//  logic out of the view body makes it testable and lets the view stay a thin,
//  POD `Canvas` wrapper.
//

import SwiftUI

/// Draws one chart into a `Canvas`. Implementations hold immutable data + style.
public protocol ChartRenderer {
  /// Draws the chart.
  /// - Parameters:
  ///   - context: the live graphics context (already a value copy per frame).
  ///   - size: the canvas size in points.
  ///   - theme: resolved colors to draw with.
  ///   - progress: entrance reveal in `0...1` (1 = fully drawn).
  func draw(in context: inout GraphicsContext, size: CGSize, theme: DrafterThemeColors, progress: Double)

  /// A short VoiceOver label naming the kind of chart, e.g. `"Line chart"`.
  /// A `Canvas` is opaque to assistive technology, so each renderer supplies the
  /// text that makes its drawing legible to VoiceOver. Defaults to `"Chart"`.
  var accessibilityLabel: String { get }

  /// A VoiceOver value summarizing the chart's data — counts, range, and a few
  /// representative points — read out after the label. Defaults to empty.
  var accessibilityValue: String { get }
}

public extension ChartRenderer {
  var accessibilityLabel: String { "Chart" }
  var accessibilityValue: String { "" }
}

/// Shared formatting so every renderer's `accessibilityValue` reads consistently.
/// Trims trailing zeros so `40.0` announces as `"40"` and `3.50` as `"3.5"`.
enum AccessibilityFormat {
  static func number(_ value: Float) -> String {
    if value == value.rounded() { return String(Int(value.rounded())) }
    var text = String(format: "%.2f", value)
    while text.hasSuffix("0") { text.removeLast() }
    if text.hasSuffix(".") { text.removeLast() }
    return text
  }

  /// "Jan 40, Feb 65, Mar 30" style list, capped so long series stay terse.
  static func points(_ pairs: [(String, Float)], limit: Int = 12) -> String {
    let shown = pairs.prefix(limit).map { pair in
      pair.0.isEmpty ? number(pair.1) : "\(pair.0) \(number(pair.1))"
    }
    let suffix = pairs.count > limit ? ", and \(pairs.count - limit) more" : ""
    return shown.joined(separator: ", ") + suffix
  }

  /// "ranging 20 to 95" — handy when listing every point would be noise.
  static func range(_ values: [Float]) -> String {
    guard let lo = values.min(), let hi = values.max() else { return "" }
    return "ranging \(number(lo)) to \(number(hi))"
  }
}

/// A thin, reusable SwiftUI view that hosts any `ChartRenderer` in a `Canvas`,
/// reads the theme from the environment, and traces the chart in with the shared
/// reveal animation. This is the single entry point every concrete chart view
/// wraps — so the animation/theming plumbing lives in exactly one place.
///
/// ```swift
/// public struct AreaChart: View {
///   public let data: AreaChartData
///   public var animate = true
///   public var replay = 0
///   public var body: some View {
///     ChartCanvas(renderer: AreaChartRenderer(data: data), animate: animate, replay: replay)
///   }
/// }
/// ```
public struct ChartCanvas<R: ChartRenderer>: View {
  private let renderer: R
  private let animate: Bool
  private let duration: Double
  private let replay: Int

  @Environment(\.drafterTheme) private var theme
  @State private var progress: Double = 0

  public init(renderer: R, animate: Bool = true, duration: Double = 1.0, replay: Int = 0) {
    self.renderer = renderer
    self.animate = animate
    self.duration = duration
    self.replay = replay
  }

  public var body: some View {
    // `RevealCanvas` conforms to `Animatable`, so SwiftUI interpolates `progress`
    // and re-runs the `Canvas` every frame. A plain `@State` Double read inside a
    // `Canvas` closure does NOT animate — it would jump straight to the final
    // frame — which is the trap this avoids.
    RevealCanvas(renderer: renderer, theme: theme, progress: animate ? progress : 1)
      // A `Canvas` is a single opaque drawing to VoiceOver. Collapse it into one
      // accessibility element and describe it from the renderer so the chart is
      // announced as "<kind>, <data summary>" instead of being skipped over.
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(renderer.accessibilityLabel))
      .accessibilityValue(Text(renderer.accessibilityValue))
      .accessibilityHidden(renderer.accessibilityValue.isEmpty && renderer.accessibilityLabel == "Chart")
      .onAppear { restart() }
      .onChange(of: replay) { _ in restart() }
  }

  private func restart() {
    guard animate else { return }
    var reset = Transaction()
    reset.disablesAnimations = true
    withTransaction(reset) { progress = 0 }
    withAnimation(.easeInOut(duration: duration)) { progress = 1 }
  }
}

/// An `Animatable` `Canvas` host. SwiftUI drives `animatableData` (the reveal
/// `progress`) through each interpolated value during an animation and
/// re-evaluates `body`, so the `Canvas` redraws frame-by-frame.
private struct RevealCanvas<R: ChartRenderer>: View, Animatable {
  let renderer: R
  let theme: DrafterThemeColors
  var progress: Double

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  var body: some View {
    Canvas { context, size in
      var ctx = context
      renderer.draw(in: &ctx, size: size, theme: theme, progress: progress)
    }
  }
}
