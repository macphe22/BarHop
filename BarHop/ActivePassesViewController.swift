//
//  ActivePassesViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/30/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit

class ActivePassesViewController: UIViewController {
    @IBOutlet weak var activePassesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        createDataArray()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Outlets



    
    //Mark: - Data
    var activePasses = [String]()
    
    func createDataArray(){
        activePasses = ["Harpers", "Ricks", "Pt O'Malies"]
    }

}
extension ActivePassesViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activePasses.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Constructing tableView rows now")
        let cellIdentifier = "ActivePassTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ActivePassTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        let activePass = activePasses[indexPath.row]
        // Configure the cell...
        cell.barNameLabel.text = activePass
        
        return cell
    }
}
