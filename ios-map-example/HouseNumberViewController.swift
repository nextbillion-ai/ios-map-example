import Nbmap
import UIKit

/// Maps the sample UI choices to each provider's style endpoint names.
enum HouseNumberBasemapStyle: String, CaseIterable {
    case bright = "Bright"
    case dark = "Dark"
    case satellite = "Satellite"

    var tomTomName: String {
        switch self {
        case .bright: return "basic_street-light"
        case .dark: return "basic_street-dark"
        case .satellite: return "basic_street-satellite"
        }
    }

    var mapTilerName: String {
        switch self {
        case .bright: return "streets"
        case .dark: return "dark"
        case .satellite: return "hybrid"
        }
    }
}

/// Describes the vector-tile schema expected by each supported basemap.
/// When using your own style JSON, check its source IDs, source-layer names,
/// feature attributes, and glyph fonts before reusing these mappings.
enum HouseNumberProvider: String, CaseIterable {
    case tomTom = "TomTom"
    case orbis = "Orbis"
    case mapTiler = "MapTiler"

    // These are IDs in the style JSON's top-level "sources" object.
    // MapTiler streets/dark and hybrid use different IDs for their vector data.
    var sourceIdentifiers: [String] {
        self == .mapTiler ? ["openmaptiles", "maptiler_planet"] : ["vectorTiles"]
    }

    // A source layer is a collection inside a vector tile, not a style layer ID.
    var sourceLayer: String {
        switch self {
        case .tomTom: return "places"
        case .orbis: return "address_points"
        case .mapTiler: return "housenumber"
        }
    }

    // Read the label from a feature attribute; provider schemas are not interchangeable.
    var textField: String { self == .mapTiler ? "housenumber" : "number" }
    // These names must exist in the basemap's glyph service, not just in UIFont.
    var fontNames: [String] {
        self == .mapTiler ? ["Roboto Medium", "Noto Sans Regular"] : ["Noto-Regular"]
    }
    var category: String? {
        switch self {
        case .tomTom: return "address_point"
        case .orbis: return "house"
        case .mapTiler: return nil
        }
    }
    var nativeLayerIdentifier: String? {
        switch self {
        case .tomTom: return nil
        case .orbis: return "House Number"
        case .mapTiler: return "housenumber"
        }
    }

    /// Builds a URL for this map instance without changing the SDK's global provider.
    func styleURL(style: HouseNumberBasemapStyle, accessToken: String) -> URL {
        var components: URLComponents
        switch self {
        case .tomTom:
            components = URLComponents(string: "https://api.nextbillion.io/tt/style/1/style/22.2.1-9")!
            components.queryItems = [URLQueryItem(name: "map", value: "2/" + style.tomTomName)]
        case .orbis:
            components = URLComponents(string: "https://api.nextbillion.io/orbis/style/2.0.0-2/style.json")!
            components.queryItems = [URLQueryItem(name: "apiVersion", value: "1"),
                                     URLQueryItem(name: "map", value: style.tomTomName)]
        case .mapTiler:
            components = URLComponents(string: "https://api.nextbillion.io/maps/\(style.mapTilerName)/style.json")!
            components.queryItems = []
        }
        // Use the SDK's configured header authentication when available; otherwise
        // URLQueryItem safely encodes the API key as a query parameter.
        if NGLAccountManager.apiKeyHeaderName?.isEmpty != false {
            components.queryItems?.append(URLQueryItem(name: "key", value: accessToken))
        }
        return components.url!
    }
}

// #-example-code(HouseNumbers)
enum HouseNumberStyle {
    static let layerIdentifier = "example-house-numbers"
    // This sample displays detailed address labels at street/building zoom levels.
    // Actual address coverage still depends on the provider's tiles for the area.
    static let minimumZoom: Float = 17

    /// Adds or updates house-number labels using the loaded basemap's vector data.
    ///
    /// Call on the main thread from `mapView(_:didFinishLoading:)` after every
    /// style load. A style change replaces runtime layers, so installation and
    /// the desired visibility must be reapplied to the new style.
    ///
    /// - Parameters:
    ///   - style: The loaded style belonging to your map view.
    ///   - provider: The schema matching the basemap URL used by that map.
    ///   - visible: The current user preference, including after a style reload.
    /// - Returns: The installed symbol layer, or nil if the expected vector source
    ///   is absent or an existing layer with the chosen ID is not a symbol layer.
    @discardableResult
    static func install(in style: NGLStyle, provider: HouseNumberProvider,
                        visible: Bool = true) -> NGLSymbolStyleLayer? {
        // MapTiler hybrid uses maptiler_planet; streets/dark use openmaptiles.
        let sources = provider.sourceIdentifiers.compactMap {
            style.source(withIdentifier: $0) as? NGLVectorTileSource
        }
        guard let source = sources.first else { return nil }

        // Reuse native labels, including MapTiler's initially hidden housenumber
        // layer. Hybrid has no native house-number layer, so create one there.
        let existing = style.layer(withIdentifier: layerIdentifier)
            ?? provider.nativeLayerIdentifier.flatMap { style.layer(withIdentifier: $0) }
        let layer: NGLSymbolStyleLayer
        if let existing {
            guard let symbol = existing as? NGLSymbolStyleLayer else { return nil }
            layer = symbol
        } else {
            layer = NGLSymbolStyleLayer(identifier: layerIdentifier, source: source)
        }
        // The source selects a tile set; sourceLayerIdentifier selects its address
        // collection. The predicate below then selects valid address features.
        layer.sourceLayerIdentifier = provider.sourceLayer
        var filters = [NSPredicate(format: "%K != nil AND %K != %@",
                                   provider.textField, provider.textField, "")]
        // TomTom/Orbis collections contain categorized features. MapTiler already
        // provides a dedicated housenumber collection and needs no category filter.
        if let category = provider.category {
            filters.append(NSPredicate(format: "category == %@", category))
        }
        layer.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filters)
        // A key-path expression reads each feature's number; a constant expression
        // here would display the attribute name itself on every label.
        layer.text = NSExpression(forKeyPath: provider.textField)
        layer.textFontNames = NSExpression(forConstantValue: provider.fontNames)
        layer.textFontSize = NSExpression(forNGLInterpolating: .zoomLevelVariable,
                                         curveType: .linear, parameters: nil,
                                         stops: NSExpression(forConstantValue: [17: 11, 20: 15]))
        layer.textColor = NSExpression(forConstantValue: UIColor(white: 0.2, alpha: 1))
        layer.textHaloColor = NSExpression(forConstantValue: UIColor.white)
        layer.textHaloWidth = NSExpression(forConstantValue: 1)
        // Keep collision detection enabled so dense address labels remain readable.
        layer.textAllowsOverlap = NSExpression(forConstantValue: false)
        layer.textIgnoresPlacement = NSExpression(forConstantValue: false)
        layer.textPadding = NSExpression(forConstantValue: 2)
        layer.minimumZoomLevel = minimumZoom
        layer.isVisible = visible
        if existing == nil { style.addLayer(layer) }
        return layer
    }
}
// #-end-example-code

/// Sample UI for provider/style selection. Existing apps can call
/// `HouseNumberStyle.install(in:provider:visible:)` from their own map delegate.
final class HouseNumberViewController: UIViewController, NGLMapViewDelegate {
    private let providerControl = UISegmentedControl(items: HouseNumberProvider.allCases.map(\.rawValue))
    private let styleControl = UISegmentedControl(items: HouseNumberBasemapStyle.allCases.map(\.rawValue))
    private let visibilitySwitch = UISwitch()
    private let statusLabel = UILabel()
    private var mapView: NGLMapView!
    private var houseNumberLayer: NGLSymbolStyleLayer?
    private var provider: HouseNumberProvider {
        HouseNumberProvider.allCases[providerControl.selectedSegmentIndex]
    }

    private var basemapStyle: HouseNumberBasemapStyle {
        HouseNumberBasemapStyle.allCases[styleControl.selectedSegmentIndex]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "House Numbers"
        view.backgroundColor = .systemBackground
        providerControl.selectedSegmentIndex = 0
        providerControl.accessibilityIdentifier = "housenumber.provider"
        providerControl.addTarget(self, action: #selector(changeProvider), for: .valueChanged)
        styleControl.selectedSegmentIndex = 0
        styleControl.accessibilityIdentifier = "housenumber.style"
        styleControl.addTarget(self, action: #selector(changeStyle), for: .valueChanged)
        visibilitySwitch.isOn = true
        visibilitySwitch.accessibilityIdentifier = "housenumber.visibility"
        visibilitySwitch.accessibilityLabel = "Show house numbers"
        visibilitySwitch.addTarget(self, action: #selector(changeVisibility), for: .valueChanged)

        let label = UILabel()
        label.text = "Show house numbers"
        let visibilityRow = UIStackView(arrangedSubviews: [label, visibilitySwitch])
        visibilityRow.alignment = .center
        visibilityRow.distribution = .equalSpacing
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "housenumber.status"
        statusLabel.text = "Loading map…"

        let zoomOut = UIButton(type: .system)
        zoomOut.setTitle("−", for: .normal)
        zoomOut.accessibilityLabel = "Zoom out"
        zoomOut.accessibilityIdentifier = "housenumber.zoomOut"
        zoomOut.addTarget(self, action: #selector(decreaseZoom), for: .touchUpInside)
        let zoomIn = UIButton(type: .system)
        zoomIn.setTitle("+", for: .normal)
        zoomIn.accessibilityLabel = "Zoom in"
        zoomIn.accessibilityIdentifier = "housenumber.zoomIn"
        zoomIn.addTarget(self, action: #selector(increaseZoom), for: .touchUpInside)
        let zoomRow = UIStackView(arrangedSubviews: [statusLabel, zoomOut, zoomIn])
        zoomRow.spacing = 12
        zoomRow.alignment = .center
        zoomOut.widthAnchor.constraint(equalToConstant: 44).isActive = true
        zoomIn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        zoomRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        let sdkVersionLabel = UILabel()
        let sdkVersion = Bundle(for: NGLMapView.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        sdkVersionLabel.text = "NextBillion Maps \(sdkVersion)"
        sdkVersionLabel.font = .preferredFont(forTextStyle: .caption1)
        sdkVersionLabel.textColor = .secondaryLabel
        sdkVersionLabel.accessibilityIdentifier = "housenumber.sdkVersion"
        let controls = UIStackView(arrangedSubviews: [sdkVersionLabel, providerControl, styleControl, visibilityRow, zoomRow])
        controls.axis = .vertical
        controls.spacing = 8
        controls.isLayoutMarginsRelativeArrangement = true
        controls.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16)

        // Configure NBMapAccessKey in Info.plist, or NGLAccountManager.accessToken,
        // before creating the map. The controls select a style URL for this instance.
        mapView = NGLMapView(frame: .zero, styleURL: provider.styleURL(style: basemapStyle, accessToken: NGLAccountManager.accessToken ?? ""))
        mapView.delegate = self
        // Match the Android demo's Amsterdam residential street for comparison.
        mapView.setCenter(CLLocationCoordinate2D(latitude: 52.35273, longitude: 4.91638),
                          zoomLevel: 19, animated: false)
        let stack = UIStackView(arrangedSubviews: [controls, mapView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    @objc private func changeProvider() { reloadStyle() }
    @objc private func changeStyle() { reloadStyle() }

    private func reloadStyle() {
        // The old layer belongs to the previous style. Resolve a new layer only
        // after the replacement style finishes loading.
        houseNumberLayer = nil
        statusLabel.text = "Loading map…"
        mapView.styleURL = provider.styleURL(style: basemapStyle, accessToken: NGLAccountManager.accessToken ?? "")
    }

    @objc private func changeVisibility() {
        houseNumberLayer?.isVisible = visibilitySwitch.isOn
        updateStatus()
    }

    @objc private func decreaseZoom() { mapView.setZoomLevel(mapView.zoomLevel - 1, animated: false) }
    @objc private func increaseZoom() { mapView.setZoomLevel(mapView.zoomLevel + 1, animated: false) }

    // Integration entry point: the basemap's sources and native layers are ready.
    func mapView(_: NGLMapView, didFinishLoading style: NGLStyle) {
        houseNumberLayer = HouseNumberStyle.install(in: style, provider: provider, visible: visibilitySwitch.isOn)
        if houseNumberLayer == nil { statusLabel.text = "This style has no address source." }
    }

    // Refresh after rendering settles instead of querying on every camera change.
    func mapViewDidBecomeIdle(_: NGLMapView) { updateStatus() }

    func mapViewDidFailLoadingMap(_: NGLMapView, withError _: Error) {
        statusLabel.text = "Map failed to load. Check your API key and connection."
    }

    private func updateStatus() {
        guard let layer = houseNumberLayer else { return }
        statusLabel.accessibilityValue = "\(provider.rawValue) \(basemapStyle.rawValue)"
        if !visibilitySwitch.isOn {
            statusLabel.text = "House numbers hidden"
        } else if mapView.zoomLevel < Double(HouseNumberStyle.minimumZoom) {
            statusLabel.text = "Zoom in to level 17+ to see house numbers"
        } else {
            // Count features in this layer within the current viewport. This is a
            // rendering diagnostic, not the total number of addresses in the tiles.
            let features = mapView.visibleFeatures(in: mapView.bounds, styleLayerIdentifiers: [layer.identifier])
            statusLabel.text = String(format: "Zoom %.1f · %d house numbers", mapView.zoomLevel, features.count)
        }
    }
}
