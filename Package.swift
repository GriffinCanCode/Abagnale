// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "abagnale",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "abagnale",
            targets: ["abagnale"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "abagnale",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]),
    ]
) 