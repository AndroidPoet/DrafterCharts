# Changelog

All notable changes to DrafterCharts are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the version
is `0.x`, the public API may still change between minor releases.

## [0.1.0] - 2026-06-25

Initial public (pre-1.0) release.

### Added
- A native SwiftUI charting library with 27 chart types built on
  `Canvas`/`GraphicsContext`, a shared `ChartRenderer` + `ChartCanvas`
  architecture, Catmull-Rom smoothing, soft gradient fills, left-to-right reveal
  animations (`replay` to re-run), and light/dark theming via `DrafterThemeColors`.
- A **point-based, type-safe data API**. Charts take bound elements instead of
  parallel `labels`/`values`/`colors` arrays, so a label can never desync from
  its value and a color can never index past its data — the mismatch is
  unrepresentable:
  - single-series charts take `[ChartPoint]` (`AreaChart`, `LineChart`, `StepLineChart`);
  - multi-series charts take `[ChartSeries]` + optional `categories`
    (`GroupedLineChart`, `StackedLineChart`, `GroupedBarChart`, `StackedBarChart`,
    `StreamGraphChart`);
  - `SimpleBarChart` takes `[BarItem]`, `WaterfallChart` takes `[WaterfallStep]`,
    `ScatterPlot` takes `[ScatterPoint]`, `RadarChart` takes `[RadarSeries]`,
    `GanttChart` takes `[GanttTask]` with per-task color.
  - `values:`-first convenience initializers exist for the simplest charts.
- `WaterfallChart` supports a leading **Start** bar (`startLabel`) and a trailing
  **Total** bar (`totalLabel`) — the classic Start … Total waterfall.
- Off-screen render tests for every chart family (including a regression test
  that the Sankey flow bands fill the gap between node columns) plus ragged
  multi-series and empty-input safety tests.

[0.1.0]: https://github.com/AndroidPoet/DrafterCharts/releases/tag/0.1.0
