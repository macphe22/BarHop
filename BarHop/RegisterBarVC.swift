//
//  RegisterBarVC.swift
//  BarHop
//
//  Created by Scott Macpherson on 1/6/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class RegisterBarVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    //Textfields below
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var ownerName: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var zip: UITextField!
    @IBOutlet weak var maxTicketsPerNight: UITextField!
    @IBOutlet weak var ticketCost: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var venmoUsername: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Insert a row into the aws database for bars when submit is clicked
    @IBAction func submitClicked(_ sender: Any) {
        // First we need to verify all user info
        // Check that the maxTickets and ticketCost are above zero
        while true {
            var correct = true
            let maxTickets = Int(maxTicketsPerNight.text!)
            let cost = Int(ticketCost.text!)
            if maxTickets! < 0 {
                maxTicketsPerNight.text = ""
                correct = false
                // Show the error message
                errorLabel.isHidden = false
            }
            if cost! < 0 {
                ticketCost.text = ""
                correct = false
                // Show the error message
                errorLabel.isHidden = false
            }
            // If max tickets and cost check out, we can break from the loop
            if correct == true {
                errorLabel.isHidden = true
                break
            }
        }
        
        // Now we know that the parameters are (likely) correct, we will instantiate a row in our table and insert it with all of the bars information
        
        
        
        
    }
}
