//
//  ios_map_exampleTests.swift
//  ios-map-exampleTests
//
//  Created by qiu on 2023/6/1.
//

import XCTest
import Nbmap
import UIKit
@testable import ios_map_example

final class ios_map_exampleTests: XCTestCase {
    func testPolylineReferenceGeometry() throws {
        // Published encoded-polyline reference, independent of the sample API.
        let points = try XCTUnwrap(DirectionsViewController.decodePolyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@"))
        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[0].latitude, 38.5, accuracy: 0.00001)
        XCTAssertEqual(points[0].longitude, -120.2, accuracy: 0.00001)
        XCTAssertEqual(points[1].latitude, 40.7, accuracy: 0.00001)
        XCTAssertEqual(points[1].longitude, -120.95, accuracy: 0.00001)
        XCTAssertEqual(points[2].latitude, 43.252, accuracy: 0.00001)
        XCTAssertEqual(points[2].longitude, -126.453, accuracy: 0.00001)
    }

    func testPolylineRejectsMalformedGeometry() {
        for input in ["_", "?", String(repeating: "~", count: 12), "\u{0000}"] {
            XCTAssertNil(DirectionsViewController.decodePolyline(input))
        }
    }


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

@MainActor
final class AppLifecycleRegressionTests: XCTestCase {
    func testCustomLocationDelegateDoesNotRetainMap() {
        let manager = CustomMapLocationManager()
        weak var releasedMap: NGLMapView?
        autoreleasepool {
            let map = NGLMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
            map.locationManager = manager
            releasedMap = map
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertNil(releasedMap, "Map → custom location manager → strong delegate retains the map")
        manager.delegate = nil
    }

    func testAnimatedControllerReleasesAfterLeaving() {
        weak var releasedController: AnimateMapLayerViewController?
        autoreleasepool {
            let controller = AnimateMapLayerViewController()
            controller.loadViewIfNeeded()
            controller.addImageSourceLayer()
            releasedController = controller
        }
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        XCTAssertNil(releasedController, "RunLoop → repeating Timer → controller keeps the animation page alive")
    }
}

@MainActor
final class GallerySafetyTests: XCTestCase {
    private func map(in view: UIView) -> NGLMapView? {
        if let map = view as? NGLMapView { return map }
        return view.subviews.compactMap { map(in: $0) }.first
    }

    func testAllGalleryControllersReleaseTheirMaps() {
        let gallery = HomeViewController().examples
        for name in gallery.keys.sorted().flatMap({ gallery[$0] ?? [] }) {
            weak var releasedController: UIViewController?
            weak var releasedMap: NGLMapView?
            autoreleasepool {
                let controller = name.viewController.init()
                controller.loadViewIfNeeded()
                let mapView = map(in: controller.view)
                XCTAssertNotNil(mapView, name.name)
                mapView?.showsUserLocation = false
                releasedController = controller
                releasedMap = mapView
            }
            let gone = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                releasedController == nil && releasedMap == nil
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed, name.name)
            print("Released gallery page and map: \(name.name)")
        }
    }

    private func waitForFixture(_ map: NGLMapView) {
        let json = "{\"version\":8,\"sources\":{},\"layers\":[{\"id\":\"fixture-background\",\"type\":\"background\",\"paint\":{\"background-color\":\"#e0e0e0\"}}]}"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("regression-style.json")
        do { try Data(json.utf8).write(to: url) }
        catch { XCTFail("Could not write fixture: \(error)"); return }
        map.styleURL = url
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            map.style?.layer(withIdentifier: "fixture-background") != nil
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
    }

    func testAnimationReinstallationAndLeavingInvalidateTimer() throws {
        let controller = AnimateMapLayerViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.loadViewIfNeeded()
        waitForFixture(controller.nbMapView)
        controller.addImageSourceLayer()
        let firstTimer = try XCTUnwrap(controller.animationTimer)
        controller.addImageSourceLayer()
        XCTAssertFalse(firstTimer.isValid)
        XCTAssertTrue(try XCTUnwrap(controller.animationTimer).isValid)
        controller.viewWillDisappear(false)
        XCTAssertNil(controller.animationTimer)
    }

    func testRepeatedQueryAndMultiShapeActions() {
        let controller = AddMapStyleLayerViewController()
        controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        controller.loadViewIfNeeded()
        waitForFixture(controller.nbMapView)
        for _ in 0..<5 {
            controller.addQueryFeaturesLayer()
            controller.addMultiShapeLayers()
        }
        XCTAssertNotNil(controller.nbMapView.style?.layer(withIdentifier: "query-layer-id"))
        XCTAssertNotNil(controller.nbMapView.style?.layer(withIdentifier: "leaf-circle-layer"))
    }

    func testThousandAnnotationRenderingAndAccessibilityTiming() throws {
        let controller = AnnotationsViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = UIScreen.main.bounds
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.loadViewIfNeeded()
        let map = try XCTUnwrap(controller.nbMapView)
        waitForFixture(map)
        let url = try XCTUnwrap(Bundle.main.url(forResource: "points", withExtension: "geojson"))
        let annotations = AnnotationsViewController.parseAnnotations(data: try Data(contentsOf: url), limit: 1000)
        XCTAssertEqual(annotations.count, 1000)
        var start = ProcessInfo.processInfo.systemUptime
        map.addAnnotations(annotations)
        let addSeconds = ProcessInfo.processInfo.systemUptime - start
        map.showAnnotations(annotations, animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        start = ProcessInfo.processInfo.systemUptime
        let visibleCount = map.visibleAnnotations?.count ?? 0
        let querySeconds = ProcessInfo.processInfo.systemUptime - start
        XCTAssertGreaterThan(visibleCount, 0)
        let count = map.accessibilityElementCount()
        start = ProcessInfo.processInfo.systemUptime
        for index in 0..<max(0, count) { _ = map.accessibilityElement(at: index) }
        let accessibilitySeconds = ProcessInfo.processInfo.systemUptime - start
        print("ANNOTATION_PRESSURE_TIMING add=\(addSeconds)s query=\(querySeconds)s accessibility=\(accessibilitySeconds)s elements=\(count) visible=\(visibleCount)")
        XCTAssertLessThan(addSeconds, 2, "Adding 1000 annotations blocked the main thread")
        XCTAssertLessThan(querySeconds, 2, "Native visible-annotation query blocked the main thread")
    }

    func testMalformedAnnotationDataAndCountLimit() throws {
        let malformed = "{\"features\":[{\"geometry\":{\"type\":\"Point\",\"coordinates\":[]}},{\"geometry\":{\"type\":\"Point\",\"coordinates\":[4.9,52.3]}},{\"geometry\":{\"type\":\"Point\",\"coordinates\":[4.91,52.31]}}]}"
        let points = AnnotationsViewController.parseAnnotations(data: Data(malformed.utf8), limit: 1)
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(try XCTUnwrap(points.first).coordinate.latitude, 52.3, accuracy: 0.00001)
        XCTAssertTrue(AnnotationsViewController.parseAnnotations(data: Data("invalid".utf8), limit: 10).isEmpty)
        XCTAssertTrue(AnnotationsViewController.parseAnnotations(data: Data(malformed.utf8), limit: 0).isEmpty)
    }

    func testPolylineKeepsOneGeometryInsteadOfAllPrefixes() {
        let controller = PolylineViewController()
        controller.loadViewIfNeeded()
        for i in 0..<100 {
            controller.points.append(CLLocationCoordinate2D(latitude: 12.94 + Double(i) * 0.00001, longitude: 77.57))
            controller.drawPolyline()
        }
        XCTAssertEqual(controller.nbMapView.annotations?.filter { $0 is NGLPolyline }.count, 1)
    }

    func testNoLocationFixAndInvalidPuckSizeAreSafe() {
        let controller = LocationStyleViewController()
        controller.loadViewIfNeeded()
        controller.performeSettings(tyle: .GetUserLocation)
        controller.nbMapView.showsUserLocation = false
        for index in controller.typeList.indices { _ = controller.settingsTitlesForRaw(index: index) }
        XCTAssertFalse(controller.nbMapView.showsUserLocation, "Reading menu titles must not enable location")
        controller.performeSettings(tyle: .UpdateToFollow)
        XCTAssertTrue(controller.nbMapView.showsUserLocation)
        controller.performeSettings(tyle: .HidePuckView)
        XCTAssertFalse(controller.nbMapView.showsUserLocation)
        for index in controller.typeList.indices { _ = controller.settingsTitlesForRaw(index: index) }
        XCTAssertFalse(controller.nbMapView.showsUserLocation)
        let puck = CustomUserLocationAnnotationView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        puck.updateFrame(with: CGSize(width: CGFloat.infinity, height: CGFloat.nan))
        XCTAssertEqual(puck.frame.size, CGSize(width: 30, height: 30))
        XCTAssertEqual(puck.accuracyInPoints(), 0)
    }
}
