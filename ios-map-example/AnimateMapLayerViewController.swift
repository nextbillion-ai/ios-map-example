import Foundation
import UIKit
import Nbmap

/// Animates a raster image source installed after the basemap style loads.
class AnimateMapLayerViewController: UIViewController, NGLMapViewDelegate {
    var nbMapView: NGLMapView!
    private(set) var animationTimer: Timer?
    private var imageSource: NGLImageSource?
    private var radarSuffix = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        nbMapView = NGLMapView(frame: view.bounds)
        nbMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nbMapView.delegate = self
        view.addSubview(nbMapView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }

    // Stop work when leaving the page; deinit alone cannot manage a repeating timer.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    deinit { animationTimer?.invalidate() }

    /// Reinstalls the raster source/layer and replaces any previous animation timer.
    func addImageSourceLayer() {
        stopAnimation()
        guard let style = nbMapView.style, let image = UIImage(named: "southeast_radar_0") else { return }
        // A referenced source cannot be removed until its layer is removed.
        if let layer = style.layer(withIdentifier: "style-raster-image-layer-id") { style.removeLayer(layer) }
        if let source = style.source(withIdentifier: "style-image-source-id") { style.removeSource(source) }
        // Match these corner coordinates to the geographic extent of your image.
        let quad = NGLCoordinateQuad(
            topLeft: CLLocationCoordinate2D(latitude: 46.437, longitude: -80.425),
            bottomLeft: CLLocationCoordinate2D(latitude: 37.936, longitude: -80.425),
            bottomRight: CLLocationCoordinate2D(latitude: 37.936, longitude: -71.516),
            topRight: CLLocationCoordinate2D(latitude: 46.437, longitude: -71.516))
        let source = NGLImageSource(identifier: "style-image-source-id", coordinateQuad: quad, image: image)
        style.addSource(source)
        style.addLayer(NGLRasterStyleLayer(identifier: "style-raster-image-layer-id", source: source))
        imageSource = source
        radarSuffix = 0
        startAnimation()
    }

    private func startAnimation() {
        // Style loading is asynchronous; do not start until the view is attached.
        guard animationTimer == nil, imageSource != nil, isViewLoaded, view.window != nil else { return }
        // RunLoop retains its timers. A weak callback avoids retaining this page
        // and its map until the timer is explicitly invalidated.
        let timer = Timer(timeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self, let source = self.imageSource,
                  let image = UIImage(named: "southeast_radar_\(self.radarSuffix)") else { return }
            source.image = image
            self.radarSuffix = (self.radarSuffix + 1) % 4
        }
        animationTimer = timer
        // Continue the animation while map gestures use the tracking run-loop mode.
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle) {
        mapView.setCenter(CLLocationCoordinate2D(latitude: 41.437, longitude: -76.425), zoomLevel: 5, animated: false)
        addImageSourceLayer()
    }
}
