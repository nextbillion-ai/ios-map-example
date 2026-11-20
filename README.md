# NextBillion Maps iOS Examples

The example uses the published [NextBillion Maps SDK 2.3.3](https://github.com/nextbillion-ai/nextbillion-map-ios/releases/tag/2.3.3), pinned in both `Cartfile` and `Cartfile.resolved`.

## Run the example

1. Run `carthage bootstrap --use-xcframeworks --platform iOS` from this directory.
2. Open `ios-map-example.xcodeproj`, choose the `ios-map-example` scheme, and select your development team in Signing & Capabilities.
3. Replace the `Your-Access-key` placeholder in `ios-map-example/Info.plist` (`NBMapAccessKey`) with your own API key, then run on an iPhone.

## House numbers

Open **Runtime Styling → House Numbers**. The example uses real address points on the same Amsterdam residential street as the Android demo (52.35273, 4.91638). It includes TomTom/Orbis/MapTiler selection, Bright/Dark/Satellite styles, a visibility switch, zoom controls, and a count of currently rendered address points.

See [HouseNumberViewController.swift](ios-map-example/HouseNumberViewController.swift). Install the symbol layer after each style load:

```swift
func mapView(_: NGLMapView, didFinishLoading style: NGLStyle) {
    HouseNumberStyle.install(in: style, provider: .tomTom)
}
```

| Provider | Vector source | Source layer | Filter | Text attribute |
| --- | --- | --- | --- | --- |
| TomTom | `vectorTiles` | `places` | `category == address_point` | `number` |
| Orbis | `vectorTiles` | `address_points` | `category == house` | `number` |
| MapTiler (Bright/Dark) | `openmaptiles` | `housenumber` | Nonempty house number | `housenumber` |
| MapTiler (Satellite/hybrid) | `maptiler_planet` | `housenumber` | Nonempty house number | `housenumber` |

The layer has a minimum zoom of 17; start at zoom 19 to inspect the sample. Label availability also depends on the provider's tile coverage and zoom. Native `House Number` (Orbis) and `housenumber` (MapTiler) layers are reused to avoid duplicate labels. MapTiler's initially hidden labels are enabled explicitly, with its `Roboto Medium` / `Noto Sans Regular` font stack. The Satellite/hybrid style gets a new symbol layer on `maptiler_planet`. Every style load reapplies the selected visibility state.

## Physical-device test

With a connected, unlocked iPhone and local signing configured:

```sh
xcodebuild test -project ios-map-example.xcodeproj -scheme ios-map-example \
  -destination 'platform=iOS,id=<device-UDID>' \
  -only-testing:ios-map-exampleUITests/HouseNumberDeviceTests/testHouseNumbersOnDevice \
  -only-testing:ios-map-exampleUITests/HouseNumberDeviceTests/testMapTilerHouseNumbersAcrossStyles \
  -parallel-testing-enabled NO -resultBundlePath /tmp/house-numbers.xcresult
```

The test verifies the loaded SDK is 2.3.3, renders live house numbers for TomTom, Orbis, and all three MapTiler styles, and checks visibility, zoom, and style reload. Screenshots are attached to the test result. An internet connection is required.

## Upgrading from SDK 1.x

The old Directions sample used `NBAPIClient`, `NBRoute`, and `GeometryDecoder`, which are absent from the 2.3.3 framework. [Directions.swift](ios-map-example/Directions.swift) now uses `URLSession` and the [Directions API](https://docs.nextbillion.ai/routing/directions-api) with `geometry=polyline`, then draws the decoded route using `NGLShapeSource` and `NGLLineStyleLayer`. The shared scheme also includes a physical-device route rendering check and reference-geometry decoder tests.

## Full-app regression

The shared scheme includes lifecycle and malformed-data checks in `ios-map-exampleTests`, plus `FullAppRegressionTests` for all 15 gallery pages and their settings, all nine provider/style combinations, rapid style reloads, rotation, background/foreground, and repeated animation/location navigation.

```sh
xcodebuild test -project ios-map-example.xcodeproj -scheme ios-map-example \
  -destination 'platform=iOS,id=<device-UDID>' \
  -only-testing:ios-map-exampleTests \
  -only-testing:ios-map-exampleUITests/FullAppRegressionTests \
  -only-testing:ios-map-exampleUITests/HouseNumberDeviceTests \
  -parallel-testing-enabled NO -resultBundlePath /tmp/full-app.xcresult
```

`GallerySafetyTests.testThousandAnnotationRenderingAndAccessibilityTiming` prints separate native-add, visible-query, and accessibility-enumeration timings. On an iPhone 12 mini with SDK 2.3.3 and iOS 26.6.1, adding/querying 1,000 points took about 8/31 ms, while enumerating 1,002 accessibility elements took about 9.8 seconds. Large annotation accessibility traversal remains a performance issue; functional assertions do not certify that path as responsive. No comparison with SDK 1.x was performed for this timing.

`MemoryCaptureTests` is skipped unless `NB_MEMORY_CAPTURE=1` is set in the test-runner environment. It returns home after three visits each to the animation and custom-location pages, then prints `MEMORY_CAPTURE_READY` and waits 60 seconds for a simulator memory-graph capture. Local results and new untracked test files are ignored by `.gitignore`; already tracked test sources remain tracked.
