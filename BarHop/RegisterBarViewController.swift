//
//  RegisterBarViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 8/16/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class RegisterBarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func submitAction(_ sender: Any) {
        forwardGeoCoding(state: state.text!, city: city.text!, streetAddress: streetAddress.text!)
    }
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var streetAddress: UITextField!
    @IBOutlet weak var city: UITextField!
    
    func forwardGeoCoding(state: String, city: String, streetAddress: String) -> Void {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
