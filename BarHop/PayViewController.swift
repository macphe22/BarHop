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

class PayViewController: UIViewController {

    @IBOutlet weak var barLabel: UITextField!
    @IBOutlet weak var numPassesLabel: UITextField!
    @IBOutlet weak var payBtn: UIButton!
    @IBOutlet weak var disclaimerLabel: UILabel!
    
    var barName: String?
    var cost: Int?
    var numPassesText: String?
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Bar label
        let textField = "\(barName!), $\(cost!)"
        barLabel.text = textField
        barLabel.textColor = UIColor(white: 1, alpha: 1)
        barLabel.textAlignment = NSTextAlignment.center
        // Number of passes label
        if (numPassesText == nil) {
            numPassesLabel.text = "INSERT NUM LEFT"
        } else {
            numPassesLabel.text = "\(numPassesText!) passes left"
        }
        // Change background color of label depending on number of passes left once query figured out
        numPassesLabel.textColor = UIColor(white: 1, alpha: 1)
        numPassesLabel.textAlignment = NSTextAlignment.center
        // Pay button
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        payBtn.layer.cornerRadius = 8
        payBtn.layer.borderWidth = 1
        payBtn.layer.borderColor = midBlue.cgColor
        payBtn.titleLabel?.textColor = midBlue
        // Disclaimer Label
        disclaimerLabel.text = "BarHop is not responsible for your entry into this venue; our services solely serve to reduce your time waiting in line. It is up to staff at each venue whether or not to permnit your entry, regardless of your legal ability to enter. Please drink responsibly."
        disclaimerLabel.textColor = UIColor(white: 1, alpha: 1)
        disclaimerLabel.textAlignment = NSTextAlignment.center
    }
    
    @IBAction func payBtnClicked(_ sender: Any) {
        // Start running the process in the background
        DispatchQueue.global().async {
            // Request the task assertion and save the ID.
            self.backgroundTask = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
                // End the task if time expires.
                UIApplication.shared.endBackgroundTask(self.backgroundTask!)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
            // Perform the actual task
            self.handleCustomerCreation(userId: self.getUser())
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(self.backgroundTask!)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
        // Start running the process in the background
        DispatchQueue.global().async {
            // Request the task assertion and save the ID.
            self.backgroundTask = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
                // End the task if time expires.
                UIApplication.shared.endBackgroundTask(self.backgroundTask!)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
            // Perform the actual task
            self.fetchClientToken()
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(self.backgroundTask!)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // Function to handle finding the current user
    func getUser() -> String {
        var userId: String = AWSIdentityManager.default().identityId!
        userId = userId.components(separatedBy: ":")[1] // Remove beginning
        return userId
    }
    
    // This function serves to ensure that the customer exists before fetching a client token
    func handleCustomerCreation(userId: String) {
        let createURL = URL(string: "https://mysterious-brook-47208.herokuapp.com/create")!
        var request = URLRequest(url: createURL)
        // Save the current user in a variable
        // Make the body with the payment_method_nonce and the amount
        let userId: String = getUser()
        request.httpBody = "customerId=\(userId)".data(using: String.Encoding.utf8)
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
                let cost: Double = 10.99 // QUERY NEEDED HERE
                // If the user is paying with Venmo, we need to cast their nonce into a BTVenmoAccountNonce
                // and then use the username property instead of the typical card transaction nonce
                if (result!.paymentOptionType.rawValue == 17) {
                    let nonce = result?.paymentMethod as! BTVenmoAccountNonce
                    // Check the below line to ensure that the username property of
                    // the VenmoAccountNonce is what should be passed in here
                    self.postNonceToServer(paymentMethodNonce: nonce.username ?? "", amount: cost, venue: self.barName ?? "unknown")
                } else {
                    self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "", amount: cost, venue: self.barName ?? "unknown")
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
        clientTokenURL.queryItems = [URLQueryItem(name: "userId", value: getUser())]
        // Create the URLRequest and downcast the NSURLComponents to a URL
        let clientTokenRequest = URLRequest(url: clientTokenURL.url!)
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            // Present drop in
            self.showDropIn(token: clientToken ?? "nil")
        }.resume()
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
        }.resume()
    }
}
