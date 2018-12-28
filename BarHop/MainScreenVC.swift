//
//  MainScreenVC.swift
//  BarHop
//
//  Created by John Landy on 12/23/18.
//  Copyright © 2018 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSAuthUI

class MainScreenVC: UIViewController {
    
    private var profileOpen: Bool = false

    @IBOutlet weak var ProfLeftEdge: NSLayoutConstraint!
    
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
             print("here")
        }
    }
    func showSignIn() {
        self.viewDidLoad()
    }
    
    @IBAction func ClickedProfile(_ sender: UIBarButtonItem) {
        if (profileOpen) {
            ProfLeftEdge.constant = -260;
        } else {
            ProfLeftEdge.constant = 0;
        }
        profileOpen = !profileOpen;
    }
    
//@IBAction func signOutButtonPress(_ sender: Any) {
        //print("here")
        //AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
        //self.showSignIn()
        // print("Sign-out Successful: \(signInProvider.getDisplayName)");
        
    //})
    //}
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
