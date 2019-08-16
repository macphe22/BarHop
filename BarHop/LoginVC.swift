//
//  ViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 12/23/18.
//  Copyright © 2018 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSDynamoDB
import AWSMobileClient

 class LoginVC: UIViewController {
    
    @IBOutlet weak var findBarBtn: UIButton!
    @IBOutlet weak var activePassesBtn: UIButton!
    @IBOutlet weak var registerBarBtn: UIButton!
    @IBOutlet weak var signOutBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Button stuff
        findBarBtn.layer.cornerRadius = 8
        findBarBtn.layer.borderWidth = 1
        findBarBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        findBarBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        activePassesBtn.layer.cornerRadius = 8
        activePassesBtn.layer.borderWidth = 1
        activePassesBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        activePassesBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        registerBarBtn.layer.cornerRadius = 8
        registerBarBtn.layer.borderWidth = 1
        registerBarBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        registerBarBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        signOutBtn.layer.cornerRadius = 8
        signOutBtn.layer.borderWidth = 1
        signOutBtn.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
        signOutBtn.titleLabel?.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        // Do any additional setup after loading the view, typically from a nib.
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            presentAuthUIViewController()
        }
    }
    
    func presentAuthUIViewController() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        config.backgroundColor = UIColor(white: 0, alpha: 1)
        config.isBackgroundColorFullScreen = true
        config.logoImage = UIImage(named: "beer-2424943_960_720")
        
        AWSAuthUIViewController.presentViewController(
            with: self.navigationController!,
            configuration: config, completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                if error == nil {
                    // SignIn succeeded.
                    self.createCustomer()
                } else {
                    // end user faced error while loggin in, take any required action here.
                }
        })
    }
    

    @IBAction func signOutBtnPressed(_ sender: Any) {
        AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
            self.viewDidLoad()
            //self.presentAuthUIViewController()
            // print("Sign-out Successful: \(signInProvider.getDisplayName)");
        })
    }
    
    // Creating a new customer
    func createCustomer(){
        //print("Creating Customer")
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let newCust:Customer = Customer()
        //initialize values for attributes for new customer
        let barSet: Set<String> = ["Harpers"]
        newCust._userId = AWSIdentityManager.default().identityId //_userId represents the partition key
        newCust._tripsTaken = 0
        newCust._activeTrips = barSet
        //Save a new item
        dynamoDbObjectMapper.save(newCust, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
    }
    
}

