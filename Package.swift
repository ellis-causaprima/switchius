// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChromeSwitch",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic: reading Chrome's profile list, labelling, remembering the choice.
        .target(name: "ChromeSwitchCore"),
        // The menu bar app. Thin AppKit layer over the core.
        .executableTarget(
            name: "ChromeSwitch",
            dependencies: ["ChromeSwitchCore"],
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        // Self-contained checks for the core (`make test`). No XCTest: it is not part of the
        // Command Line Tools, and we want `make install` to work without Xcode.
        .executableTarget(name: "ChromeSwitchChecks", dependencies: ["ChromeSwitchCore"]),
    ]
)
