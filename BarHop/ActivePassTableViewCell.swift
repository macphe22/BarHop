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
        redeemBtn.setTitleColor(.white, for: .normal)
        redeemBtn.layer.backgroundColor = UIColor(ciColor: .blue).cgColor
        redeemBtn.layer.cornerRadius = 5
    }
    
    // Handle the redeem button being clicked
    // We must both remove the pass from the user's profile, and in real-time,
    // remove the pass from the table view
    @IBAction func redeemBtnClicked(_ sender: Any) {
        let tableView = ActivePassesViewController()
        tableView.redeemPass(bar: barUniqueId!, index: indexPath!)
    }
}

// Extension used for finding parent of an object
extension UIResponder {
    func next<T: UIResponder>(_ type: T.Type) -> T? {
        return next as? T ?? next?.next(type)
    }
}

// UITableViewCell extension
extension UITableViewCell {
    
    var tableView: UITableView? {
        return next(UITableView.self)
    }
    
    var indexPath: IndexPath? {
        return tableView?.indexPath(for: self)
    }
}
