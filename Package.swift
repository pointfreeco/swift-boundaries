// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Boundaries",
  products: [
    .library(name: "Boundaries", targets: ["Boundaries"]),
    .library(name: "BoundariesTestSupport", targets: ["BoundariesTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .revision("06e745a")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .revision("2c2b390")),
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
