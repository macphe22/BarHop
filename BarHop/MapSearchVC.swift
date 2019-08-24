//
//  MapSearchVC.swift
//  BarHop
//
//  Created by John Landy on 5/6/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AWSDynamoDB
import AWSAuthCore

// Map Search View Controller
class MapSearchVC: UIViewController {
    
    // Map view outlet
    @IBOutlet weak var mapView: MKMapView!
    // Button and label outlet
    @IBOutlet weak var button: UIButton!
    
    var barName = ""
    var index: Int?
    
    let locationManager = CLLocationManager()
    let regionSpan: Double = 10000
    
    var scanReturn: [MKPointAnnotation] = []
    var pinInfo: [[String: Any]] = []
    var names: [String] = []
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set button and label to invisible
        button.isHidden = true
        // Make the view controller the mapView's delegate
        mapView.delegate = self as MKMapViewDelegate
        // Call check location services
        checkLocationServices()
        // Add our pins here
        addPins()
        dispatchGroup.notify(queue: .main) {
            self.displayPins()
        }
    }
    
    // Function to handle moving on to PayVC and handling data forwarding
    @IBAction func barBtnClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "pushPayVC", sender: self)
    }
    
    // Override the prepare for segue function to handle data forwarding
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let payVC = segue.destination as! PayViewController
        // Find the bar within the names list
        payVC.barUserId = barName
        payVC.barItemId = pinInfo[index!]["rangeKey"] as? String
        payVC.cost = pinInfo[index!]["price"] as? Int
        payVC.numPassesText = pinInfo[index!]["numLeft"] as? Int
    }
    
    // Function to add custom pins to the mapview
    private func addPins() {
        // Call our scan here, and use the results to make new pins
        // Create a scan expression
        self.dispatchGroup.enter()
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        
        dynamoDBObjectMapper.scan(Bars.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result {
                // For each bar found in the scan, we will make a pin object and append it to the list
                for bar in paginatedOutput.items as! [Bars] {
                    let tempPin = MKPointAnnotation()
                    tempPin.title = bar._userId
                    tempPin.coordinate = CLLocationCoordinate2D(latitude: Double(truncating: bar._latitude!), longitude: Double(truncating: bar._longitude!))
                    self.scanReturn.append(tempPin)
                    // Add other important information needed later on
                    let hashKey = bar._userId!
                    let rangeKey = bar._itemId!
                    let numLeft = bar._numPassesLeft!
                    let price = bar._price!
                    let temp = ["hashKey": hashKey, "rangeKey": rangeKey, "numLeft": numLeft, "price": price] as [String : Any]
                    self.pinInfo.append(temp)
                    self.names.append(hashKey)
                }
            }
            self.dispatchGroup.leave()
        })
    }
    
    func displayPins() {
        for pin in scanReturn {
            mapView.addAnnotation(pin)
        }
    }
        
    // Function that centers the map on the user's location
    func centerViewOnUserLocation() {
        // Need if let and ? because location is an optional variable
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionSpan, longitudinalMeters: regionSpan)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Function to check if location services are enabled on device
    func checkLocationServices() {
        // If location services are already on, continue forward with pinning user
        // location. Otherwise, request that the user turn them on
        if CLLocationManager.locationServicesEnabled() {
            // Check location authorization
            checkLocationAuthorization()
        } else {
            // Here we need to show an alert letting the user know they have to turn these on
            let transMessage = "Go to settings to enable location"
            let alert = UIAlertController(title: "Location Services", message: transMessage, preferredStyle: .alert)
            // Add a Dismiss choice if the user wishes to leave location services off
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            // Add an option to navigate directly to settings
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            alert.addAction(settingsAction)
            self.present(alert, animated: true)
        }
    }
    
    // Function to check if location services are enabled for app
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            // Set map to user location (checkbox in sidebar of MapView)
            // Center the view on the user's location
            centerViewOnUserLocation()
            // Update the location
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Show alert instructing how to turn on permissions
            break
        case .notDetermined:
            // Request permissiosn
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // User cannot change app status (e.g. due to parental controls)
            // Show alert instructing how to turn on permissions
            break
        case .authorizedAlways:
            // Don't really need this one
            break
        @unknown default:
            // Default catcher
            break
        }
    }
    
    // Handles button and label properties
    private func addPinInfo(name: String) {
        // Set barName variable for later use
        barName = name
        index = names.firstIndex(of: barName)
        // Button
        button.isHidden = false
        button.frame = CGRect(x: 10, y: UIScreen.main.bounds.height*5/6, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/12 - 10)
        button.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        button.setTitle("Go to \(name)", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = UIColor(white: 0, alpha: 1).cgColor
        button.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        mapView.addSubview(button)
    }
}

// Allow extension from CLLocationManagerDelegate
extension MapSearchVC: CLLocationManagerDelegate {
    // Handles permission authorization changes, simply calls checkLocationAuthorization()
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension MapSearchVC: MKMapViewDelegate {
    // Function that runs when an annotation is clicked
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Modally present a new view label and button to go to the correct screen
        if (view.annotation?.title != "My Location") {
            addPinInfo(name: (view.annotation?.title)! ?? "Bar")
        }
    }
}
