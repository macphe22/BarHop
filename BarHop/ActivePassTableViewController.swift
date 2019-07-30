//
//  ActivePassTableViewController.swift
//  BarHop
//
//  Created by Scott Macpherson on 7/25/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSAuthCore

class ActivePassTableViewController: UITableViewController {
    //MARK: Properties
    var activePasses = [String]()
    var returnedActivePasses = Set<String>()
    
    //MARK: Private Methods
    private func loadActivePasses() {
        self.activePasses = ["Harpers", "Ricks", "Lou Harry's"]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCustomersActiveTrips()
        print(activePasses)
        //loadActivePasses()
        print("In view did load")
        
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return activePasses.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("here")
        let cellIdentifier = "ActivePassTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ActivePassTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        let activePass = activePasses[indexPath.row]
        // Configure the cell...
        cell.barLabel.text = activePass
        
        return cell
    }
    
    func getCustomersActiveTrips(){
        // Create a query expression
        var returnedPasses = [String]();
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        customerItem._tripsTaken = 0
        dynamoDbObjectMapper.load(Customer.self,
                                  hashKey: customerItem._userId,
                                  rangeKey: customerItem._tripsTaken,
                                  completionHandler: {
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
                                    
        })
        
        
        
        
    }
    
    func mapReturnedActivePassesToActivePassesArray() -> [String]{
        var returnArray = [String]();
        for activePass in self.returnedActivePasses{
            returnArray.append(activePass);
            
        }
        
        return returnArray
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
