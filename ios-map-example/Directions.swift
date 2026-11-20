import Foundation
import UIKit
import Nbmap

/// Fetches a route from the Directions HTTP API and renders it with Maps SDK 2.3.3.
class DirectionsViewController: UIViewController, NGLMapViewDelegate {
    private var nbMapView: NGLMapView!
    private var request: URLSessionDataTask?

    // A network request may outlive this screen; cancel unnecessary work on exit.
    deinit { request?.cancel() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Directions"
        view.backgroundColor = .systemBackground
        nbMapView = NGLMapView(frame: .zero)
        nbMapView.translatesAutoresizingMaskIntoConstraints = false
        nbMapView.delegate = self
        view.addSubview(nbMapView)
        NSLayoutConstraint.activate([
            nbMapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nbMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nbMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nbMapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle) {
        let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 12.977, longitude: 77.593),
                                  acrossDistance: 14000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: false)
        drawDirections(in: style)
    }

    private func drawDirections(in style: NGLStyle) {
        // SDK 2.3.3 is the map renderer. Call the Directions API directly instead
        // of relying on NBAPIClient/GeometryDecoder from the old 1.x SDK.
        var url = URLComponents(string: "https://api.nextbillion.io/directions/json")!
        // Directions uses latitude,longitude for its endpoint parameters.
        // Keep geometry=polyline paired with the five-decimal decoder below.
        url.queryItems = [
            URLQueryItem(name: "key", value: NGLAccountManager.accessToken),
            URLQueryItem(name: "origin", value: "12.96206481,77.56687669"),
            URLQueryItem(name: "destination", value: "12.99150562,77.61940507"),
            URLQueryItem(name: "mode", value: "car"),
            URLQueryItem(name: "geometry", value: "polyline"),
            URLQueryItem(name: "overview", value: "full"),
        ]
        navigationItem.prompt = "Loading route…"
        // A new style starts a fresh request. Weak capture lets the screen and map
        // be released even while a previous HTTP response is still pending.
        request?.cancel()
        request = URLSession.shared.dataTask(with: url.url!) { [weak self] data, response, error in
            guard (error as? URLError)?.code != .cancelled else { return }
            let body = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            let routes = body?["routes"] as? [[String: Any]]
            let encoded = routes?.first?["geometry"] as? String
            let coordinates = encoded.flatMap(Self.decodePolyline)
            // UIKit and style mutations belong on the main thread. Ignore a late
            // response if the screen has gone away or the map now has another style.
            DispatchQueue.main.async {
                guard let self, self.nbMapView.style === style else { return }
                guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200,
                      body?["status"] as? String == "Ok", var coordinates, coordinates.count >= 2 else {
                    self.navigationItem.prompt = "Route unavailable. Check the API key and connection."
                    return
                }
                let route = NGLPolylineFeature(coordinates: &coordinates, count: UInt(coordinates.count))
                let source = NGLShapeSource(identifier: "route-style-source", shape: route, options: nil)
                let layer = NGLLineStyleLayer(identifier: "route-layer", source: source)
                layer.lineColor = NSExpression(forConstantValue: UIColor.systemRed)
                layer.lineWidth = NSExpression(forConstantValue: 3)
                // Register the data source before the layer that references it.
                style.addSource(source)
                style.addLayer(layer)
            }
        }
        request?.resume()
    }

    // Confirm rendered route features, rather than only a successful HTTP response.
    func mapViewDidBecomeIdle(_ mapView: NGLMapView) {
        guard mapView.style?.layer(withIdentifier: "route-layer") != nil else { return }
        let features = mapView.visibleFeatures(in: mapView.bounds, styleLayerIdentifiers: ["route-layer"])
        if !features.isEmpty { navigationItem.prompt = "Route loaded" }
    }

    /// The API's geometry=polyline response uses five decimal places.
    /// Reject incomplete or overflowing input rather than drawing a partial route.
    static func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D]? {
        let bytes = Array(encoded.utf8)
        var index = 0
        var latitude = 0
        var longitude = 0
        var coordinates: [CLLocationCoordinate2D] = []
        // Decode one signed delta from ASCII-offset, five-bit groups. Bound the
        // shift so malformed or truncated input cannot produce an invalid route.
        func delta() -> Int? {
            var result = 0
            var shift = 0
            while index < bytes.count, shift <= 30 {
                let byte = bytes[index]
                index += 1
                guard byte >= 63, byte <= 126 else { return nil }
                let value = Int(byte) - 63
                result |= (value & 0x1f) << shift
                if value < 0x20 { return result & 1 == 0 ? result >> 1 : ~(result >> 1) }
                shift += 5
            }
            return nil
        }
        while index < bytes.count {
            guard let lat = delta(), let lon = delta() else { return nil }
            // Polyline coordinates are delta-encoded latitude/longitude pairs.
            // Accumulate them before converting the fixed-point values to degrees.
            latitude += lat
            longitude += lon
            let point = CLLocationCoordinate2D(latitude: Double(latitude) / 100000,
                                               longitude: Double(longitude) / 100000)
            guard CLLocationCoordinate2DIsValid(point) else { return nil }
            coordinates.append(point)
        }
        return coordinates
    }
}
