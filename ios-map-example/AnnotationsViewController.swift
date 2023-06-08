//
//  AnnotationsViewController.swift
//  maps-ios-demo
//
//  Created by qiuyu on 2023/5/31.
//

import Foundation
import UIKit
import Nbmap

enum AnnotationActionType{
    case AddAnnotations
    case AddNumberAnnotations
    case AnimateAnnotations
    case QueryVisibleAnnotations
    case CenterSelectedAnnotations
    case AddVisibleAreaPolyline

}

class AnnotationsViewController: UIViewController {
    
    var nbMapView: NGLMapView! {
        didSet {
            oldValue?.removeFromSuperview()
            if let mapView = nbMapView {
                view.insertSubview(mapView, at: 0)
                mapView.delegate = self
            }
        }
    }
    var button: UIButton!
    
    let typeList = [
        AnnotationActionType.AddAnnotations,
        AnnotationActionType.AddNumberAnnotations,
        AnnotationActionType.AnimateAnnotations,
        AnnotationActionType.QueryVisibleAnnotations,
        AnnotationActionType.CenterSelectedAnnotations,
        AnnotationActionType.AddVisibleAreaPolyline,
    ]
    
    
    var points : Array = [CLLocationCoordinate2D]()
    
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
    
    func performeSettings(type: AnnotationActionType) {
        switch type {
        case AnnotationActionType.AddAnnotations :
            addAnnotations(count: 100)
            break
        case AnnotationActionType.AddNumberAnnotations :
            addAnnotations(count: 1000)
            break
        case .AnimateAnnotations:
            animateAnnotations()
            break
        case .QueryVisibleAnnotations:
            queryVisibleAnnotations()
            break
        case .CenterSelectedAnnotations:
            centerSelectedAnnotation()
            break
        case .AddVisibleAreaPolyline:
            addVisibleAreaPolyline()
            break
        }
        
    }
    
    func addAnnotations(count: Int32) {
        
        if let annotations = self.nbMapView.annotations {
            self.nbMapView.removeAnnotations(annotations)
        }

        DispatchQueue.global(qos: .default).async {
            if let featuresData = try? Data(contentsOf: Bundle.main.url(forResource: "points", withExtension: "geojson")!),
                let features = try? JSONSerialization.jsonObject(with: featuresData, options: []) as? [String: Any] {
                
                var annotations = [NGLPointAnnotation]()
                
                if let featureList = features["features"] as? [[String: Any]] {
                    for feature in featureList {
                        if let coordinates = feature["geometry"] as? [String: Any],
                           let coordinateList = coordinates["coordinates"] as? [Double],
                           let title = feature["properties"] as? [String: Any] {
                            
                            let coordinate = CLLocationCoordinate2D(latitude: coordinateList[1], longitude: coordinateList[0])
                            let annotation = NGLPointAnnotation()
                            annotation.coordinate = coordinate
                            annotation.title = title["NAME"] as? String
                            
                            annotations.append(annotation)
                            
                            if annotations.count == count {
                                break
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.nbMapView.addAnnotations(annotations)
                        self.nbMapView.showAnnotations(annotations, animated: true)
                    }
                }
            }
        }

    }
    
    func animateAnnotations () {
        let annot = NGLPointAnnotation()
        annot.coordinate = self.nbMapView.centerCoordinate
        self.nbMapView.addAnnotation(annot)

        let point = CGPoint(x: self.view.frame.origin.x + 200, y: self.view.frame.midY)
        let coord = self.nbMapView.convert(point, toCoordinateFrom: self.view)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.animate(withDuration: 1) {
                annot.coordinate = coord
            }
        }

    }
    
    func queryVisibleAnnotations() {
        let visibleAnnotationCount = NSNumber(value: self.nbMapView.visibleAnnotations?.count ?? 0)
        var message: String

        if visibleAnnotationCount.intValue == 1 {
            message = "There is \(visibleAnnotationCount) visible annotation."
        } else {
            message = "There are \(visibleAnnotationCount) visible annotations."
        }

        let alertController = UIAlertController(title: "Visible Annotations", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)

    }
    
    func centerSelectedAnnotation() {
        
        if let annotation = self.nbMapView.selectedAnnotations.first {
            let point = self.nbMapView.convert(annotation.coordinate, toPointTo: self.nbMapView)
            let center = self.nbMapView.convert(point, toCoordinateFrom: self.nbMapView)
            self.nbMapView.setCenter(center, animated: true)
        }
    }

    func addVisibleAreaPolyline() {
        let constrainedRect = self.nbMapView.bounds.inset(by: self.nbMapView.contentInset)

        var lineCoords = [CLLocationCoordinate2D]()

        lineCoords.append(self.nbMapView.convert(CGPoint(x: constrainedRect.minX, y: constrainedRect.minY), toCoordinateFrom: self.nbMapView))
        lineCoords.append(self.nbMapView.convert(CGPoint(x: constrainedRect.maxX, y: constrainedRect.minY), toCoordinateFrom: self.nbMapView))
        lineCoords.append(self.nbMapView.convert(CGPoint(x: constrainedRect.maxX, y: constrainedRect.maxY), toCoordinateFrom: self.nbMapView))
        lineCoords.append(self.nbMapView.convert(CGPoint(x: constrainedRect.minX, y: constrainedRect.maxY), toCoordinateFrom: self.nbMapView))
        lineCoords.append(lineCoords[0])

        let line = NGLPolyline(coordinates: &lineCoords, count: UInt(lineCoords.count))
        self.nbMapView.addAnnotation(line)

    }
    
  
}


extension AnnotationsViewController: NGLMapViewDelegate {
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle){
        nbMapView.setCenter(CLLocationCoordinate2DMake(38.87031006108791, -77.00896639534831), zoomLevel: 10, animated: true)
        
    }
    
    func mapView(_ mapView: NGLMapView, didSelect annotation: NGLAnnotation) {
        let point = self.nbMapView.convert(annotation.coordinate, toPointTo: self.nbMapView)
        let center = self.nbMapView.convert(point, toCoordinateFrom: self.nbMapView)
        self.nbMapView.setCenter(center, zoomLevel: 14, animated: true)
    }
    
    func mapView(_ mapView: NGLMapView, annotationCanShowCallout annotation: NGLAnnotation) -> Bool {
        return true
    }
}

extension AnnotationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func settingsTitlesForRaw(index: Int) -> String {
        let type = typeList[index]
        switch type {
        case AnnotationActionType.AddAnnotations :
            return "Add 100 Annotations"
        case AnnotationActionType.AddNumberAnnotations :
            return "Add 1000 Annotations"
        case AnnotationActionType.AnimateAnnotations :
            return "Animate Annotations"
        case AnnotationActionType.QueryVisibleAnnotations :
            return "Query Visible Annotations"
        case AnnotationActionType.CenterSelectedAnnotations :
            return "Center Selected Annotations"
        case AnnotationActionType.AddVisibleAreaPolyline :
            return "Add Visible Area Polyline"
        }
    }
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
    
    func dismissSettings(type: AnnotationActionType) {
        dismiss(animated: true)
        performeSettings(type: type)
    }
}
