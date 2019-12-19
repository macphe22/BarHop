//
//  RedeemPassViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 12/18/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class RedeemPassViewController: UIViewController {
    var barName: String? = ""
    @IBAction func redeemButton(_ sender: UIButton) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createBarNameLabel()
        self.createDisclaimerLabel()
        self.view.backgroundColor = UIColor.black
        self.redeemButtonOutlet.layer.cornerRadius = 8
        self.redeemButtonOutlet.layer.borderWidth = 1
        self.redeemButtonOutlet.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var redeemButtonOutlet: UIButton!
    @IBOutlet weak var barNameLabel: UILabel!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    func createDisclaimerLabel() -> Void{
        self.instructionLabel.text = "After presenting valid ID to bouncer, please press redeem button"
        self.instructionLabel.textAlignment = .center
        self.instructionLabel.textColor = .white
        self.instructionLabel.numberOfLines = 0
//        self.instructionLabel.font = instructionLabel.font.withSize()
    }
    
    func createBarNameLabel() -> Void{
        if self.barName != nil{
            self.barNameLabel.text = self.barName
        }
        self.barNameLabel.font = barNameLabel.font.withSize(25)
        self.barNameLabel.textAlignment = .center
        self.barNameLabel.textColor = .white
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
