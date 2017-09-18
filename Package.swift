// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Boundaries",
  products: [
    .library(name: "Boundaries", targets: ["Boundaries"]),
    .library(name: "BoundariesTestSupport", targets: ["BoundariesTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .revision("aab186e")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .revision("6a292e9")),
  ],
  targets: [
    .target(
      name: "Boundaries",
      dependencies: ["Optics", "Prelude"]),
    .target(
      name: "BoundariesTestSupport",
      dependencies: ["Boundaries", "NonEmpty", "SnapshotTesting"]),
    .testTarget(
      name: "BoundariesTests",
      dependencies: ["Boundaries", "BoundariesTestSupport", "SnapshotTesting"]),
  ]
)
