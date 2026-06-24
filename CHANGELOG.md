# Changelog

All notable changes to DrafterCharts are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-24

### Added
- Values-first convenience initializers for the simplest single-series charts, so
  trivial cases can skip the data struct:
  ```swift
  LineChart(values: [40, 65, 50, 80])
  AreaChart(values: [12, 18, 9, 24], color: .teal)
  SimpleBarChart(values: [24, 38, 30, 46])
  StepLineChart(values: [10, 25, 18, 32])
  ```
  The `init(data:)` form remains the primary API for labels, multi-series, and
  per-element colors.
- Snapshot render tests: every chart family is rendered off-screen and asserted to
  draw non-trivial content, including a targeted test that the Sankey flow bands
  fill the gap between node columns.

### Fixed
- Sankey chart flow bands now render. The band layer was clipped to a near-infinite
  rect, which produced an empty clip region so no ribbons were drawn.
- Sankey edge-column node labels (e.g. `Source`) no longer clip at the canvas edge;
  labels are clamped by their measured width.

### Changed
- Demo gallery no longer uses `AnyView`; cards are concrete `@ViewBuilder` views,
  preserving SwiftUI view diffing.

## [1.0.0] - 2026-06-24

### Added
- Initial release: a native SwiftUI charting library with 27 chart types built on
  `Canvas`/`GraphicsContext`, a shared `ChartRenderer` + `ChartCanvas` architecture,
  Catmull-Rom smoothing, gradient fills, left-to-right reveal animations, and
  light/dark theming via `DrafterThemeColors`.

[1.1.0]: https://github.com/AndroidPoet/DrafterCharts/releases/tag/1.1.0
[1.0.0]: https://github.com/AndroidPoet/DrafterCharts/releases/tag/1.0.0
