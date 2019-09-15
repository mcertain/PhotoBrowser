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
    
    // This helpers creates the base root directory for the test vector files
    func getFilePathString(filename: String?, withExtension: String?) -> String? {
        
        // When local debug is disabled, the vectors come from documents directory, this can be
        // helpful after a new capture of test vectors from the backend server is performed
        if(LOCAL_DEBUG == false) {
            let filenameStr = "Vectors/" + (filename ?? "") + "." + (withExtension ?? "")
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString + filenameStr
        }
        // Otherwise, the vectors are loaded from the app bundle where the TestVectors are located.
        // This is useful after capturing and permanantly storing Test Vectors for Unit Testing
        else {
            return Bundle(for: TestVectors.self).url(forResource: filename, withExtension: withExtension)?.absoluteString
        }
    }
    
    // Just like the product executeRequest except it sources data locally from the file system vs.
    // remotely from a backend server
    func executeRequest(with endpointDescriptor: EndpointDescriptorBase, responseHandler: @escaping EndpointResponseHandler) {
        self.urlRequested = endpointDescriptor.getTargetURL()
        let targetArgument = endpointDescriptor.getTargetArgument() as! TargetArguments
        
        var response: URLResponse? = HTTPURLResponse(url: self.urlRequested!, statusCode: 200, httpVersion: nil, headerFields: nil)
        var error: NSError?
        var cachedDataFromFile: Data?
        if(targetArgument.pageURL != nil) {
            cachedDataFromFile = loadCachedImage(urlString: targetArgument.pageURL?.absoluteString, searchString: endpointDescriptor.getSearchString(), pageNumber: endpointDescriptor.getCachedPageIndex())

        }
        else {
            cachedDataFromFile = loadCachedPage(searchString: endpointDescriptor.getSearchString(), pageNumber: endpointDescriptor.getCachedPageIndex())
        }
        
        if(cachedDataFromFile == nil) {
            error = NSError(domain: "TestDataNotFound", code: 404, userInfo: nil)
            response = HTTPURLResponse(url: self.urlRequested!, statusCode: 404, httpVersion: nil, headerFields: nil)
        }
        
        DispatchQueue.main.async {
            responseHandler(cachedDataFromFile, response, error)
        }
    }
    
    // Loads the exact same JSON data that could come from a backend server, there is
    // a separate file each cached page response that would normally come from the server
    func loadCachedPage(searchString: String?, pageNumber: Int?) -> Data? {
        guard let searchStr = searchString else {
            return nil
        }
        guard let pageNum = pageNumber else {
            return nil
        }
        
        var filenameStr: String? = searchStr + "-P" + String(pageNum)
        filenameStr = getFilePathString(filename: filenameStr, withExtension: "json")
        let filenameURL = URL(string: filenameStr ?? "")
        
        var cachedPageData: Data?
        do {
            guard filenameURL != nil else {
                throw "File URL Invalid."
            }
            cachedPageData = try Data(contentsOf: filenameURL!)
        } catch {
            print("Could not load cached page from file.")
        }
        
        return cachedPageData
    }
    
    // Loads a dictionary from a JSON file where the key is the requested URL and the value is
    // a Data object representing the image being requested. There is a separate JSON file that
    // aligns to same cache page number where the image reference is sourced.
    func loadCachedImage(urlString: String?, searchString: String?, pageNumber: Int?) -> Data? {
        guard let pageURLStr = urlString else {
            return nil
        }
        guard let searchStr = searchString else {
            return nil
        }
        guard let pageNum = pageNumber else {
            return nil
        }
        
        var filenameStr: String? = searchStr + "-I" + String(pageNum)
        filenameStr = getFilePathString(filename: filenameStr, withExtension: "json")
        let filenameURL = URL(string: filenameStr ?? "")
        
        var cachedFileData: Data?
        do {
            guard filenameURL != nil else {
                throw "File URL Invalid"
            }
            cachedFileData = try Data(contentsOf: filenameURL!)
        }
        catch let decodeError {
            print("Failed to load cached image data from file: \(decodeError)")
            return nil
        }
        
        var cachedImages: [String:Data?]?
        if(cachedFileData != nil) {
            do {
                cachedImages = try JSONDecoder().decode([String:Data?].self, from: cachedFileData!)
            }
            catch let decodeError {
                print("Failed to decode favorites list from file: \(decodeError)")
                return nil
            }
        }
        
        let imageData = cachedImages![urlString!]!
        
        return imageData
    }
    
    func getOriginalURLRequest() -> URL? {
        return self.urlRequested
    }
    
}
