//
//  RedeemedPopUpViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 1/18/20.
//  Copyright © 2020 Scott Macpherson. All rights reserved.
//

import UIKit

class RedeemedPopUpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.view.layer.cornerRadius = 8
        // Do any additional setup after loading the view.
    }
    

    @IBAction func closePopUp(_ sender: Any) {
        self.view.removeFromSuperview()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
//    func showAnimate()
//    {
//        UIView.animate(withDuration: 0.25, animations: {
//            self.view.transform = __CGAffineTransformMake(1.3, 1.3, 1.3, 1.3, 1.3, 1.3 )
//            self.view.alpha = 0.0
//            UIView.animate(withDuration: <#T##TimeInterval#>, animations: <#T##() -> Void#>)
//        })
//    }

}
