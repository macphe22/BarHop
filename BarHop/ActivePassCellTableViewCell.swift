//
//  ActivePassCellTableViewCell.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/1/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class ActivePassCellTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var barLabel: UILabel!
    
    func setActivePassLabel(bar: String){
        //print(bar)
        barLabel?.text = bar;
        
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
