//
//  Bars.swift
//  MySampleApp
//
//
// Copyright 2018 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.21
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers class Bars: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId: String?
    var _itemId: String?
    var _category: String?
    var _latitude: NSNumber?
    var _longitude: NSNumber?
    var _maxCapacity: NSNumber?
    var _numPassesLeft: NSNumber?
    var _name: String?
    var _ownersName: String?
    var _phoneNumber: String?
    var _price: NSNumber?
    
    class func dynamoDBTableName() -> String {

        return "barhop-mobilehub-1353656554-Bars"
    }
    
    class func hashKeyAttribute() -> String {

        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {

        return "_itemId"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_userId" : "userId",
               "_itemId" : "itemId",
               "_category" : "category",
               "_latitude" : "latitude",
               "_longitude" : "longitude",
               "_maxCapacity" : "max_capacity",
               "_numPassesLeft" : "numPassesLeft",
               "_name" : "name",
               "_ownersName" : "owners_name",
               "_phoneNumber" : "phone_number",
               "_price" : "price",
        ]
    }
}

