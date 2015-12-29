//
//  UrlExtensions.swift
//  pinmodel
//
//  Created by Rahul Malik on 8/25/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


extension NSURLSession {
    func synchronousDataTaskWithUrl(url: NSURL) -> NSData? {
        let semaphore = dispatch_semaphore_create(0)
        var responseData: NSData?
        self.dataTaskWithURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if response != nil {
                responseData = data
            }
            dispatch_semaphore_signal(semaphore)
        }.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return responseData
    }
}
