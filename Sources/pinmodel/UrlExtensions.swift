//
//  UrlExtensions.swift
//  pinmodel
//
//  Created by Rahul Malik on 8/25/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


extension URLSession {
    func synchronousDataTaskWithUrl(_ url: URL) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        self.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if response != nil {
                responseData = data
            }
            semaphore.signal()
        } as! (Data?, URLResponse?, Error?) -> Void) .resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return responseData
    }
}
