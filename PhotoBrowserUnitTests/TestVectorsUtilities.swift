//
//  TestVectors.swift
//  PhotoBrowserUnitTests
//
//  Created by Matthew Certain on 9/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation



class TestVectors {
    
    // Invoked to start capturing data for the first 5 cached pages for the given search string
    static func executeVectorCapture(with searchString: String) -> Void {
        let pageToFetch = 1
        let searchStr = searchString
        
        TestVectors.initializeVectorCapture(searchString: searchStr, cachedPageNumberToFetch: pageToFetch)
        TestVectors.initializeVectorCapture(searchString: searchStr, cachedPageNumberToFetch: pageToFetch + 1)
        TestVectors.initializeVectorCapture(searchString: searchStr, cachedPageNumberToFetch: pageToFetch + 2)
        TestVectors.initializeVectorCapture(searchString: searchStr, cachedPageNumberToFetch: pageToFetch + 3)
        TestVectors.initializeVectorCapture(searchString: searchStr, cachedPageNumberToFetch: pageToFetch + 4)
        
    }
    
    static let pageDataDownloadSem = DispatchSemaphore(value: 0)
    static let imageDownloadSem = DispatchSemaphore(value: 0)
    static var imageURLs: [URL] = [URL]()
    
    // Used to setup everything necessary to capture the vector data and related images into files
    static func initializeVectorCapture(searchString: String, cachedPageNumberToFetch: Int) {
        let endpointRequestTaskMocked = EndpointRequestTask()
        let successHandler: EndpointSuccessHandler? = captureVectorData(receivedData:withArgument:)
        let errorHandler = { () -> Void in
            print("Error response received for results listing download.")
            pageDataDownloadSem.signal()
        }
        
        EndpointRequestor.requestEndpointData(endpointDescriptor: FlickrEndpointDescriptor(endpoint: .PHOTO_LISTING,
                                                                                           endpointRequestTask: endpointRequestTaskMocked,
                                                                                           errorHandler: errorHandler,
                                                                                           successHandler: successHandler,
                                                                                           withUIViewController: nil,
                                                                                           busyTheView: true,
                                                                                           withTargetArgument: TargetArguments(cachedPageIndex: cachedPageNumberToFetch,
                                                                                                                               searchString: searchString,
                                                                                                                               pageURL: nil) as AnyObject))
        pageDataDownloadSem.wait()
        
        captureVectorImages(withArgument: TargetArguments(cachedPageIndex: cachedPageNumberToFetch,
                                                          searchString: searchString,
                                                          pageURL: nil) as AnyObject)
        
    }
    
    // Used to capture JSON data and store it in JSON files
    static func captureVectorData(receivedData: Data?, withArgument: AnyObject?) -> Void {
        let searchParams = withArgument as! TargetArguments
        let fetchedPageIdx = searchParams.cachedPageIndex
        let searchStr = searchParams.searchString
        let jsonString: String = String(data: receivedData!, encoding: .utf8)!
        let vectorRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
        let filenameStr = vectorRoot + "Vectors/" + searchStr! + "-P" + String(fetchedPageIdx!) + ".json"
        let filenameURL = URL(string: filenameStr)
        
        do {
            try jsonString.write(to: filenameURL!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("failed to write file (\(filenameStr)) – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding")
        }
        
        var receivedPage: ResultsPage?
        if(receivedData != nil) {
            do {
                receivedPage = try JSONDecoder().decode(ResultsPage.self, from: receivedData!)
            }
            catch let decodeError {
                print("Failed to decode Photo DB JSON Data: \(decodeError)")
                return
            }
        }
        let imageCount: Int = (receivedPage?.photos?.photo!.count) ?? 0
        for i in 0..<imageCount {
            guard let imageURL = receivedPage?.photos?.photo![i].getImageThumbnailURL() else {
                print("There is no image index \(i) for photo with ID: " + String((receivedPage?.photos?.photo![i].getPhotoID())!))
                continue
            }
            
            imageURLs.append(imageURL)
        }
        pageDataDownloadSem.signal()
    }
    
    // Used to capture the images referenced in JSON data and required by the app.
    // The images are stored in a JSON file containing a dictionary where the key is
    // the requested URL and the value is a Data object representing the image being requested.
    static func captureVectorImages(withArgument: AnyObject?) -> Void {
        let searchParams = withArgument as! TargetArguments
        let fetchedPageIdx = searchParams.cachedPageIndex
        let searchStr = searchParams.searchString
        var imageDataForPage: [String:Data?] = [String:Data?]()

        let storeImageDataHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
            let searchParams = withArgument as! TargetArguments
            guard let imageData = receivedData else {
                return
            }
            guard let imageURL = searchParams.pageURL else {
                return
            }
            
            imageDataForPage[imageURL.absoluteString] = imageData
            
            if(imageDataForPage.count == 50) {
                let fileManager = FileManager.default
                let saveURL = try! fileManager.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let appendPath = "Vectors/" + searchStr! + "-I" + String(fetchedPageIdx!) + ".json"
                let fullPath = saveURL.appendingPathComponent(appendPath)
                let encoder = JSONEncoder()
                let storageString: String? = String(decoding: try! encoder.encode(imageDataForPage), as: UTF8.self)
                if(storageString != nil)
                {
                    do {
                        try storageString?.write(to: fullPath, atomically: true, encoding: String.Encoding.utf8)
                    } catch {
                        print("Couldn't save image map cache list to JSON file.")
                    }
                }
            }
            imageDownloadSem.signal()
        }
        
        let errorHandler = { () -> Void in
            print("Error response received for image download.")
            imageDownloadSem.signal()
        }
        

        for imageURL in imageURLs {
            EndpointRequestor.requestEndpointData(endpointDescriptor: FlickrEndpointDescriptor(endpoint: .PHOTO_IMAGE_THUMBNAIL,
                                                                                               endpointRequestTask: EndpointRequestTask(),
                                                                                               errorHandler: errorHandler,
                                                                                               successHandler: storeImageDataHandler,
                                                                                               withUIViewController: nil,
                                                                                               busyTheView: false,
                                                                                               withTargetArgument: TargetArguments(cachedPageIndex: fetchedPageIdx,
                                                                                                                                   searchString: searchStr,
                                                                                                                                   pageURL: imageURL) as AnyObject))
            imageDownloadSem.wait()
        }
        imageDataForPage.removeAll()
        imageURLs.removeAll()
    }
    
    // This helpers creates the base root directory for the test vector files
    static func getFilePathString(filename: String?, withExtension: String?) -> String? {
        
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
    
    // Loads the exact same JSON data that could come from a backend server, there is
    // a separate file each cached page response that would normally come from the server
    static func loadCachedPage(searchString: String?, pageNumber: Int?) -> Data? {
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
    static func loadCachedImage(urlString: String?, searchString: String?, pageNumber: Int?) -> Data? {
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
        
        let imageData = cachedImages![pageURLStr]!
        
        return imageData
    }
    
}
