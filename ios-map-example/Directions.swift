import Foundation
import UIKit
import Nbmap

class DirectionsViewController: UIViewController {

    var nbMapView: NGLMapView! {
        didSet {
            oldValue?.removeFromSuperview()
            if let mapView = nbMapView {
                view.insertSubview(mapView, at: 0)
            }
        }
    }
    
    var points : Array = [CLLocationCoordinate2D]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nbMapView = NGLMapView(frame:self.view.bounds)
        nbMapView.delegate = self
        drawDirections()
    }
    
    func drawDirections(){
        let locations: [CLLocationCoordinate2D] =  [
                   CLLocationCoordinate2D(latitude: 12.96206481, longitude: 77.56687669),
                   CLLocationCoordinate2D(latitude: 12.99150562, longitude: 77.61940507)
               ]

        let apiClient: NBAPIClient = NBAPIClient()
        apiClient.getDirections(locations) { [weak self] resp in
            guard let weakSelf = self else {
                return
            }
            let first = resp?.routes.first;
            if first is NBRoute {
                let route:NBRoute? = first as? NBRoute
                let geometry = route?.geometry
                let routeline = GeometryDecoder.covert(toFeature: geometry, precision:5)
                let routeSource = NGLShapeSource.init(identifier: "route-style-source", shape: routeline)
                weakSelf.nbMapView.style?.addSource(routeSource)
                let routeLayer = NGLLineStyleLayer.init(identifier: "route-layer", source: routeSource)
                routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.red)
                routeLayer.lineWidth = NSExpression.init(forConstantValue: 2)
                
                weakSelf.nbMapView.style?.addLayer(routeLayer)
            }
        }
    }
}

extension DirectionsViewController: NGLMapViewDelegate {
    // Set the camera after map style loaded
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle){
        
        let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(12.962, 77.56687669),
                                                                      acrossDistance:10000,
                                                                               pitch:0,
                                                                             heading:0)
        nbMapView.setCamera(camera, animated: false)
    
    }
}

