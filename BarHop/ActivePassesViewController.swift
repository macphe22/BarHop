//
//  ActivePassesViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/30/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSAuthCore


class ActivePassesViewController: UIViewController {
    
    @IBOutlet weak var activePassesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getCustomersActiveTrips()
        dispatchGroup.notify(queue: .main)
        {
            self.displayPasses()
        }
    }
    
    func displayPasses(){
        self.tableView?.reloadData();
    }

    //Mark: - Data
    var activePasses = [String]()
    var returnedActivePasses = Set<String>();
    
    func createDataArray(){
        activePasses = ["Harpers", "Ricks", "Pt O'Malies"]
    }
    
    func getCustomersActiveTrips(){
        // Create a query expression
        self.dispatchGroup.enter()
        var returnedPasses = [String]()
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        customerItem._tripsTaken = 0
        dynamoDbObjectMapper.load(Customer.self, hashKey: customerItem._userId,
                                  rangeKey: customerItem._tripsTaken, completionHandler: {
                                    (objectModel: AWSDynamoDBObjectModel?, error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Read Error: \(error)")
                return
            }
            else if let loadedCustomer = objectModel as? Customer{
                
                self.returnedActivePasses = loadedCustomer._activeTrips ?? Set<String>()
                //print(self.returnedActivePasses)
                returnedPasses = self.mapReturnedActivePassesToActivePassesArray();
                self.activePasses = returnedPasses
            }
            print("An item was read")
            self.dispatchGroup.leave()
        })
    }
    
    func mapReturnedActivePassesToActivePassesArray() -> [String]{
        var returnArray = [String]();
        for activePass in self.returnedActivePasses{
            // We must take into account the constant string
            if (activePass != "EMPTY_STRING") {
                returnArray.append(activePass);
            }
        }
        
        return returnArray
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
