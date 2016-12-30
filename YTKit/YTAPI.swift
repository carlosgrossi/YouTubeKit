//
//  YTAPI.swift
//  YTKit
//
//  Created by Carlos Grossi on 1/8/16.
//  Copyright © 2016 Carlos Grossi. All rights reserved.
//

import Foundation

open class YTAPI {
    open var apiKey:String
    
    public init(apiKey:String) {
        self.apiKey = apiKey
    }
    
    public convenience init() {
        self.init(apiKey:"")
    }
}
