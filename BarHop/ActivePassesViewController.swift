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
    
    @IBOutlet weak var tableView: UITableView!
    
    var activePasses = [String]()
    var returnedActivePasses = Set<String>()
    var passAddress: String?
    
    private let refreshControl = UIRefreshControl()
    
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Add a refresh by pull-down method
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Data ...")
        // First we call our query
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main)
        {
            self.displayPasses()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // First we call our query
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main)
        {
            self.displayPasses()
        }
    }
    
    // Selector function for updating pull-down
    @objc private func refreshData(_ sender: Any) {
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main)
        {
            self.displayPasses()
            self.refreshControl.endRefreshing()
        }
    }
    
    // This function handles local reloads of data
    func displayPasses() {
        self.tableView?.reloadData()
    }
    
    func getCustomersActiveTrips(){
        // Create a query expression
        self.dispatchGroup.enter()
        var returnedPasses = [String]()
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let customerItem: Customer = Customer();
        customerItem._userId = AWSIdentityManager.default().identityId
        customerItem._tripsTaken = 0
        dynamoDbObjectMapper.load(Customer.self, hashKey: customerItem._userId!,
                                  rangeKey: nil, completionHandler: {
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
    
    func getPassCity(barUserId: String, barItemId: String) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        self.dispatchGroup.enter()
        dynamoDBObjectMapper.load(Bars.self, hashKey: barUserId, rangeKey:
            barItemId).continueWith(block: { (task:AWSTask<AnyObject>!) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let resultBook = task.result as? Bars {
                self.passAddress = "\(resultBook._city!), \(resultBook._state!)"
            }
            self.dispatchGroup.leave()
        })
    }
}

extension ActivePassesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activePasses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ActivePassTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ActivePassTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        let activePass = activePasses[indexPath.row]
        // Configure the cell...
        // The active pass id has both the range key and the hash key, but we only want
        // to display the hash key to the user
        cell.backgroundColor = UIColor(white: 0, alpha: 1)
        cell.barNameLabel.textColor = UIColor(white: 1, alpha: 1)
        cell.barNameLabel.text = activePass.components(separatedBy: ",")[0]
        cell.barUniqueId = activePass
        // Also, we would like to display the city to the user as well which requires a query
        getPassCity(barUserId: activePass.components(separatedBy: ",")[0], barItemId: activePass.components(separatedBy: ",")[1])
        dispatchGroup.notify(queue: .main)
        {
            cell.barAddressLabel.textColor = UIColor(white: 1, alpha: 1)
            cell.barAddressLabel.text = self.passAddress
        }
        return cell
    }
}
