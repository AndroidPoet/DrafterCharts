import XCTest
@testable import DrafterCharts

final class SmoothPathTests: XCTestCase {
  func testSmoothPathThroughThreePoints() {
    let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 5), CGPoint(x: 20, y: 0)]
    XCTAssertFalse(smoothPath(pts).isEmpty)
  }
}
