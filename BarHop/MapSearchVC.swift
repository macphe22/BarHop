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
import AWSAuthUI
import AWSMobileClient

// Map Search View Controller
class MapSearchVC: UIViewController {
    
    // Map view outlet
    @IBOutlet weak var mapView: MKMapView!
    // Button and label outlet
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var termsOfUseLabel: UILabel!
    @IBOutlet weak var acceptBtn: UIButton!
    
    // For checking active passes
    var activePasses: Set<String>?
    var userHasPass: Bool = false
    var numPassesLeft: Int?
    
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
        // Set up navigation bar logo
        let logoImage = UIImage(named: "NavBarLogo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        logoImageView.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoImageView)
        // Set terms of use information to invisible
        termsOfUseLabel.isHidden = true
        acceptBtn.isHidden = true
        // Handle terms of use styling
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        acceptBtn.layer.borderColor = midBlue.cgColor
        acceptBtn.layer.cornerRadius = 8
        acceptBtn.setTitleColor(midBlue, for: .normal)
        // Set button and label to invisible
        button.isHidden = true
        button.frame = CGRect(x: 10, y: UIScreen.main.bounds.height*5/6, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height/12 - 10)
        button.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        button.layer.cornerRadius = 8
        button.layer.backgroundColor = UIColor(white: 0, alpha: 1).cgColor
        button.layer.borderColor = midBlue.cgColor
        button.layer.borderWidth = 2
        button.setTitleColor(midBlue, for: .normal)
        // Make the view controller the mapView's delegate
        mapView.delegate = self as MKMapViewDelegate
        // Handle sign in here
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            presentAuthUIViewController()
        } else {
            postAuth()
        }
        // Handle button disappearing code
        let gesture = UITapGestureRecognizer(target: self, action: #selector(hideBtn))
        mapView.addGestureRecognizer(gesture)
    }
    
    // Function that makes the button invisible upon a click to the map
    @objc func hideBtn() {
        button.isHidden = true
    }
    
    // Function that handles post-authorization
    func postAuth() {
        // Call check location services
        checkLocationServices()
        // Add our pins here
        addPins()
        dispatchGroup.notify(queue: .main) {
            self.displayPins()
        }
    }
    
    // Present the view controller responsible for user login and signup
    func presentAuthUIViewController() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        config.backgroundColor = UIColor(white: 0, alpha: 1)
        config.isBackgroundColorFullScreen = true
        config.logoImage = UIImage(named: "logoImage")
        
        AWSAuthUIViewController.presentViewController(with: self.navigationController!,
                                                      configuration: config, completionHandler: { (provider: AWSSignInProvider, error: Error?) in
            if error == nil {
                // SignIn succeeded.
                // We can check to see if the customer with the provided information is in the database
                // already, and if not, create a new customer object
                self.findCustomer(userId: AWSIdentityManager.default().identityId!)
            } else {
                // end user faced error while loggin in, take any required action here.
            }
        })
    }
    
    // Function to handle searching for customer
    func findCustomer(userId: String) {
        let customerItem: Customer = Customer();
        customerItem._userId = userId
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
            if error != nil {
                // An error has occurred
            } else if (objectModel as? Customer) != nil {
                // The customer already exists; we don't need to do anything here
                // except handle post authorization setup details
                self.postAuth()
            } else if (objectModel as? Customer) == nil {
                // The customer was not found, we can create the customer
                self.createCustomer()
            }
        })
    }
    
    // Function to retrieve the size of the customers table in order to provide a uniqueId to be
    // used for processing payments via braintree
    func getTableSize() -> NSNumber {
        // First enter the dispatch group
        self.dispatchGroup.enter()
        // Then we can begin our scan
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        var count: NSNumber = 0
        dynamoDBObjectMapper.scan(Customer.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result {
                for _ in paginatedOutput.items as! [Customer] {
                    count = (Int(truncating: count) + 1) as NSNumber
                }
            }
            // We can leave our dispatch group once we finish retrieving customers
            self.dispatchGroup.leave()
        })
        return count
    }
    
    // Function that handles making new users agree to BarHop's terms of use
    func termsOfUse() {
        // Make everything invisible except the terms of use information
        DispatchQueue.main.async {
            self.mapView.isHidden = true
            self.termsOfUseLabel.isHidden = false
            self.acceptBtn.isHidden = false
        }
    }
    
    // Function that handles making terms of use info invisible when the accept button is clicked
    @IBAction func acceptBtnClicked(_ sender: Any) {
        // Make everything visible again except the terms of use information
        DispatchQueue.main.async {
            self.mapView.isHidden = false
            self.termsOfUseLabel.isHidden = true
            self.acceptBtn.isHidden = true
        }
    }
    
    // Creating a new customer
    func createCustomer(){
        //print("Creating Customer")
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let newCust:Customer = Customer()
        //initialize values for attributes for new customer
        let barSet: Set<String> = ["EMPTY_STRING"]
        newCust._userId = AWSIdentityManager.default().identityId //_userId represents the partition key
        newCust._tripsTaken = 0
        newCust._activeTrips = barSet
        // Also add in the customer's unique id (we need to use dispatch queues to do this)
        let count: NSNumber = getTableSize()
        dispatchGroup.notify(queue: .main) {
            newCust._braintreeId = count
            //Save a new item (notice how we save inside of the dispatch notify)
            dynamoDbObjectMapper.save(newCust, completionHandler: { (error: Error?) -> Void in
                if let error = error {
                    print("Amazon DynamoDB Save Error: \(error)")
                    return
                }
                // Now that we've created a new customer, we should bring up a one-time
                // terms of service agreement telling the customer our policies on refunds, etc.
                self.termsOfUse()
                self.postAuth()
            })
        }
    }
    
    // Function to handle moving on to PayVC and handling data forwarding
    @IBAction func barBtnClicked(_ sender: Any) {
        if (!userHasPass) {
            self.performSegue(withIdentifier: "pushPayVC", sender: self)
        } else {
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    // Handle sign out
    @IBAction func signOutBtnPressed(_ sender: Any) {
        AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
            self.viewDidLoad()
        })
    }
    
    // Override the prepare for segue function to handle data forwarding
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let payVC = segue.destination as! PayViewController
        // Find the bar within the names list
        payVC.barUserId = barName
        payVC.barItemId = pinInfo[index!]["rangeKey"] as? String
        payVC.cost = pinInfo[index!]["price"] as? Int
        payVC.numPassesText = pinInfo[index!]["numLeft"] as? Int
        payVC.address = pinInfo[index!]["address"] as? String
        payVC.city = pinInfo[index!]["city"] as? String
        payVC.state = pinInfo[index!]["state"] as? String
        payVC.zipCode = pinInfo[index!]["zipCode"] as? String
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
                    let address = bar._address!
                    let city = bar._city!
                    let state = bar._state!
                    let zipCode = bar._zipCode!
                    let temp = ["hashKey": hashKey,
                                "rangeKey": rangeKey,
                                "numLeft": numLeft,
                                "price": price,
                                "address": address,
                                "city": city,
                                "state": state,
                                "zipCode": zipCode] as [String : Any]
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
    
    // Function that queries to see if the user already has an active pass at the selected venue
    func checkPasses() {
        // Create a query expression
        self.dispatchGroup.enter()
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        customerItem._tripsTaken = 0
        dynamoDbObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
                                    if let error = error {
                                        print("Amazon DynamoDB Read Error: \(error)")
                                        return
                                    }
                                    else if let loadedCustomer = objectModel as? Customer {
                                        self.activePasses = loadedCustomer._activeTrips!
                                    }
                                    // Now that we have finished retrieving the user's active passes, we can return whether or not
                                    // we have found the user's active passes contain the current venue
                                    let dict = self.pinInfo[self.index!]
                                    let passName: String = self.names[self.index!] + "," + String(describing: dict["rangeKey"]!)
                                    if ((self.activePasses?.contains(passName))!) {
                                        self.userHasPass = true
                                    } else {
                                        self.userHasPass = false
                                    }
                                    self.numPassesLeft = dict["numLeft"] as? Int
                                    self.dispatchGroup.leave()
        })
    }
    
    // Handles button and label properties
    private func addPinInfo(name: String) {
        // Set barName variable for later use
        barName = name
        index = names.firstIndex(of: barName)
        // First we need to check if the user already has a pass or the passes are sold out
        checkPasses()
        // Button
        dispatchGroup.notify(queue: .main) {
            if (self.userHasPass) {
                self.button.setTitleColor(.red, for: .normal)
                self.button.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                self.button.setTitle("Pass already purchased", for: .normal)
                self.button.isHidden = false
                self.mapView.addSubview(self.button)
            } else if (self.numPassesLeft! <= 0) {
                self.button.setTitleColor(.red, for: .normal)
                self.button.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                self.button.setTitle("No passes available", for: .normal)
                self.button.isEnabled = false
                self.button.isHidden = false
                self.mapView.addSubview(self.button)
            } else {
                let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
                self.button.setTitleColor(midBlue, for: .normal)
                self.button.layer.borderColor = midBlue.cgColor
                self.button.setTitle("Go to \(name)", for: .normal)
                self.button.isEnabled = true
                self.button.isHidden = false
                self.mapView.addSubview(self.button)
            }
        }
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
