// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Switchius",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic: reading Chrome's profile list, labelling, remembering the choice.
        .target(name: "SwitchiusCore"),
        // The menu bar app. Thin AppKit layer over the core.
        .executableTarget(
            name: "Switchius",
            dependencies: ["SwitchiusCore"],
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        // Self-contained checks for the core (`make test`). No XCTest: it is not part of the
        // Command Line Tools, and we want `make install` to work without Xcode.
        .executableTarget(name: "SwitchiusChecks", dependencies: ["SwitchiusCore"]),
    ]
)
