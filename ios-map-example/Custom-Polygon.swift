import UIKit
import Nbmap

class PolygonViewController: UIViewController {

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
        nbMapView.delegate = self
        drawPolygon()
    }
    
    func drawPolygon(){
        let locations: [CLLocationCoordinate2D] =  [
            CLLocationCoordinate2D(latitude: 12.94798778, longitude: 77.57375084),
            CLLocationCoordinate2D(latitude: 12.93669616, longitude: 77.57385337),
            CLLocationCoordinate2D(latitude: 12.93639637, longitude: 77.58031279),
            CLLocationCoordinate2D(latitude: 12.94808770, longitude: 77.58000520)
        ]
        if let currentAnnotations = nbMapView.annotations {
            nbMapView.removeAnnotations(currentAnnotations)
        }
              
        let polygon: NGLPolygon = NGLPolygon.init(coordinates: locations, count: 4)
        nbMapView.addAnnotation(polygon)
    }
}

extension PolygonViewController: NGLMapViewDelegate {
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle){
        
        let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(12.94798778, 77.57375084),
                                                                      acrossDistance:10000,
                                                                               pitch:0,
                                                                             heading:0)
        nbMapView.fly(to: camera)
    
    }

    /**
     Returns the alpha value to use when rendering a shape annotation.

     A value of `0.0` results in a completely transparent shape. A value of `1.0`,
     the default, results in a completely opaque shape.

     This method sets the opacity of an entire shape, inclusive of its stroke and
     fill. To independently set the values for stroke or fill, specify an alpha
     component in the color returned by `-mapView:strokeColorForShapeAnnotation:` or
     `-mapView:fillColorForPolygonAnnotation:`.

     @param mapView The map view rendering the shape annotation.
     @param annotation The annotation being rendered.
     @return An alpha value between `0` and `1.0`.
     */
    func mapView(_ mapView: NGLMapView, alphaForShapeAnnotation annotation: NGLShape) -> CGFloat  {
        return 1.0
    }

    /**
     Returns the color to use when rendering the outline of a shape annotation.

     The default stroke color is the map view’s tint color. If a pattern color is
     specified, the result is undefined.

     Opacity may be set by specifying an alpha component. The default alpha value is
     `1.0` and results in a completely opaque stroke.

     @param mapView The map view rendering the shape annotation.
     @param annotation The annotation being rendered.
     @return A color to use for the shape outline.
     */
    func mapView(_ mapView: NGLMapView, strokeColorForShapeAnnotation annotation: NGLShape) -> UIColor  {
        return UIColor.red
    }

    /**
     Returns the color to use when rendering the fill of a polygon annotation.

     The default fill color is the map view’s tint color. If a pattern color is
     specified, the result is undefined.

     Opacity may be set by specifying an alpha component. The default alpha value is
     `1.0` and results in a completely opaque shape.

     @param mapView The map view rendering the polygon annotation.
     @param annotation The annotation being rendered.
     @return The polygon’s interior fill color.
     */
    
    func mapView(_ mapView: NGLMapView, fillColorForPolygonAnnotation annotation: NGLPolygon) -> UIColor  {
        return UIColor.blue
    }
   

    /**
     Returns the line width in points to use when rendering the outline of a
     polyline annotation.

     By default, the polyline is outlined with a line `3.0` points wide.

     @param mapView The map view rendering the polygon annotation.
     @param annotation The annotation being rendered.
     @return A line width for the polyline, measured in points.
     */
    func mapView(_ mapView: NGLMapView, lineWidthForPolylineAnnotation annotation: NGLPolyline) -> CGFloat  {
        return 3.0
    }
    
    /**
     Tells the delegate that one of its annotations was selected.

     You can use this method to track changes in the selection state of annotations.

     If the annotation is associated with an annotation view, you can also implement
     `-mapView:didSelectAnnotationView:`, which is called immediately after this
     method is called.

     @param mapView The map view containing the annotation.
     @param annotation The annotation that was selected.
     */
    func mapView(_ mapView: NGLMapView, didSelect annotation: NGLAnnotation){
        let title = (annotation.title ?? "") ?? ""
        print("didSelect title:" + title)
        let subtitle = (annotation.subtitle ?? "") ?? ""
        print("didSelect subtitle:" + subtitle)
    }

    /**
     Tells the delegate that one of its annotations was deselected.

     You can use this method to track changes in the selection state of annotations.

     If the annotation is associated with an annotation view, you can also implement
     `-mapView:didDeselectAnnotationView:`, which is called immediately after this
     method is called.

     @param mapView The map view containing the annotation.
     @param annotation The annotation that was deselected.
     */
    func mapView(_ mapView: NGLMapView, didDeselect annotation: NGLAnnotation){
        let title = (annotation.title ?? "") ?? ""
        print("didDeselect title:" + title)
        let subtitle = (annotation.subtitle ?? "") ?? ""
        print("didDeselect subtitle:" + subtitle)
    }
}
