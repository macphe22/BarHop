//
//  RedeemPassViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 12/18/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSAuthUI
import AWSDynamoDB
class RedeemPassViewController: UIViewController {
    var barName: String? = ""
    let dispatchGroup = DispatchGroup()
    @IBAction func redeemButton(_ sender: UIButton) {
        // removePassFromCustomer(bar: barName!)
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "redeemedPopUpID") as! RedeemedPopUpViewController
        self.addChild(popOverVC)
        popOverVC.view.frame = self.view.frame
        
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParent: self)
        
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
    
    func removePassFromCustomer(bar: String)
    {
        // This retreival will decrement the number of active passes for the logged in user
        // This first block is handling the retreival of the current customer in the database
        print(bar)
        self.dispatchGroup.enter()
        let customerItem: Customer = Customer()
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        customerItem._userId = AWSIdentityManager.default().identityId
        dynamoDBObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
                                    if let error = error {
                                        print("Amazon DynamoDB Read Error: \(error)")
                                        return
                                    }
                                    else if let customer = objectModel as? Customer {
                                        // We can now remove the active pass from the customer
                                        print(customer._activeTrips ?? Set<String>())
                                        if (((customer._activeTrips?.contains(bar))!)) {
                                            customer._activeTrips?.remove(bar)
//                                            print(customer._activeTrips ?? Set<String>())
                                        }
                                        // Now that we have retreived the Customer, we can save it back into the database
                                        dynamoDBObjectMapper.save(customer).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
                                            if let error = task.error as NSError? {
                                                print("The request failed. Error: \(error)")
                                            }
                                        })
                                        self.dispatchGroup.leave()
                                    }
        })
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
