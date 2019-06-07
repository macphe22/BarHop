//
//  ActivePasses.swift
//  BarHop
//
//  Created by John Landy on 5/7/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSCore

class ActivePasses: UIViewController {
    
    var activePasses: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Function to handle queries to the Customer database
    func getQuery() {
        // Create a query expression
        let queryExpression = AWSDynamoDBQueryExpression()

        
    }
    
    // Function to initialize the array with all of the user's active passes
    func createArray() -> [String] {
        // Initial temp variable to be returned
        let temp: [String] = []
        
        // Look through the AWS table to find passes
        // What we need to do here is first find the customer based on the logged
        // in user. Then we must return all of their active trips from the JSON
        // that will be returned in their jsonKeyPathsByPropertyKey() function.
        // Once we find each active pass in this JSON, we will append it to the
        // temp array
        
        
        
        
        // Now we can return the array
        return temp
    }

    
}
