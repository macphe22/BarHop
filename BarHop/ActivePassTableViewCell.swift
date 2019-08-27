//
//  ActivePassTableViewCell.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/25/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSMobileClient

class ActivePassTableViewCell: UITableViewCell {
    
    @IBOutlet weak var barAddressLabel: UILabel!
    @IBOutlet weak var barNameLabel: UILabel!
    @IBOutlet weak var redeemBtn: UIButton!
    
    var barUniqueId: String?
    var ActivePassVC = ActivePassesViewController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        redeemBtn.titleLabel?.textColor = midBlue
        redeemBtn.layer.borderWidth = 1
        redeemBtn.layer.borderColor = midBlue.cgColor
        redeemBtn.layer.cornerRadius = 5
    }
    
    // Handle the redeem button being clicked
    // We must both remove the pass from the user's profile, and in real-time,
    // remove the pass from the table view
    @IBAction func redeemBtnClicked(_ sender: Any) {
        // This retreival will decrement the number of active passes for the logged in user
        // This first block is handling the retreival of the current customer in the database
        let customerItem: Customer = Customer()
        let uniqueId = self.barUniqueId!
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
                if (((customer._activeTrips?.contains(uniqueId))!)) {
                    customer._activeTrips?.remove(uniqueId)
                }
                // Now that we have retreived the Customer, we can save it back into the database
                dynamoDBObjectMapper.save(customer).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
                    if let error = task.error as NSError? {
                        print("The request failed. Error: \(error)")
                    }
                })
            }
        })
    }
}
