//
//  EndpointRequestor.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
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

class EndpointRequestor {
    /// We store all ongoing tasks here to avoid duplicating tasks.
    static var tasks = [URLSessionTask]()
    
    static func requestEndpointData(endpoint: PhotoDataEndpoint,
                                    withUIViewController: UIViewController,
                                    errorHandler: (() -> Void)?,
                                    successHandler: ((_ receivedData: Data?, _ withArgument: AnyObject?) -> Void)?,
                                    busyTheView: Bool,
                                    withArgument: AnyObject?=nil) {
        var remoteLocation: URL?
        switch endpoint {
        case .PHOTO_LISTING:
            remoteLocation = URL(string: FLICKR_PHOTO_SEARCH_PREFIX + PhotoSearchController.searchString! + FLICKR_PHOTO_SEARCH_SUFFIX + String(withArgument as! Int))
        case .PHOTO_IMAGE_THUMBNAIL:
            remoteLocation = (withArgument as! URL)
        }
        
        guard remoteLocation != nil else {
            return
        }
        
        guard tasks.index(where: { $0.originalRequest?.url == remoteLocation }) == nil else {
            // We're already downloading the image.
            print("Attempted to download the same resource more than once.")
            return
        }
        
        // Just incase it takes a while to get a response, busy the view so the user knows something
        // is happening
        var busyViewOverlay: UIViewController?
        if(busyTheView == true) {
            busyViewOverlay = withUIViewController.busyTheViewWithIndicator(currentUIViewController: withUIViewController)
        }
        
        let task = URLSession.shared.dataTask(with: remoteLocation!) {(data, response, error) in
            // Find and remove task reference once the content processing is done
            guard let taskIndex = tasks.index(where: { $0.originalRequest?.url == remoteLocation }) else {
                print("Task for URL was not found.")
                return
            }
            
            // Once the response comes back, then the view can be unbusied and updated
            if(busyTheView == true) {
                withUIViewController.unbusyTheViewWithIndicator(currentUIViewController: withUIViewController, busyView: busyViewOverlay)
            }
            
            // For issues, dispatch the default view indicating the information is unavailable
            guard error == nil else {
                print("URL Request returned with error.")
                errorHandler?()
                tasks.remove(at: taskIndex)
                return
            }
            guard let content = data else {
                print("There was no data at the requested URL.")
                errorHandler?()
                tasks.remove(at: taskIndex)
                return
            }
            
            successHandler?(content, withArgument)
            tasks.remove(at: taskIndex)
        }
        task.resume()
        tasks.append(task)
    }
}
