//
//  MainScreenVC.swift
//  BarHop
//
//  Created by John Landy on 12/23/18.
//  Copyright © 2018 Scott Macpherson. All rights reserved.
//

import UIKit

class MainScreenVC: UIViewController {
    
    private var profileOpen: Bool = false

    @IBOutlet weak var ProfLeftEdge: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProfLeftEdge.constant = -260;
        // Do any additional setup after loading the view.
    }
    
    @IBAction func ClickedProfile(_ sender: UIBarButtonItem) {
        if (profileOpen) {
            ProfLeftEdge.constant = -260;
        } else {
            ProfLeftEdge.constant = 0;
        }
        profileOpen = !profileOpen;
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
