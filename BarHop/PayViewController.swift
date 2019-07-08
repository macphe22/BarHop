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
        let darkPurple = UIColor(red: 54/255, green: 33/255, blue: 62/255, alpha: 1)
        barLabel.text = "INSERT BAR CLICKED ON"
        barLabel.backgroundColor = darkPurple
        barLabel.textColor = UIColor(white: 1, alpha: 1)
        barLabel.textAlignment = NSTextAlignment.center
        // Number of passes label
        numPassesLabel.text = "INSERT NUM LEFT"
        // Change background color of label depending on number of passes left once query figured out
        numPassesLabel.textColor = UIColor(white: 1, alpha: 1)
        numPassesLabel.backgroundColor = darkPurple
        numPassesLabel.textAlignment = NSTextAlignment.center
        // Pay button
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        payBtn.layer.cornerRadius = 8
        payBtn.layer.borderWidth = 1
        payBtn.layer.backgroundColor = midBlue.cgColor
        payBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        // Disclaimer Label
        disclaimerLabel.text = "INSERT DISCLAIMER"
        disclaimerLabel.textColor = UIColor(white: 1, alpha: 1)
        disclaimerLabel.textAlignment = NSTextAlignment.center
    }
    
    @IBAction func payBtnClicked(_ sender: Any) {
        fetchClientToken()
    }
    // Braintree function for Venmo payments through dropin UI which collects
    // customer's payment information and sends a nonce to your server (AWS?)
    func showDropIn(clientTokenOrTokenizationKey: String) {
        let request =  BTDropInRequest()
        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: request)
        { (controller, result, error) in
            if (error != nil) {
                print("ERROR")
            } else if (result?.isCancelled == true) {
                print("CANCELLED")
            } else if let result = result {
                // Use the BTDropInResult properties to update your UI
                // result.paymentOptionType
                // result.paymentMethod
                // result.paymentIcon
                // result.paymentDescription
            }
            controller.dismiss(animated: true, completion: nil)
        }
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    // Function to fetch a client token from the server
    func fetchClientToken() {
        // TODO: Switch this URL to your own authenticated API
        let clientTokenURL = NSURL(string: "https://braintree-sample-merchant.herokuapp.com/client_token")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle errors
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            // Dark mode
            BTUIKAppearance.darkTheme()
            // As an example, you may wish to present Drop-in at this point.
            // Continue to the next section to learn more...
            self.showDropIn(clientTokenOrTokenizationKey: clientToken ?? "nil")
            }.resume()
    }
}
