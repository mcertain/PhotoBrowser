//
//  EndpointRequestor.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let LOCAL_DEBUG = false

typealias EndpointResponseHandler = ((Data?, URLResponse?, Error?) -> Void)

protocol AbstractEndpointRequestTask {
    func executeRequest(with endpointDescriptor: EndpointDescriptorBase, responseHandler: @escaping EndpointResponseHandler)
    func getOriginalURLRequest() -> URL?
}

// Encapsulate everything related to the shared URLSession task here.
// Nothing related to the URLSession should exposed externally, this way
// it could easily be swapped with another framework for accessing the
// backend or swapped for unit testing.
class EndpointRequestTask : AbstractEndpointRequestTask {
    
    private var task: URLSessionTask? = nil
    
    func executeRequest(with endpointDescriptor: EndpointDescriptorBase, responseHandler: @escaping EndpointResponseHandler) {
        guard let requestURL = endpointDescriptor.getTargetURL() else {
            return
        }
        task = URLSession.shared.dataTask(with: requestURL, completionHandler: responseHandler)
        
        guard let sessionTask = task else {
            return
        }
        sessionTask.resume()
    }
    
    func getOriginalURLRequest() -> URL? {
        return task?.originalRequest?.url
    }
}

class EndpointRequestor {
    
    // We store all ongoing endpoint request tasks here to avoid duplicating
    // requests for the same remote resource
    static var tasks = [AbstractEndpointRequestTask]()
    
    static func getDefaultEndpointRequestTask() -> AbstractEndpointRequestTask {
        if(LOCAL_DEBUG == true) {
            return MockedEndpointRequestTask()
        }
        else {
            return EndpointRequestTask()
        }
    }
    
    static func requestEndpointData(endpointDescriptor: EndpointDescriptorBase) -> Bool {
        // Use the provide endpoint descriptor to get the target URL using the supplied target arguments
        let remoteLocation: URL? = endpointDescriptor.getTargetURL()
        guard remoteLocation != nil else {
            return false
        }
        
        // Don't attempt to fetch the same resource twice while one fetch request is pending
        guard tasks.index(where: { $0.getOriginalURLRequest() == remoteLocation }) == nil else {
            print("Attempted to fetch the same resource more than once before the previous fetch had completed.")
            return false
        }
        
        guard let task = endpointDescriptor.getEndpointRequestTask() else {
            return false
        }
        
        // Just incase it takes a while to get a response, busy the view so the user knows something
        // is happening
        var busyViewOverlay: UIViewController?
        let busyTheView = endpointDescriptor.shouldShowBusyIndicator()
        let associatedViewController = endpointDescriptor.getAssociatedViewController()
        let targetArgument = endpointDescriptor.getTargetArgument()
        let successHandler = endpointDescriptor.getSuccessHandler()
        let errorHandler = endpointDescriptor.getErrorHandler()
        
        if(busyTheView == true) {
            busyViewOverlay = associatedViewController?.busyTheViewWithIndicator()
        }
        
        let taskResponseHandler: EndpointResponseHandler = {(data, response, error) -> Void in
            // Find and remove task reference once the content processing is done
            guard let taskIndex = self.tasks.index(where: { $0.getOriginalURLRequest() == remoteLocation }) else {
                print("Task for URL was not found.")
                return
            }
            
            // Once the response comes back, then the view can be unbusied and updated
            if(busyTheView == true) {
                associatedViewController?.unbusyTheViewWithIndicator(busyView: busyViewOverlay)
            }
            
            // For issues, dispatch the default view indicating the information is unavailable
            guard error == nil else {
                print("URL Request returned with error.")
                errorHandler?()
                self.tasks.remove(at: taskIndex)
                return
            }
            guard let content = data else {
                print("There was no data at the requested URL.")
                errorHandler?()
                self.tasks.remove(at: taskIndex)
                return
            }
            
            successHandler?(content, targetArgument)
            self.tasks.remove(at: taskIndex)
        }
        task.executeRequest(with: endpointDescriptor,
                            responseHandler: taskResponseHandler)
        tasks.append(task)
        
        return true
    }
}
