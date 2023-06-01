import Foundation
import UIKit
import Nbmap


class CustomLocationSourceViewController: UIViewController {

    var nbMapView: NGLMapView! {
        didSet {
            oldValue?.removeFromSuperview()
            if let mapView = nbMapView {
                view.insertSubview(mapView, at: 0)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nbMapView = NGLMapView(frame:self.view.bounds)
        nbMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        /**
         Custom the location source , The locationManager that this map view uses to start and stop the delivery of
         location-related updates.

         To receive the current user location, implement the
         `-[NGLMapViewDelegate mapView:didUpdateUserLocation:]` and
         `-[NGLMapViewDelegate mapView:didFailToLocateUserWithError:]` methods.

         If setting this property to `nil` or if no custom manager is provided this
         property is set to the default location manager.

         `NGLMapView` uses a default location manager. If you want to substitute your
         own location manager, you should do so by setting this property before setting
         `showsUserLocation` to `YES`. To restore the default location manager,
         set this property to `nil`.
         */
        nbMapView.locationManager = CustomMapLocationManager()
        nbMapView.showsUserLocation = true
        nbMapView.userTrackingMode = .follow
    }
}
