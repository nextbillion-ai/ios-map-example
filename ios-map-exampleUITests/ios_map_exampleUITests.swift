//
//  ios_map_exampleUITests.swift
//  ios-map-exampleUITests
//
//  Created by qiu on 2023/6/1.
//

import XCTest

final class ios_map_exampleUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}


/// Uses live production vector tiles and the current project's Metal renderer.
final class HouseNumberDeviceTests: XCTestCase {
    func testDirectionsCompatibilityAfterSDKUpgrade() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 15))
        let entry = table.cells.containing(.staticText, identifier: "Directions View").firstMatch
        for _ in 0..<12 {
            if entry.exists && entry.isHittable { break }
            table.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        XCTAssertTrue(app.staticTexts["Route loaded"].waitForExistence(timeout: 60))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Directions-SDK-2.3.3"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
    }

    func testMapTilerHouseNumbersAcrossStyles() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 15))
        let entry = table.cells.containing(.staticText, identifier: "House Numbers").firstMatch
        for _ in 0..<12 {
            if entry.exists && entry.isHittable { break }
            table.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        XCTAssertEqual(app.staticTexts["housenumber.sdkVersion"].label, "NextBillion Maps 2.3.3")
        app.segmentedControls["housenumber.provider"].buttons["MapTiler"].tap()

        let status = app.staticTexts["housenumber.status"]
        let toggle = app.switches["housenumber.visibility"]
        let styles = app.segmentedControls["housenumber.style"]
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func waitFor(_ pattern: String, style: String) {
            let predicate = NSPredicate(format: "label MATCHES %@ AND value == %@", pattern, "MapTiler " + style)
            let ready = XCTNSPredicateExpectation(predicate: predicate, object: status)
            let result = XCTWaiter.wait(for: [ready], timeout: 90)
            if result != .completed { capture("MapTiler-\(style)-failure") }
            XCTAssertEqual(result, .completed, status.label)
            print("MapTiler \(style): \(status.label)")
        }
        let numbers = "Zoom 19\\.0 · [1-9][0-9]* house numbers"
        waitFor(numbers, style: "Bright")
        capture("MapTiler-Bright-house-numbers")
        toggle.tap()
        waitFor("House numbers hidden", style: "Bright")
        capture("MapTiler-Bright-hidden")

        // A new style must keep the switch off, including the native base labels.
        styles.buttons["Dark"].tap()
        waitFor("House numbers hidden", style: "Dark")
        capture("MapTiler-Dark-hidden")
        toggle.tap()
        waitFor(numbers, style: "Dark")
        capture("MapTiler-Dark-house-numbers")

        // Hybrid uses maptiler_planet and contains no native housenumber layer.
        styles.buttons["Satellite"].tap()
        waitFor(numbers, style: "Satellite")
        capture("MapTiler-Satellite-house-numbers")
        toggle.tap()
        waitFor("House numbers hidden", style: "Satellite")
        capture("MapTiler-Satellite-hidden")
        toggle.tap()
        waitFor(numbers, style: "Satellite")
        for _ in 0..<3 { app.buttons["housenumber.zoomOut"].tap() }
        waitFor("Zoom in to level 17\\+ to see house numbers", style: "Satellite")
        capture("MapTiler-below-minimum-zoom")
        for _ in 0..<3 { app.buttons["housenumber.zoomIn"].tap() }
        waitFor(numbers, style: "Satellite")
        styles.buttons["Bright"].tap()
        waitFor(numbers, style: "Bright")
        capture("MapTiler-Bright-restored")
        app.terminate()
    }

    func testHouseNumbersOnDevice() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 15))
        let entry = table.cells.containing(.staticText, identifier: "House Numbers").firstMatch
        for _ in 0..<12 {
            if entry.exists && entry.isHittable { break }
            table.swipeUp()
        }
        XCTAssertTrue(entry.isHittable, "House Numbers should be available in Runtime Styling")
        entry.tap()
        let version = app.staticTexts["housenumber.sdkVersion"]
        XCTAssertTrue(version.waitForExistence(timeout: 10))
        XCTAssertEqual(version.label, "NextBillion Maps 2.3.3")

        let status = app.staticTexts["housenumber.status"]
        func waitForNumbers() {
            let predicate = NSPredicate(format: "label MATCHES %@", "Zoom 19\\.0 · [1-9][0-9]* house numbers")
            let ready = XCTNSPredicateExpectation(predicate: predicate, object: status)
            let result = XCTWaiter.wait(for: [ready], timeout: 90)
            if result != .completed { capture("House-number-render-failure") }
            XCTAssertEqual(result, .completed, status.label)
            print("House-number rendering: \(status.label)")
        }
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        waitForNumbers()
        capture("TomTom-real-house-numbers")
        let toggle = app.switches["housenumber.visibility"]
        toggle.tap()
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "House numbers hidden")
        capture("House-numbers-hidden")
        toggle.tap()
        waitForNumbers()

        for _ in 0..<3 { app.buttons["housenumber.zoomOut"].tap() }
        expectation(for: NSPredicate(format: "label == %@", "Zoom in to level 17+ to see house numbers"), evaluatedWith: status)
        waitForExpectations(timeout: 15)
        capture("House-numbers-below-minimum-zoom")
        for _ in 0..<3 { app.buttons["housenumber.zoomIn"].tap() }
        waitForNumbers()

        app.segmentedControls["housenumber.provider"].buttons["Orbis"].tap()
        waitForNumbers()
        capture("Orbis-real-house-numbers")
        // Changing styles must reinstall the layer and retain the visibility setting.
        toggle.tap()
        app.segmentedControls["housenumber.provider"].buttons["TomTom"].tap()
        expectation(for: NSPredicate(format: "label == %@", "House numbers hidden"), evaluatedWith: status)
        waitForExpectations(timeout: 90)
        toggle.tap()
        waitForNumbers()
        capture("TomTom-style-reloaded")
        app.terminate()
    }
}

final class MemoryCaptureTests: XCTestCase {
    func testCaptureRetainedPages() throws {
        guard ProcessInfo.processInfo.environment["NB_MEMORY_CAPTURE"] == "1" else {
            throw XCTSkip("Opt-in memory graph capture")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        addUIInterruptionMonitor(withDescription: "Location permission") { alert in
            for label in ["Allow While Using App", "Allow Once", "Don't Allow"] {
                if alert.buttons[label].exists { alert.buttons[label].tap(); return true }
            }
            return false
        }
        for _ in 0..<3 {
            for name in ["Animate Map Style Layer", "Custom Location Source"] {
                let table = app.tables.firstMatch
                for _ in 0..<3 { table.swipeDown() }
                let entry = table.cells.containing(.staticText, identifier: name).firstMatch
                for _ in 0..<10 {
                    if entry.exists && entry.isHittable { break }
                    table.swipeUp()
                }
                XCTAssertTrue(entry.isHittable)
                entry.tap()
                Thread.sleep(forTimeInterval: 3)
                app.navigationBars.buttons.firstMatch.tap()
                XCTAssertTrue(table.waitForExistence(timeout: 10))
            }
        }
        print("MEMORY_CAPTURE_READY")
        Thread.sleep(forTimeInterval: 60)
        app.terminate()
    }
}

final class FullAppRegressionTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        app.terminate()
    }

    private func clearPermissionAlerts() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.exists {
            for label in ["Allow While Using App", "Allow Once", "Don't Allow"] {
                if alert.buttons[label].exists { alert.buttons[label].tap(); return }
            }
        }
    }

    private func find(_ label: String, in table: XCUIElement) -> XCUIElement {
        let entry = table.cells.containing(.staticText, identifier: label).firstMatch
        for _ in 0..<12 {
            if entry.exists && entry.isHittable { return entry }
            table.swipeUp()
        }
        return entry
    }

    private func open(_ label: String) {
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        for _ in 0..<3 { table.swipeDown() }
        let entry = find(label, in: table)
        XCTAssertTrue(entry.isHittable, label)
        entry.tap()
        Thread.sleep(forTimeInterval: 1)
        clearPermissionAlerts()
        XCTAssertEqual(app.state, .runningForeground, label)
    }

    private func screenshot(_ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func apply(_ label: String) {
        app.buttons["Settings"].tap()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        let entry = find(label, in: table)
        XCTAssertTrue(entry.isHittable, label)
        entry.tap()
        clearPermissionAlerts()
        if label == "Query Visible Annotations" {
            XCTAssertTrue(app.alerts["Visible Annotations"].waitForExistence(timeout: 5))
            app.alerts["Visible Annotations"].buttons["Ok"].tap()
        }
        XCTAssertEqual(app.state, .runningForeground, label)
        print("Executed setting: \(label)")
    }

    func testMarkerTapProducesVisibleAnnotation() {
        open("Custom Marker View")
        Thread.sleep(forTimeInterval: 3)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
        Thread.sleep(forTimeInterval: 2)
        screenshot("Marker-after-loaded-tap")
        let marker = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "title")).firstMatch
        XCTAssertTrue(marker.waitForExistence(timeout: 5), "Tapping the loaded map should add a visible annotation")
    }

    func testEveryGalleryPageAndSetting() {
        let cases: [(String, [String])] = [
            ("Map Configration", []),
            ("Map Camera", ["Camera Set Center Coordinate", "Set center coordinate with zoom level", "Set center coordinate with zoom level and direction", "Set center coordinate with zoom level and direction completion handler", "Set zoom level", "Set direction", "Set visible coordinate bounds", "Set visible coordinate bounds with edge padding", "Set visible coordinates with edge padding", "Set visible coordinates with edge padding and direction and direction", "Set camera", "Set camera with duration", "Set camera with duration and completion handler", "Fly to camera", "Fly to camera with duration", "Fly to camera with duration and peak altitude"]),
            ("Custom Polyline View", []), ("Custom Polygon View", []), ("Custom Marker View", []),
            ("Custom Annotations View", ["Add 100 Annotations", "Add 1000 Annotations", "Animate Annotations", "Query Visible Annotations", "Center Selected Annotations", "Add Visible Area Polyline"]),
            ("Map view delegate", []),
            ("Custom Map Style Layer", ["Style Building Extrusions", "Add Building Extrusions", "Style Water with function", "Style Roads with function"]),
            ("Animate Map Style Layer", []),
            ("Add Map Style Layer", ["Add Query Features Layer", "Add Multi Shape Layers", "Add Query Features Layer", "Add Multi Shape Layers"]),
            ("Directions View", []),
            ("Update Location View Style", ["Get user location", "Update puck view to follow", "Update puck view to follow with course", "Update puck view to follow with heading", "Hide puck view"]),
            ("Custom Puck view", []), ("Custom Location Source", []), ("House Numbers", [])
        ]
        for (name, actions) in cases {
            open(name)
            if name == "Custom Polyline View" {
                for x in [0.25, 0.5, 0.75] {
                    app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.6)).press(forDuration: 0.8)
                }
            }
            if name == "Custom Marker View" {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
            }
            for action in actions { apply(action) }
            if name == "Directions View" {
                XCTAssertTrue(app.staticTexts["Route loaded"].waitForExistence(timeout: 60))
            }
            if name == "House Numbers" {
                XCTAssertEqual(app.staticTexts["housenumber.sdkVersion"].label, "NextBillion Maps 2.3.3")
            }
            screenshot("Gallery-" + name)
            clearPermissionAlerts()
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10), name)
            print("Gallery page passed: \(name)")
        }
    }

    func testNineProviderStylePairsAndRapidReload() {
        open("House Numbers")
        let provider = app.segmentedControls["housenumber.provider"]
        let styles = app.segmentedControls["housenumber.style"]
        let status = app.staticTexts["housenumber.status"]
        for name in ["TomTom", "Orbis", "MapTiler"] {
            provider.buttons[name].tap()
            for style in ["Bright", "Dark", "Satellite"] {
                styles.buttons[style].tap()
                let predicate = NSPredicate(format: "label MATCHES %@ AND value == %@", "Zoom 19\\.0 · [1-9][0-9]* house numbers", name + " " + style)
                let ready = XCTNSPredicateExpectation(predicate: predicate, object: status)
                let result = XCTWaiter.wait(for: [ready], timeout: 90)
                if result != .completed { screenshot("Matrix-failure-" + name + "-" + style) }
                XCTAssertEqual(result, .completed, status.label)
                print("Matrix \(name) \(style): \(status.label)")
                screenshot("Matrix-" + name + "-" + style)
            }
        }
        for _ in 0..<2 {
            for name in ["TomTom", "Orbis", "MapTiler"] { provider.buttons[name].tap() }
        }
        styles.buttons["Bright"].tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label MATCHES %@ AND value == %@", "Zoom 19\\.0 · [1-9][0-9]* house numbers", "MapTiler Bright"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 90), .completed)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeReady = XCTNSPredicateExpectation(predicate: NSPredicate { [unowned self] _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscapeReady], timeout: 15), .completed)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(provider.isHittable)
        XCTAssertTrue(styles.isHittable)
        XCTAssertTrue(app.switches["housenumber.visibility"].isHittable)
        let landscapeShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscapeShot.name = "House-numbers-landscape-stable"
        landscapeShot.lifetime = .keepAlways
        add(landscapeShot)
        XCUIDevice.shared.orientation = .portrait
        let portraitReady = XCTNSPredicateExpectation(predicate: NSPredicate { [unowned self] _, _ in
            self.app.frame.height > self.app.frame.width
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portraitReady], timeout: 15), .completed)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        screenshot("House-numbers-background-resume")
    }

    func testRepeatedAnimationAndLocationNavigation() {
        for cycle in 0..<3 {
            for name in ["Animate Map Style Layer", "Custom Location Source"] {
                open(name)
                Thread.sleep(forTimeInterval: 1)
                app.navigationBars.buttons.firstMatch.tap()
                XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10))
                print("Repeated navigation \(cycle): \(name)")
            }
        }
    }
}
