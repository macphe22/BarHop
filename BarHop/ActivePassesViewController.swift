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
    
    @IBOutlet var tableView: UITableView! = UITableView()
    
    var activePasses = [String]()
    var returnedActivePasses = Set<String>()
    var passAddress: String?
    
    private let refreshControl = UIRefreshControl()
    
    let dispatchGroup = DispatchGroup()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationViewController = segue.destination as! RedeemPassViewController
//        print((type(of: sender)))
        
//        print("here")
        let activePassTableViewCell = sender as! ActivePassTableViewCell
        destinationViewController.barName = activePassTableViewCell.barNameLabel.text
        destinationViewController.barUniqueId = activePassTableViewCell.barUniqueId
        
    }
    
    override func viewDidLoad() {
        self.tableView.allowsSelection = true
        super.viewDidLoad()
        // Set up navigation bar logo
        let logoImage = UIImage(named: "NavBarLogo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        logoImageView.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoImageView)
        // Handle table view delegation
        tableView.delegate = self
        tableView.dataSource = self
        // Add a refresh by pull-down method
        tableView.refreshControl = refreshControl
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        // First we call our query
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main) {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // First we call our query
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main) {
            self.tableView?.reloadData()
        }
    }
    
    // Selector function for updating pull-down
    @objc private func refreshData(_ sender: Any) {
        getCustomersActiveTrips()
        // Then when we exit the dispatch group, we can display the passes retrieved
        dispatchGroup.notify(queue: .main) {
            self.tableView?.reloadData()
            self.refreshControl.endRefreshing()
        }
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
    
    // Function to organize codebase for removing a pass from the user
    func redeemPass(bar: String, index: IndexPath) {
        // Alter the database
        alterDB(bar: bar)
        // Once the database returns our results, use them to reload our data
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    // Function to handle remove pass from the database
    func alterDB(bar: String) {
        // This retreival will decrement the number of active passes for the logged in user
        // This first block is handling the retreival of the current customer in the database
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
                                        if (((customer._activeTrips?.contains(bar))!)) {
                                            customer._activeTrips?.remove(bar)
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) else { return }
//        self.performSegue(withIdentifier: "redeemPassViewControllerSegue", sender: cell)
    }
}
