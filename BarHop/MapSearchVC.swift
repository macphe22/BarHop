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
import AWSCore
import BraintreeDropIn
import Braintree

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
    
    // Popup variables
    @IBOutlet weak var popupCloseBtn: UIButton!
    @IBOutlet weak var popupBarNameLabel: UILabel!
    @IBOutlet weak var popupCostLabel: UILabel!
    @IBOutlet weak var popupAddressLabel: UILabel!
    @IBOutlet weak var popupNumPassesLabel: UILabel!
    @IBOutlet weak var popupPayBtn: UIButton!
    @IBOutlet weak var popupValidUntilLabel: UILabel!
    
    @IBOutlet weak var popupView: UIView!
    
    var backgroundTask: UIBackgroundTaskIdentifier?
    var braintree: NSNumber?
    var barItemId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Popup visibility
        popupView.isHidden = true
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
            // Variable passing
            self.barItemId = pinInfo[index!]["rangeKey"] as? String
            // Close Button
            popupCloseBtn.setTitleColor(.red, for: .normal)
            // Bar Label
            popupBarNameLabel.text = "\(String(describing: pinInfo[index!]["hashKey"]!))"
            popupBarNameLabel.textColor = .white
            // Cost Label
            popupCostLabel.text = "$\(String(describing: pinInfo[index!]["price"]!))"
            popupCostLabel.textColor = .white
            // Address Label
            let address1 = pinInfo[index!]["address"] as? String
            let address2 = "\(pinInfo[index!]["city"] as! String), \(pinInfo[index!]["state"] as! String) \(pinInfo[index!]["zipCode"] as! String)"
            popupAddressLabel.text = "\(address1!)\n\(address2)"
            popupAddressLabel.textColor = .white
            // Num Passes Label
            popupNumPassesLabel.text = "\(String(describing: pinInfo[index!]["numLeft"]!)) passes left"
            popupNumPassesLabel.textColor = .white
            // Pay Button
            let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
            popupPayBtn.layer.cornerRadius = 8
            popupPayBtn.layer.borderWidth = 1
            popupPayBtn.layer.borderColor = midBlue.cgColor
            popupPayBtn.setTitleColor(midBlue, for: .normal)
            popupPayBtn.isEnabled = true
            // Valid Until Label
            let calendar = Calendar.current
            // TODO: Calculate actual times here
            let date = calendar.date(byAdding: .hour, value: -4, to: Date())!
            let hour = calendar.component(.hour, from: date)
            let dateComponents : DateComponents = {
                var dateComp = DateComponents()
                dateComp.day = 1
                return dateComp
            }()
            // TODO: Adjust this hour time below for endDate; currently, will allow the user to only buy pass for next day after 4 am (or later if daylight savings time)
            let endDate = (hour > 4) ? Calendar.current.date(byAdding: dateComponents, to: date) : date
            // Format the date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss '+0000'"
            // Extract the month and day
            formatter.dateFormat = "MM"
            let moOut = formatter.string(from: endDate!)
            let mo = month(mo: moOut)
            formatter.dateFormat = "dd"
            var day = formatter.string(from: endDate!)
            if (Array(day)[0] == "0") { day = String(Array(day)[1]) }
            popupValidUntilLabel.text = "Valid until \(mo) \(day) at 2 am"
            popupValidUntilLabel.textColor = UIColor(white: 1, alpha: 1)
            popupValidUntilLabel.textAlignment = NSTextAlignment.center
            // View
            popupView.layer.cornerRadius = 12
            popupView.isHidden = false
        } else {
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    // Function to handle closing the popup
    @IBAction func popupCloseBtnClicked(_ sender: Any) {
        self.popupView.isHidden = true
    }
    
    // Function to return written month
    func month(mo: String) -> String {
        switch mo {
        case "01": return "January"
        case "02": return "February"
        case "03": return "March"
        case "04": return "April"
        case "05": return "May"
        case "06": return "June"
        case "07": return "July"
        case "08": return "August"
        case "09": return "September"
        case "10": return "October"
        case "11": return "November"
        case "12": return "December"
        case "00": return "December"
        default: return ""
        }
    }
    
    // Handle sign out
    @IBAction func signOutBtnPressed(_ sender: Any) {
        AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
            self.viewDidLoad()
        })
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
    
    // Function that handles updating a Bar's remaining passes
    func updatePasses() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let barItemId = pinInfo[index!]["rangeKey"] as? String
        
        dynamoDBObjectMapper.load(Bars.self, hashKey: barName, rangeKey:
            barItemId).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as NSError? {
                    print("The request failed. Error: \(error)")
                } else if let resultBook = task.result as? Bars {
                    // Update our variable to current value
                    self.numPassesLeft = resultBook._numPassesLeft! as? Int
                    // Here we can also update the label itself
                    DispatchQueue.main.async {
                        self.popupNumPassesLabel.text = "\((resultBook._numPassesLeft! as? Int)!) passes left"
                    }
                }
                return nil
            })
    }
    
    @IBAction func payBtnClicked(_ sender: Any) {
        // First we get the user's unique braintree id
        getUser()
        // Then we can use the results of this to handle payments processing
        dispatchGroup.notify(queue: .main) {
            // Start running the process in the background
            DispatchQueue.global().async {
                // Request the task assertion and save the ID.
                self.backgroundTask = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.backgroundTask!)
                    self.backgroundTask = UIBackgroundTaskIdentifier.invalid
                }
                // Perform the actual task
                self.handleCustomerCreation(userId: self.braintree!)
                self.fetchClientToken()
                
                // End the task assertion.
                UIApplication.shared.endBackgroundTask(self.backgroundTask!)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        }
    }
    
    // Function to handle finding the braintreeId of the current user
    func getUser() {
        // Create a query expression
        self.dispatchGroup.enter()
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        dynamoDbObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
                                    if let error = error {
                                        print("Amazon DynamoDB Read Error: \(error)")
                                        return
                                    }
                                    else if let loadedCustomer = objectModel as? Customer{
                                        self.braintree = loadedCustomer._braintreeId!
                                    }
                                    self.dispatchGroup.leave()
        })
    }
    
    // This function serves to ensure that the customer exists before fetching a client token
    func handleCustomerCreation(userId: NSNumber) {
        let createURL = URL(string: "https://mysterious-brook-47208.herokuapp.com/create")!
        var request = URLRequest(url: createURL)
        // Save the current user in a variable
        // Make the body with the payment_method_nonce and the amount
        request.httpBody = "customerId=\(userId.stringValue)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            // TODO: Handle success or failure
            let _ = String(data: data!, encoding: String.Encoding.utf8)
            }.resume()
    }
    
    // Braintree function for Venmo payments through dropin UI which collects
    // customer's payment information and sends a nonce to your server
    func showDropIn(token: String) {
        let request =  BTDropInRequest()
        request.vaultManager = true
        request.paypalDisabled = true
        let dropIn = BTDropInController(authorization: token, request: request)
        { (controller, result, error) in
            if (error != nil) {
                print("ERROR")
            } else if (result?.isCancelled == true) {
                print("CANCELLED")
            } else if result != nil {
                // STEP 4: Send payment nonce to our server
                // This step acts after the user submits all of their payment info and hits submit
                // When the user hits submit/pay, their information is processed by the Braintree
                // servers and then the servers return a payment nonce, which we can use to pass
                // into the postNonceToServer() function below.
                let cost: Double = 10.99
                // If the user is paying with Venmo, we need to cast their nonce into a BTVenmoAccountNonce
                // and then use the username property instead of the typical card transaction nonce
                if (result!.paymentOptionType.rawValue == 17) {
                    // Check the below line to ensure that the username property of
                    // the VenmoAccountNonce is what should be passed in here
                    self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "", amount: cost, venue: "\(self.barName),\(self.barItemId!)")
                } else {
                    self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "", amount: cost, venue: "\(self.barName),\(self.barItemId!)")
                }
            }
            controller.dismiss(animated: true, completion: nil)
        }
        BTUIKAppearance.darkTheme()
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    // Function to fetch a client token from the server
    func fetchClientToken() {
        // STEP 1: Front-end requests a client token from the server and sets up the client-side SDK
        let clientTokenURL = NSURLComponents(string: "https://mysterious-brook-47208.herokuapp.com/client_token")!
        // Add query items to the GET request to allow data transferring in the form of customerId
        clientTokenURL.queryItems = [URLQueryItem(name: "userId", value: braintree?.stringValue)]
        // Create the URLRequest and downcast the NSURLComponents to a URL
        let clientTokenRequest = URLRequest(url: clientTokenURL.url!)
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            // Present drop in
            self.showDropIn(token: clientToken ?? "nil")
            }.resume()
    }
    
    // This function handles altering the databases when a user purchases a new pass
    func alterDatabase() {
        // First create an instance of the object mapper
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        // This first retreival and write will decrement the number of remaining passes for the given bar
        dynamoDBObjectMapper.load(Bars.self, hashKey: self.barName, rangeKey: self.barItemId).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let resultBar = task.result as? Bars {
                // We can now change the number of passes on the given bar to one less than before
                resultBar._numPassesLeft = Int(truncating: resultBar._numPassesLeft!) - 1 as NSNumber
                // Now that we have retreived the element, we can save it back into the database
                dynamoDBObjectMapper.save(resultBar).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
                    if let error = task.error as NSError? {
                        print("The request failed. Error: \(error)")
                    }
                })
            }
        })
        // This second retreival will increment the number of active passes for the logged in user
        // This first block is handling the retreival of the current customer in the database
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        dynamoDBObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
                                    if let error = error {
                                        print("Amazon DynamoDB Read Error: \(error)")
                                        return
                                    }
                                    else if let customer = objectModel as? Customer {
                                        let newPass: String = self.barName + "," + self.barItemId!
                                        customer._activeTrips?.insert(newPass)
                                        customer._tripsTaken = Int(truncating: customer._tripsTaken!) + 1 as NSNumber
                                        // Now that we have retreived the Customer, we can save it back into the database
                                        dynamoDBObjectMapper.save(customer).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
                                            if let error = task.error as NSError? {
                                                print("The request failed. Error: \(error)")
                                            }
                                        })
                                    }
        })
    }
    
    // Sends the payment nonce to the server via a post request on the /payment-methods route
    func postNonceToServer(paymentMethodNonce: String, amount: Double, venue: String) {
        let paymentURL = URL(string: "https://mysterious-brook-47208.herokuapp.com/payment-methods")!
        var request = URLRequest(url: paymentURL)
        // Handle device data collection
        let deviceData = PPDataCollector.collectPayPalDeviceData()
        // Make the body with the payment_method_nonce and the amount
        request.httpBody = "nonce=\(paymentMethodNonce)&amount=\(amount)&venue=\(venue)&device_data=\(deviceData)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            // TODO: Handle success or failure
            let result = String(data: data!, encoding: String.Encoding.utf8)
            // Show the client their transaction results
            // If the string is empty, we can assume it's false
            let transMessage = (result == "true") ? "Your payment was processed successfully!" : "Oops, something went wrong with your payment, please try again"
            let alert = UIAlertController(title: "Transaction Status", message: transMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            // Now that the user has paid, if the transaction was successful, we
            // can add their new pass to their activePass set and subtract a remaining pass
            // from the selected bar
            if (result == "true") {
                // Continue to perform db operations (back-end) and UI changes to reflect new pass (front-end)
                self.alterDatabase()
                self.updatePasses()
                // Now that the user has bought a pass successfully, we should make sure they
                // don't accidentally buy a second pass and disable the pay button on this screen
                self.popupPayBtn.isEnabled = false
            }
        }.resume()
        // Hide the view
        self.popupView.isHidden = true
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
