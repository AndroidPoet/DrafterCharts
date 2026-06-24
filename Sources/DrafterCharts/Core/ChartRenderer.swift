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
