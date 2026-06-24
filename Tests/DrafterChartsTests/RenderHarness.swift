//
//  RenderHarness.swift
//  DrafterChartsTests
//
//  Off-screen rendering utilities for the chart snapshot tests. Charts are pure
//  functions of their data, so instead of committing reference PNGs (which would
//  bloat the repo and need regenerating on every cosmetic tweak), we render each
//  chart to a bitmap with `ImageRenderer` and assert *structural invariants* on
//  the pixels — "this region is not blank", "content exists between the columns".
//  That catches the class of bug where a renderer silently draws nothing, while
//  staying robust to anti-aliasing and sub-pixel layout differences.
//

import CoreGraphics
import SwiftUI
import XCTest

/// A decoded RGBA8 bitmap with helpers for counting drawn content.
struct Bitmap {
  let data: [UInt8]
  let width: Int
  let height: Int
  let bytesPerRow: Int

  /// Counts pixels that differ from a white background by more than `threshold`
  /// on any channel, optionally restricted to `region` (in pixel coordinates).
  /// Charts are rendered over an opaque white backing, so "non-white" == "drawn".
  func contentPixels(in region: CGRect? = nil, threshold: Int = 24) -> Int {
    let rect = region ?? CGRect(x: 0, y: 0, width: width, height: height)
    let minX = max(0, Int(rect.minX))
    let maxX = min(width, Int(rect.maxX))
    let minY = max(0, Int(rect.minY))
    let maxY = min(height, Int(rect.maxY))
    guard minX < maxX, minY < maxY else { return 0 }

    var count = 0
    for y in minY..<maxY {
      let row = y * bytesPerRow
      for x in minX..<maxX {
        let i = row + x * 4
        let r = Int(data[i])
        let g = Int(data[i + 1])
        let b = Int(data[i + 2])
        if (255 - r) > threshold || (255 - g) > threshold || (255 - b) > threshold {
          count += 1
        }
      }
    }
    return count
  }

  /// Total pixel count, for ratio-based assertions.
  var pixelCount: Int { width * height }
}

@MainActor
enum RenderHarness {
  /// Renders a SwiftUI view over an opaque white background to an RGBA8 bitmap.
  /// Charts are built with their entrance animation disabled, so the renderer
  /// runs at full reveal progress (`progress == 1`) and the output is stable.
  static func bitmap<V: View>(
    _ view: V,
    size: CGSize = CGSize(width: 320, height: 240)
  ) throws -> Bitmap {
    let content = view
      .frame(width: size.width, height: size.height)
      .background(Color.white)

    let renderer = ImageRenderer(content: content)
    renderer.scale = 1

    let image = try XCTUnwrap(renderer.cgImage, "ImageRenderer produced no image")
    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var data = [UInt8](repeating: 0, count: bytesPerRow * height)

    let context = try XCTUnwrap(
      CGContext(
        data: &data,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ),
      "Could not create CGContext for pixel readback"
    )
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return Bitmap(data: data, width: width, height: height, bytesPerRow: bytesPerRow)
  }
}
