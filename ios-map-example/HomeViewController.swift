//
//  ViewController.swift
//  maps-ios-demo
//
//  Created by qiu on 2022/9/8.
//

import UIKit


class HomeViewController: UITableViewController  {

    let examples: [String: [ViewModel]] = [
        "Map Configration":[
            ViewModel(name: "Map Configration", viewController: MapConfigViewController.self),
        ],
        "Map Camera":[
            ViewModel(name: "Map Camera", viewController: MapsCameraViewController.self),
        ],
        
        "Map Annotations":[
            ViewModel(name: "Custom Polyline View", viewController: PolylineViewController.self),
            ViewModel(name: "Custom Polygon View", viewController: PolygonViewController.self),
            ViewModel(name: "Custom Marker View", viewController: MarkerViewController.self),
            ViewModel(name: "Custom Annotations View", viewController: AnnotationsViewController.self),
        ],
        "Map view delegate":[
            ViewModel(name: "Map view delegate", viewController: MapViewDelegateViewController.self),
        ],
        "Runtime Styling":[
            ViewModel(name: "Custom Map Style Layer", viewController: StyleMapLayerViewController.self),
            ViewModel(name: "Animate Map Style Layer", viewController: AnimateMapLayerViewController.self),
            ViewModel(name: "Add Map Style Layer", viewController: AddMapStyleLayerViewController.self)

        ],
        "Snap to route":[
            ViewModel(name: "Directions View", viewController: DirectionsViewController.self),
        ],
        "Map Location":[
            ViewModel(name: "Update Location View Style", viewController: LocationStyleViewController.self),
            ViewModel(name: "Custom Puck view", viewController: CustomPuckViewController.self),
            ViewModel(name: "Custom Location Source", viewController: CustomLocationSourceViewController.self),
            
            
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
            return examples.count
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionKey = Array(examples.keys)[section]
        return examples[sectionKey]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionKey = Array(examples.keys)[section]
        return sectionKey
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "tableViewCell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        
        let sectionKey = Array(examples.keys)[indexPath.section]
        if let viewModels = examples[sectionKey], indexPath.row < viewModels.count {
            cell?.textLabel?.text = viewModels[indexPath.row].name
        }
        
        cell?.textLabel?.numberOfLines = 0
        
        return cell!
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
            
        let sectionKey = Array(examples.keys)[indexPath.section]
        if let viewModels = examples[sectionKey], indexPath.row < viewModels.count {
            let viewModel = viewModels[indexPath.row]
            let detailViewController = viewModel.viewController.init()
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
}

