//
//  ActivePassTableViewCell.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/25/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class ActivePassTableViewCell: UITableViewCell {
    //MARK: Properties
    
    @IBOutlet weak var barLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
