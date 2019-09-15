//
//  FlickrEndpointDescriptor.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/21/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let FLICKR_PHOTO_SEARCH_PREFIX:String = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=675894853ae8ec6c242fa4c077bcf4a0&text="
let FLICKR_PHOTO_SEARCH_SUFFIX:String = "&extras=url_s,url_m,date_upload,views&format=json&nojsoncallback=1&sort=relevance&per_page=" + String(RESULTS_PER_PAGE) + "&page="

enum PhotoDataEndpoint: Int {
    case PHOTO_LISTING
    case PHOTO_IMAGE_THUMBNAIL
}

class FlickrEndpointDescriptor : EndpointDescriptorBase {
    let endpointType: PhotoDataEndpoint
    let endpointRequestTask: AbstractEndpointRequestTask?
    let associatedViewController: UIViewController?
    let busyTheAssociatedView: Bool
    let targetURLArgument: AnyObject?
    let errorHandler: EndpointErrorHandler?
    let successHandler: EndpointSuccessHandler?
    
    init(endpoint: PhotoDataEndpoint,
         endpointRequestTask: AbstractEndpointRequestTask,
         errorHandler: EndpointErrorHandler?,
         successHandler: EndpointSuccessHandler?,
         withUIViewController: UIViewController?,
         busyTheView: Bool,
         withTargetArgument: AnyObject?=nil) {
        self.endpointType = endpoint
        self.endpointRequestTask = endpointRequestTask
        self.associatedViewController = withUIViewController
        self.busyTheAssociatedView = busyTheView
        self.targetURLArgument = withTargetArgument
        self.errorHandler = errorHandler
        self.successHandler = successHandler
    }
    
    func getEndpointRequestTask() -> AbstractEndpointRequestTask? {
        return endpointRequestTask
    }
    
    func getErrorHandler() -> EndpointErrorHandler? {
        return errorHandler
    }
    
    func getSuccessHandler() -> ((Data?, AnyObject?) -> Void)? {
        return successHandler
    }
    
    func getTargetArgument() -> AnyObject? {
        return targetURLArgument
    }
    
    func getSearchString() -> String? {
        let searchParams = targetURLArgument as! TargetArguments
        return searchParams.searchString
    }
    
    func getCachedPageIndex() -> Int? {
        let searchParams = targetURLArgument as! TargetArguments
        return searchParams.cachedPageIndex
    }
    
    func getAssociatedViewController() -> UIViewController? {
        return associatedViewController
    }
    
    func shouldShowBusyIndicator() -> Bool {
        return busyTheAssociatedView
    }
    
    func getTargetURL() -> URL? {
        var remoteLocation: URL?
        switch endpointType {
        case .PHOTO_LISTING:
            let searchParams = targetURLArgument as! TargetArguments
            remoteLocation = URL(string: FLICKR_PHOTO_SEARCH_PREFIX + searchParams.searchString! + FLICKR_PHOTO_SEARCH_SUFFIX + String(searchParams.cachedPageIndex!))
        case .PHOTO_IMAGE_THUMBNAIL:
            let searchParams = targetURLArgument as! TargetArguments
            remoteLocation = searchParams.pageURL
        }
        
        return remoteLocation
    }
}
