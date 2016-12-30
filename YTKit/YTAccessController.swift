//
//  YTAccessController.swift
//  YTKit
//
//  Created by Carlos Grossi on 12/7/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTAccessController {
    
    open static let standardController = YTAccessController()
    open var apiKey:String
    
    public init(apiKey:String) {
        self.apiKey = apiKey
    }
    
    public convenience init() {
        self.init(apiKey:"")
    }
    
    

}
