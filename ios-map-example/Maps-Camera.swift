import Foundation
import UIKit
import Nbmap

enum CameraType{
    case CameraSetCenterCoordinate
    case CameraSetCenterCoordinateWithZoomLevel
    case CameraSetCenterCoordinateWithZoomLevelAndDirection
    case CameraSetCenterCoordinateWithZoomLevelAndDirectionCompletion
    case SetZoomLevel
    case SetDirection
case SetVisibleCoordinateBounds
    case SetVisibleCoordinateBoundsWithEdgePadding
    case SetVisibleCoordinatesWithEdgePadding
    case SetVisibleCoordinatesWithEdgePaddingAndDirectionAndDuration
    case SetCamera
    case SetCameraWithDuration
    case SetCameraWithDurationAndCompletionHandler
    case FlyToCamera
    case FlyToCameraWithDuration
    case FlyToCameraWithDurationAndPeakAltitude
}


class MapsCameraViewController: UIViewController {
    
    var nbMapView: NGLMapView! {
        didSet {
            oldValue?.removeFromSuperview()
            if let mapView = nbMapView {
                configureMapView(nbMapView)
                view.insertSubview(mapView, at: 0)
            }
        }
    }
    
    var button: UIButton!
    
    let typeList = [
        CameraType.CameraSetCenterCoordinate,
        CameraType.CameraSetCenterCoordinateWithZoomLevel,
        CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirection,
        CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirectionCompletion,
        CameraType.SetZoomLevel,
        CameraType.SetDirection,
        CameraType.SetVisibleCoordinateBounds,
        CameraType.SetVisibleCoordinateBoundsWithEdgePadding,
        CameraType.SetVisibleCoordinatesWithEdgePadding,
        CameraType.SetVisibleCoordinatesWithEdgePaddingAndDirectionAndDuration,
        CameraType.SetCamera,
        CameraType.SetCameraWithDuration,
        CameraType.SetCameraWithDurationAndCompletionHandler,
        CameraType.FlyToCamera,
        CameraType.FlyToCameraWithDuration,
        CameraType.FlyToCameraWithDurationAndPeakAltitude,
    ]
    
    func configureMapView(_ mapView: NGLMapView) {
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nbMapView = NGLMapView(frame:self.view.bounds)
        
        button = UIButton(type: .system)
        button.setTitle("Settings", for: .normal)
        button.addTarget(self, action: #selector(showSetings), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
    }
    
    @objc func showSetings() {
        let tableViewController = UITableViewController(style: .plain)
        tableViewController.tableView.delegate = self
        tableViewController.tableView.dataSource = self
        tableViewController.title = "Camera Settings"
        self.present(tableViewController, animated: true)
    }
    
    /**
     Perform operations on the map based on user selection
     @param type:  The type which user selected. user to perform operations on the map
     */
    func performeSettings(type: CameraType) {
        switch type {
        case CameraType.CameraSetCenterCoordinate :
            nbMapView.setCenter(CLLocationCoordinate2DMake(53.5511, 9.9937),animated: true )
            break
        case .CameraSetCenterCoordinateWithZoomLevel:
            nbMapView.setCenter(CLLocationCoordinate2DMake(53.5511, 9.9937),zoomLevel: 18 ,animated: true )
            break
        case CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirection :
            nbMapView.setCenter(CLLocationCoordinate2DMake(53.5511, 9.9937),zoomLevel: 18 ,direction: 180, animated: true )
            break
        case CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirectionCompletion :
            nbMapView.setCenter(CLLocationCoordinate2DMake(53.5511, 9.9937),zoomLevel: 18 ,direction: 180, animated: true ,completionHandler: {
                
            })
            break
        case CameraType.SetZoomLevel :
            nbMapView.setZoomLevel(17, animated: true)
            break
        case CameraType.SetDirection :
            nbMapView.setDirection(0, animated: true)
            break
        case .SetVisibleCoordinateBounds:
            let coords = [
                CLLocationCoordinate2DMake(53.5511, 9.9937),
                CLLocationCoordinate2DMake(53.5311, 9.9947),
                CLLocationCoordinate2DMake(53.5531, 9.9957),
                CLLocationCoordinate2DMake(53.5521, 9.9967)
            ]
            let bounds = NGLPolygon(coordinates: coords, count: UInt(coords.count)).overlayBounds
            //  Changes the receiver’s viewport to fit the given coordinate bounds, optionally animating the change.
            nbMapView.setVisibleCoordinateBounds(bounds,animated: true)
            break
        case .SetVisibleCoordinateBoundsWithEdgePadding:
            let coords = [
                CLLocationCoordinate2DMake(53.5511, 9.9937),
                CLLocationCoordinate2DMake(53.5311, 9.9947),
                CLLocationCoordinate2DMake(53.5531, 9.9957),
                CLLocationCoordinate2DMake(53.5521, 9.9967)
            ]
            let bounds = NGLPolygon(coordinates: coords, count: UInt(coords.count)).overlayBounds

            //  Changes the receiver’s viewport to fit the given coordinate bounds with some additional padding on each side, optionally calling a completion handler.
            nbMapView.setVisibleCoordinateBounds(bounds,edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),animated: true,completionHandler: {})
            break
        case .SetVisibleCoordinatesWithEdgePadding:
            let coords = [
                CLLocationCoordinate2DMake(53.5511, 9.9937),
                CLLocationCoordinate2DMake(53.5313, 9.9947),
                CLLocationCoordinate2DMake(53.5531, 9.9937),
                CLLocationCoordinate2DMake(53.5526, 9.9968)
            ]
            //  Changes the receiver’s viewport to fit all of the given coordinates with some additional padding on each side.
            nbMapView.setVisibleCoordinates(coords,count: UInt(coords.count),edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),animated: true)
            break
        case .SetVisibleCoordinatesWithEdgePaddingAndDirectionAndDuration:
            let coords = [
                CLLocationCoordinate2DMake(53.5511, 9.9937),
                CLLocationCoordinate2DMake(53.5313, 9.9987),
                CLLocationCoordinate2DMake(53.5533, 9.9947),
                CLLocationCoordinate2DMake(53.5529, 9.9938)
            ]
            let function: CAMediaTimingFunction? = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            //  Changes the receiver’s viewport to fit all of the given coordinates with some additional padding on each side, optionally calling a completion handler.
            nbMapView.setVisibleCoordinates(coords,count: UInt(coords.count),edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),direction:160, duration: 2, animationTimingFunction: function,completionHandler: nil)
            break

        case CameraType.SetCamera :
            let camera =  NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            //  Moves the viewpoint to a different location with respect to the map with an
            //  optional transition animation. For animated changes, wait until the map view has
            //  finished loading before calling this method.
            nbMapView.setCamera(camera, animated: true)
            break
        case .SetCameraWithDuration:
            let camera =  NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            let function: CAMediaTimingFunction? = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            // Moves the viewpoint to a different location with respect to the map with an
            // optional transition duration and timing function. For animated changes, wait
            // until the map view has finished loading before calling this method.
            nbMapView.setCamera(camera, withDuration: 1 ,animationTimingFunction: function)
            break
            
        case   CameraType.SetCameraWithDurationAndCompletionHandler:
            let function: CAMediaTimingFunction? = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            let camera =  NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            //  Moves the viewpoint to a different location with respect to the map with an
            //  optional transition duration and timing function. For animated changes, wait
            //  until the map view has finished loading before calling this method.
            nbMapView.setCamera(camera, withDuration: 1 ,animationTimingFunction: function,completionHandler: {
                
            })
            break
        case CameraType.FlyToCamera :
            let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            //  Moves the viewpoint to a different location using a transition animation that
            //  evokes powered flight and a default duration based on the length of the flight path.
            
            // The transition animation seamlessly incorporates zooming and panning to help
            // the user find his or her bearings even after traversing a great distance.
            nbMapView.fly(to: camera)
            break
        case CameraType.FlyToCameraWithDuration :
            let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            // Moves the viewpoint to a different location using a transition animation that
            // evokes powered flight and an optional transition duration.

            // The transition animation seamlessly incorporates zooming and panning to help
            // the user find his or her bearings even after traversing a great distance.
            nbMapView.fly(to: camera, withDuration: 2 , completionHandler: {
                
            })
            break
        case CameraType.FlyToCameraWithDurationAndPeakAltitude :
            let camera = NGLMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(53.5511, 9.9937),
                                       acrossDistance:1000,
                                                pitch:0,
                                              heading:0)
            
            // Moves the viewpoint to a different location using a transition animation that
            //  evokes powered flight and an optional transition duration and peak altitude.

            // The transition animation seamlessly incorporates zooming and panning to help
            // the user find his or her bearings even after traversing a great distance.
            nbMapView.fly(to: camera, withDuration: 2 , peakAltitude: 1000 ,completionHandler: {
                
            })
            break
       
        }
        
    }
}

extension MapsCameraViewController: NGLMapViewDelegate {
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle){
        
        nbMapView.zoomLevel = 16.0
        nbMapView.setCenter(CLLocationCoordinate2DMake(53.5511, 9.9937),animated: false)
        
    }
}

extension MapsCameraViewController: UITableViewDelegate, UITableViewDataSource {
    
    func settingsTitlesForRaw(index: Int) -> String {
        let type = typeList[index]
        switch type {
            case CameraType.CameraSetCenterCoordinate :
                return "Camera Set Center Coordinate"
            case CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirection :
                return "Set center coordinate with zoom level and direction"
            case CameraType.CameraSetCenterCoordinateWithZoomLevelAndDirectionCompletion :
                return "Set center coordinate with zoom level and direction completion handler"
            case CameraType.SetZoomLevel :
                return "Set zoom level"
            case CameraType.SetDirection :
                return "Set direction"
            case CameraType.SetVisibleCoordinateBounds :
                return "Set visible coordinate bounds"
            case CameraType.SetVisibleCoordinateBoundsWithEdgePadding :
                return "Set visible coordinate bounds with edge padding"
            case .SetVisibleCoordinatesWithEdgePadding:
                return "Set visible coordinates with edge padding"
            case .SetVisibleCoordinatesWithEdgePaddingAndDirectionAndDuration:
                return "Set visible coordinates with edge padding and direction and direction"
            case CameraType.SetCamera :
                return "Set camera"
            case CameraType.FlyToCamera :
                return "Fly to camera"
            case CameraType.FlyToCameraWithDuration :
                return "Fly to camera with duration"
            case CameraType.FlyToCameraWithDurationAndPeakAltitude :
                return "Fly to camera with duration and peak altitude"
            case .CameraSetCenterCoordinateWithZoomLevel:
                return "Set center coordinate with zoom level"
            case .SetCameraWithDurationAndCompletionHandler:
                return "Set camera with duration and completion handler"
            case .SetCameraWithDuration:
                return "Set camera with duration"
        }
    }
    // UITableViewDelegate 和 UITableViewDataSource 方法的实现
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return typeList.count
     }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
         cell.textLabel?.text = settingsTitlesForRaw(index: indexPath.row)
         return cell
     }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         tableView.isHidden = true
         let type = typeList[indexPath.row]
        dismissSettings(type: type)
     }
    
    func dismissSettings(type: CameraType) {
        dismiss(animated: true)
        performeSettings(type: type)
    }
}
