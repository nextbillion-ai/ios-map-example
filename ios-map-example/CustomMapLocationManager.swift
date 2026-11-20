import Nbmap
import CoreLocation

/// Bridges Core Location updates into the SDK's location-manager contract.
/// Assign this adapter to mapView.locationManager before enabling showsUserLocation.
class CustomMapLocationManager: NSObject,NGLLocationManager {
    
    // The map owns this manager; its delegate must not own the map back.
    weak var delegate: NGLLocationManagerDelegate?
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        // Configure Core Location once, independently of changes to the SDK delegate.
        locationManager.delegate = self
    }

    var headingOrientation: CLDeviceOrientation {
        get {
            return locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
    }
    
    var desiredAccuracy: CLLocationAccuracy {
        get {
            return locationManager.desiredAccuracy
        }
        set {
            locationManager.desiredAccuracy = newValue
        }
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    var activityType: CLActivityType {
        get {
            return locationManager.activityType
        }
        set {
            locationManager.activityType = newValue
        }
    }
    
    @available(iOS 14.0, *)
    var accuracyAuthorization: CLAccuracyAuthorization {
        return locationManager.accuracyAuthorization
    }
    
    @available(iOS 14.0, *)
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey)
    }
    
    func dismissHeadingCalibrationDisplay() {
        locationManager.dismissHeadingCalibrationDisplay()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Release sensor work on teardown. Avoid assigning our own delegate here:
    // the map may already be deallocating and clearing that same relationship.
    deinit {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        locationManager.delegate = nil
    }
    
}

// MARK: - CLLocationManagerDelegate
extension CustomMapLocationManager : CLLocationManagerDelegate {
  
    // Forward this adapter as the sender because it is the NGLLocationManager
    // instance owned by the map, rather than the wrapped CLLocationManager.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(self, didUpdate: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return delegate?.locationManagerShouldDisplayHeadingCalibration(self) ?? false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationManagerDidChangeAuthorization(self)
    }
}
