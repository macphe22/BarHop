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

    override func viewDidLoad() {
        super.viewDidLoad()
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
    func showSignIn() {
        self.viewDidLoad()
    }

    @IBAction func signOutButtonPress(_ sender: Any) {
        print("here")
        AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
            self.showSignIn()
            // print("Sign-out Successful: \(signInProvider.getDisplayName)");
            
        })
    }
    
}

