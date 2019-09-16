//
//  UTMockedObjects.swift
//  PhotoBrowserUnitTests
//
//  Created by Matthew Certain on 9/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation

// This specialized version of the AbstractEndpointRequestTask mocks the functionality of the one
// used during production/normal operations. The difference is that this version loads data from
// JSON files that mimics what would come from the backend server.
class MockedEndpointRequestTask: AbstractEndpointRequestTask {
    private var urlRequested: URL?
    
    // Just like the product executeRequest except it sources data locally from the file system vs.
    // remotely from a backend server
    func executeRequest(with endpointDescriptor: EndpointDescriptorBase, responseHandler: @escaping EndpointResponseHandler) {
        self.urlRequested = endpointDescriptor.getTargetURL()
        let targetArgument = endpointDescriptor.getTargetArgument() as! TargetArguments
        
        var response: URLResponse? = HTTPURLResponse(url: self.urlRequested!, statusCode: 200, httpVersion: nil, headerFields: nil)
        var error: NSError?
        var cachedDataFromFile: Data?
        if(targetArgument.pageURL != nil) {
            cachedDataFromFile = TestVectors.loadCachedImage(urlString: targetArgument.pageURL?.absoluteString, searchString: endpointDescriptor.getSearchString(), pageNumber: endpointDescriptor.getCachedPageIndex())

        }
        else {
            cachedDataFromFile = TestVectors.loadCachedPage(searchString: endpointDescriptor.getSearchString(), pageNumber: endpointDescriptor.getCachedPageIndex())
        }
        
        if(cachedDataFromFile == nil) {
            error = NSError(domain: "TestDataNotFound", code: 404, userInfo: nil)
            response = HTTPURLResponse(url: self.urlRequested!, statusCode: 404, httpVersion: nil, headerFields: nil)
        }
        
        DispatchQueue.main.async {
            responseHandler(cachedDataFromFile, response, error)
        }
    }
    
    func getOriginalURLRequest() -> URL? {
        return self.urlRequested
    }
    
}
