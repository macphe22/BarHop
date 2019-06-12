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
        let darkPurple = UIColor(red: 54/255, green: 33/255, blue: 62/255, alpha: 1)
        let midPurple = UIColor(red: 85/255, green: 73/255, blue: 113/255, alpha: 1)
        let dullBlue = UIColor(red: 99/255, green: 118/255, blue: 141/255, alpha: 1)
        let dullSkyBlue = UIColor(red: 138/255, green: 198/255, blue: 208/255, alpha: 1)
        
        findBarBtn.layer.cornerRadius = 8
        findBarBtn.layer.borderWidth = 1
        findBarBtn.backgroundColor = darkPurple
        findBarBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        findBarBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        activePassesBtn.layer.cornerRadius = 8
        activePassesBtn.layer.borderWidth = 1
        activePassesBtn.backgroundColor = midPurple
        activePassesBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        activePassesBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        registerBarBtn.layer.cornerRadius = 8
        registerBarBtn.layer.borderWidth = 1
        registerBarBtn.backgroundColor = dullBlue
        registerBarBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        registerBarBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        signOutBtn.layer.cornerRadius = 8
        signOutBtn.layer.borderWidth = 1
        signOutBtn.backgroundColor = dullSkyBlue
        signOutBtn.layer.borderColor = UIColor(white: 1, alpha: 1).cgColor
        signOutBtn.titleLabel?.textColor = UIColor(white: 1, alpha: 1)
        // Do any additional setup after loading the view, typically from a nib.
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            presentAuthUIViewController()
        }
    }
    
    func presentAuthUIViewController() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        let darkPurple = UIColor(red: 54/255, green: 33/255, blue: 62/255, alpha: 1)
        config.backgroundColor = darkPurple
        config.isBackgroundColorFullScreen = true
        config.logoImage = UIImage(named: "beer-2424943_960_720")
        
        AWSAuthUIViewController.presentViewController(
            with: self.navigationController!,
            configuration: config, completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                if error == nil {
                    // SignIn succeeded.
                } else {
                    // end user faced error while loggin in, take any required action here.
                }
        })
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

