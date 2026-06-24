# Contributing to DrafterCharts

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Getting started

DrafterCharts is a pure Swift Package — no Xcode project file is checked in.
Clone the repo and build from the command line:

```bash
git clone https://github.com/AndroidPoet/DrafterCharts.git
cd DrafterCharts
swift build
swift test
```

You can also open `Package.swift` directly in Xcode, or run the bundled demo:

```bash
swift run DrafterChartsDemo
```

## Preparing a pull request for review

Ensure your change is properly formatted and passes lint by running
[SwiftLint](https://github.com/realm/SwiftLint) from the repository root:

```bash
brew install swiftlint   # one-time
swiftlint --strict
```

Then make sure the package builds and all tests pass:

```bash
swift build
swift test
```

Please correct any failures before requesting a review. CI runs the same
SwiftLint, build, and test steps on every pull request.

## Adding a new chart

Each chart follows the same three-part pattern (see `Charts/AreaChart.swift`
for the reference implementation):

1. An immutable, `Equatable & Sendable` data struct.
2. A pure `ChartRenderer` that draws into a `GraphicsContext`.
3. A thin `View` that hosts the renderer in `ChartCanvas` for theming and the
   reveal animation.

Keep drawing logic inside the renderer so it stays testable and reusable, and
read colors from the injected `DrafterThemeColors` rather than hard-coding them.

## Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
for more information on using pull requests.
