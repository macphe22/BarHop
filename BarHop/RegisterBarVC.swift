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
        print("register view loaded")
        
        // Do any additional setup after loading the view.
    }
    //Textfields below
    
    @IBOutlet weak var bar_name: UITextField!
    @IBOutlet weak var ownersName: UITextField!

    @IBOutlet weak var phoneNumber: UITextField!
    
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var maxCapacity: UITextField!
    @IBOutlet weak var accountNumber: UITextField!
    
    @IBOutlet weak var ticketPrice: UITextField!
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
