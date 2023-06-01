import UIKit
import Nbmap

class CustomPuckViewController: UIViewController {

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
        nbMapView.delegate = self
        nbMapView.userTrackingMode = .follow
    }
}

// MARK: - NGLMapViewDelegate
extension CustomPuckViewController: NGLMapViewDelegate {
 
    /**
     Asks the user styling options for each default user location annotation view.
     
     This method is called many times during gesturing, so you should avoid performing
     complex or performance-intensive tasks in your implementation.
     
     @param mapView The map view that is tracking the user’s location.
     */
    func mapView(styleForDefaultUserLocationAnnotationView mapView: NGLMapView) -> NGLUserLocationAnnotationViewStyle {
        let locationStyle =  NGLUserLocationAnnotationViewStyle()
        /**
         The fill color for the puck view.
         */
        locationStyle.puckFillColor = UIColor.blue
        /**
         The shadow color for the puck view.
         */
        locationStyle.puckShadowColor = UIColor.red
        /**
         The shadow opacity for the puck view.
         Set any value between 0.0 and 1.0.
         The default value of this property is equal to `0.25`
         */
        locationStyle.puckShadowOpacity = 0.25
        /**
         The fill color for the arrow puck.
         */
        locationStyle.puckArrowFillColor = UIColor.black
        /**
         The fill color for the puck view.
         */
        locationStyle.haloFillColor = UIColor.white
       
        if #available(iOS 14, *) {
            /**
             The halo fill color for the approximate view.
             */
            locationStyle.approximateHaloFillColor = UIColor.white
            /**
             The halo border color for the approximate view.
             */
            locationStyle.approximateHaloBorderColor = UIColor.white
            /**
             The halo border width for the approximate view.
             The default value of this property is equal to `2.0`
             */
            locationStyle.approximateHaloBorderWidth = 2.0
            /**
             The halo opacity for the approximate view.
             Set any value between 0.0 and 1.0
             The default value of this property is equal to `0.15`
             */
            locationStyle.approximateHaloOpacity = 0.15
        }
      
        return locationStyle
    }

    
    /**
     Returns a view object to mark the given point annotation object on the map.

     Implement this method to mark a point annotation with a view object. If you
     want to mark a particular point annotation with a static image instead, omit
     this method or have it return `nil` for that annotation, then implement
     `-mapView:imageForAnnotation:` instead.

     Annotation views are compatible with UIKit, Core Animation, and other Cocoa
     Touch frameworks. On the other hand, static annotation images use less memory
     and draw more quickly than annotation views.

     The user location annotation view can also be customized via this method. When
     `annotation` is an instance of `NGLUserLocation` (or equal to the map view’s
     `userLocation` property), return an instance of `NGLUserLocationAnnotationView`
     (or a subclass thereof).

     @param mapView The map view that requested the annotation view.
     @param annotation The object representing the annotation that is about to be
        displayed.
     @return The view object to display for the given annotation or `nil` if you
        want to display an annotation image instead.
     */
    func mapView(_ mapView: NGLMapView, viewFor annotation: NGLAnnotation) -> NGLAnnotationView?  {
        let annotationView = CustomUserLocationAnnotationView(frame: CGRect.zero)
        annotationView.frame = CGRect(x:0, y:0, width:annotationView.intrinsicContentSize.width, height:annotationView.intrinsicContentSize.height);
        return annotationView
    }
  
}
