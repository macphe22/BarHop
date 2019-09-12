//
//  PayViewController.swift
//  BarHop
//
//  Created by John Landy on 6/8/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import BraintreeDropIn
import Braintree
import AWSDynamoDB
import AWSMobileClient
import AWSCore
import AudioToolbox

class PayViewController: UIViewController {

    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var validUntilLabel: UILabel!
    @IBOutlet weak var barLabel: UITextField!
    @IBOutlet weak var numPassesLabel: UITextField!
    @IBOutlet weak var payBtn: UIButton!
    
    var barUserId: String?
    var barItemId: String?
    var cost: Int?
    var numPassesText: Int?
    var backgroundTask: UIBackgroundTaskIdentifier?
    var braintree: NSNumber?
    var activePasses: Set<String>?
    var userHasPass: Bool = false
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Call function to update how many passes are left over
        updatePasses()
        // Bar label
        let textField = "\(barUserId!), $\(cost!)"
        barLabel.text = textField
        barLabel.textColor = UIColor(white: 1, alpha: 1)
        barLabel.textAlignment = NSTextAlignment.center
        // Pay button
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        payBtn.layer.cornerRadius = 8
        payBtn.layer.borderWidth = 1
        payBtn.layer.borderColor = midBlue.cgColor
        payBtn.titleLabel?.textColor = midBlue
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
        validUntilLabel.text = "Valid until \(mo) \(day) at 2 am"
        validUntilLabel.textColor = UIColor(white: 1, alpha: 1)
        validUntilLabel.textAlignment = NSTextAlignment.center
        // Address label
        addressLabel.text = "\(address!)\n\(city!), \(state!) \(zipCode!)"
        addressLabel.textColor = UIColor(white: 1, alpha: 1)
        addressLabel.textAlignment = NSTextAlignment.center
        // Number of passes label
        if (numPassesText == nil) {
            numPassesLabel.text = "INSERT NUM LEFT"
        } else {
            numPassesLabel.text = "\(numPassesText!) passes left"
        }
        // Change background color of label depending on number of passes left once query figured out
        numPassesLabel.textColor = UIColor(white: 1, alpha: 1)
        numPassesLabel.textAlignment = NSTextAlignment.center
        // Check the user's active passes against the current venue
        checkPasses()
        // Need a dispatch group here because we are querying to check if the user has already gotten a pass here
        dispatchGroup.notify(queue: .main) {
            if (self.numPassesText! == 0) {
                self.payBtn.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                self.payBtn.setTitle("No remaining passes available", for: .normal)
                self.payBtn.setTitleColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1), for: .normal)
                self.payBtn.isEnabled = false
            } else if (self.userHasPass) {
                self.payBtn.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                self.payBtn.setTitle("You have an active pass at this venue", for: .normal)
                self.payBtn.setTitleColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1), for: .normal)
                self.payBtn.isEnabled = false
            }
        }
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
            let passName: String = self.barUserId! + "," + self.barItemId!
            if ((self.activePasses?.contains(passName))!) {
                self.userHasPass = true
            }
            self.dispatchGroup.leave()
        })
    }
    
    // Function that handles updating a Bar's remaining passes
    func updatePasses() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()

        dynamoDBObjectMapper.load(Bars.self, hashKey: barUserId!, rangeKey:
             barItemId).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let resultBook = task.result as? Bars {
                // Update our variable to current value
                self.numPassesText = resultBook._numPassesLeft! as? Int
                // Here we can also update the label itself
                DispatchQueue.main.async {
                    self.numPassesLabel.text = "\((resultBook._numPassesLeft! as? Int)!) passes left"
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
                    self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "", amount: cost, venue: "\(self.barUserId!),\(self.barItemId!)")
                } else {
                    self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "", amount: cost, venue: "\(self.barUserId!),\(self.barItemId!)")
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
        dynamoDBObjectMapper.load(Bars.self, hashKey: self.barUserId!, rangeKey: self.barItemId).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
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
                let newPass: String = self.barUserId! + "," + self.barItemId!
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
                self.payBtn.isEnabled = false
            }
        }.resume()
    }
}
