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
        findBarBtn.layer.borderColor = UIColor.white.cgColor
        activePassesBtn.layer.cornerRadius = 8
        activePassesBtn.layer.borderWidth = 1
        activePassesBtn.layer.borderColor = UIColor.white.cgColor
        registerBarBtn.layer.cornerRadius = 8
        registerBarBtn.layer.borderWidth = 1
        registerBarBtn.layer.borderColor = UIColor.white.cgColor
        signOutBtn.layer.cornerRadius = 8
        signOutBtn.layer.borderWidth = 1
        signOutBtn.layer.borderColor = UIColor.white.cgColor
        // Do any additional setup after loading the view, typically from a nib.
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            AWSAuthUIViewController
                .presentViewController(with: self.navigationController!,
                                       configuration: nil,
                                       completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                                        if error != nil {
                                            print("Error occurred: \(String(describing: error))")
                                        } else {
                                            // Sign in successful.
                                        }
                })
        }
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        if !AWSSignInManager.sharedInstance().isLoggedIn {
//            presentAuthUIViewController()
//        }
//    }
    
//    func presentAuthUIViewController() {
//        let config = AWSAuthUIConfiguration()
//        config.enableUserPoolsUI = true
//        //config.addSignInButtonView(class: AWSFacebookSignInButton.self)
//        //config.addSignInButtonView(class: AWSGoogleSignInButton.self)
//
//        //change the logo on the UI here
//        //config.logoImage =
//        config.backgroundColor = UIColor.white
//        config.font = UIFont (name: "Helvetica Neue", size: 15)
//        config.isBackgroundColorFullScreen = true
//        config.canCancel = true
//
//
//        AWSAuthUIViewController.presentViewController(
//            with: self.navigationController!,
//            configuration: config, completionHandler: { (provider: AWSSignInProvider, error: Error?) in
//                if error == nil {
//                    // SignIn succeeded.
//                    self.createCustomer()
//                } else {
//                    // end user faced error while loggin in, take any required action here.
//                }
//        })
//    }

    @IBAction func signOutBtnPressed(_ sender: Any) {
        AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
            self.viewDidLoad()
            //self.presentAuthUIViewController()
            // print("Sign-out Successful: \(signInProvider.getDisplayName)");
        })
    }
   
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let identifier = segue.identifier {
//            switch identifier{
//            case "show register":
//                    if let vc = segue.destination as? UIViewController {
//                        print("true")
//
//                }
//            default: break
//            }
//        }
//    }
    
    // Creating a new customer
    func createCustomer(){
        print("Creating Customer")
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let newCust:Customer = Customer()
        //initialize values for attributes for new customer
        let barSet: Set<String> = ["Harpers"]
        newCust._userId = AWSIdentityManager.default().identityId
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

