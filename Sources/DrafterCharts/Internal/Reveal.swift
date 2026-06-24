//
//  Reveal.swift
//  DrafterCharts
//
//  The shared entrance-animation driver. Every chart traces itself in with a
//  left-to-right reveal (progress 0 -> 1), matching the Compose library. This is
//  the idiomatic SwiftUI way to feed an animated scalar into a `Canvas`: animate
//  a `@State` value with `withAnimation`, and read it inside the draw closure so
//  SwiftUI interpolates it frame-by-frame.
//

import SwiftUI

/// Wraps chart content and supplies a live reveal `progress` in `0...1`.
///
/// The animation runs on appear and restarts whenever `replay` changes — bind a
/// button to an incrementing counter to replay every chart's entrance at once.
///
/// ```swift
/// ChartReveal(replay: replayKey) { progress in
///   LineChart(data: data, reveal: progress)
/// }
/// ```
public struct ChartReveal<Content: View>: View {
  private let duration: Double
  private let delay: Double
  private let replay: Int
  private let content: (Double) -> Content

  @State private var progress: Double = 0

  /// - Parameters:
  ///   - duration: reveal length in seconds (default 1.0 — a deliberate, premium trace).
  ///   - delay: stagger delay before the reveal starts (use the grid index for a cascade).
  ///   - replay: change this value to replay the entrance animation.
  public init(
    duration: Double = 1.0,
    delay: Double = 0,
    replay: Int = 0,
    @ViewBuilder content: @escaping (Double) -> Content
  ) {
    self.duration = duration
    self.delay = delay
    self.replay = replay
    self.content = content
  }

  public var body: some View {
    content(progress)
      .onAppear(perform: animateIn)
      .onChange(of: replay) { _ in
        progress = 0
        animateIn()
      }
  }

  private func animateIn() {
    withAnimation(.easeInOut(duration: duration).delay(delay)) {
      progress = 1
    }
  }
}
