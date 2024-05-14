// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AcuantiOSSDKV11",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "AcuantCommon", targets: ["AcuantCommon"]),
        .library(name: "AcuantImagePreparation", targets: ["AcuantImagePreparation"]),
        .library(name: "AcuantDocumentProcessing", targets: ["AcuantDocumentProcessing"]),
        .library(name: "AcuantFaceMatch", targets: ["AcuantFaceMatch"]),
        .library(name: "AcuantPassiveLiveness", targets: ["AcuantPassiveLiveness"]),
        .library(name: "AcuantHGLiveness", targets: ["AcuantHGLiveness"]),
        .library(name: "AcuantEchipReader", targets: ["AcuantEchipReaderTargets"]),
        .library(name: "AcuantFaceCapture", targets: ["AcuantFaceCapture"]),
        .library(name: "AcuantCamera", targets: ["AcuantCamera"]),
    ],
    targets: [
        /* START_ACUANT */
        .binaryTarget(
            name: "AcuantCommon",
            path: "EmbeddedFrameworks/AcuantCommon.xcframework"
        ),
        .binaryTarget(
            name: "AcuantImagePreparation",
            path: "EmbeddedFrameworks/AcuantImagePreparation.xcframework"
        ),
        .binaryTarget(
            name: "AcuantDocumentProcessing",
            path: "EmbeddedFrameworks/AcuantDocumentProcessing.xcframework"
        ),
        .binaryTarget(
            name: "AcuantFaceMatch",
            path: "EmbeddedFrameworks/AcuantFaceMatch.xcframework"
        ),
        .binaryTarget(
            name: "AcuantPassiveLiveness",
            path: "EmbeddedFrameworks/AcuantPassiveLiveness.xcframework"
        ),
        .binaryTarget(
            name: "AcuantHGLiveness",
            path: "EmbeddedFrameworks/AcuantHGLiveness.xcframework"
        ),
        .binaryTarget(
            name: "AcuantEchipReader",
            path: "EmbeddedFrameworks/AcuantEchipReader.xcframework"
        ),
        .target(
            name: "AcuantEchipReaderTargets",
            dependencies: [
                .target(name: "AcuantEchipReader"),
                .target(name: "OpenSSL")
            ],
            path: "AcuantTargets/AcuantEchipReaderTargets"
        ),
        .target(
            name: "AcuantFaceCapture",
            dependencies: [
                .target(name: "AcuantCommon"),
                .target(name: "AcuantImagePreparation")
            ],
            path: "AcuantFaceCapture/AcuantFaceCapture",
            publicHeadersPath: "AcuantFaceCapture.h"
        ),
        .target(
            name: "AcuantCamera",
            dependencies: [
                .target(name: "AcuantCommon"),
                .target(name: "AcuantImagePreparation"),
                .target(name: "libtesseract")
            ],
            path: "AcuantCamera/AcuantCamera",
            resources: [.process("Media.xcassets")],
            publicHeadersPath: "AcuantCamera.h",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("CoreImage"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit")
            ]
        ),
        /* END_ACUANT */
        /* START_INTERNAL_DEPENDENCIES */
        .binaryTarget(
            name: "OpenSSL",
            path: "EmbeddedFrameworks/OpenSSL.xcframework"
        ),
        .binaryTarget(
            name: "libtesseract",
            path: "EmbeddedFrameworks/libtesseract.xcframework"
        )
        /* END_INTERNAL_DEPENDENCIES */
    ]
)
