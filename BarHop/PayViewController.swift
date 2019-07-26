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

class PayViewController: UIViewController {

    @IBOutlet weak var barLabel: UITextField!
    @IBOutlet weak var numPassesLabel: UITextField!
    @IBOutlet weak var payBtn: UIButton!
    @IBOutlet weak var disclaimerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Bar label
        barLabel.text = "INSERT BAR CLICKED ON"
        barLabel.textColor = UIColor(white: 1, alpha: 1)
        barLabel.textAlignment = NSTextAlignment.center
        // Number of passes label
        numPassesLabel.text = "INSERT NUM LEFT"
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
        disclaimerLabel.text = "INSERT DISCLAIMER"
        disclaimerLabel.textColor = UIColor(white: 1, alpha: 1)
        disclaimerLabel.textAlignment = NSTextAlignment.center
    }
    
    @IBAction func payBtnClicked(_ sender: Any) {
        fetchClientToken()
    }
    
    // Braintree function for Venmo payments through dropin UI which collects
    // customer's payment information and sends a nonce to your server
    func showDropIn(token: String) {
        let request =  BTDropInRequest()
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
                let cost = 12.99 // QUERY NEEDED HERE
                self.postNonceToServer(paymentMethodNonce: result?.paymentMethod?.nonce ?? "fake-valid-nonce", amount: cost)
                print(result?.paymentMethod?.nonce as Any);
            }
            controller.dismiss(animated: true, completion: nil)
        }
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    // Function to fetch a client token from the server
    func fetchClientToken() {
        // STEP 1: Front-end requests a client token from the server and sets up the client-side SDK
        let clientTokenURL = NSURL(string: "https://mysterious-brook-47208.herokuapp.com/client_token")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle errors
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            // Dark mode
            BTUIKAppearance.darkTheme()
            // Present drop in
            self.showDropIn(token: clientToken ?? "nil")
        }.resume()
    }
    
    // Sends the payment nonce to the server via a post request on the /payment-methods route
    func postNonceToServer(paymentMethodNonce: String, amount: Double) {
        let paymentURL = URL(string: "https://mysterious-brook-47208.herokuapp.com/payment-methods")!
        var request = URLRequest(url: paymentURL)
        // Make the body with the payment_method_nonce and the amount
        request.httpBody = "payment_method_nonce=\(paymentMethodNonce)&amount=\(amount)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            // TODO: Handle success or failure
        }.resume()
    }
}
