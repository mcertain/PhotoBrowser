//
//  FlickrEndpointDescriptor.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/21/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation

let FLICKR_PHOTO_SEARCH_PREFIX:String = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=675894853ae8ec6c242fa4c077bcf4a0&text="
let FLICKR_PHOTO_SEARCH_SUFFIX:String = "&extras=url_s,url_m,date_upload,views&format=json&nojsoncallback=1&sort=relevance&per_page=" + String(RESULTS_PER_PAGE) + "&page="

enum PhotoDataEndpoint: Int {
    case PHOTO_LISTING
    case PHOTO_IMAGE_THUMBNAIL
}

class FlickrEndpointDescriptor : EndpointDescriptorBase {
    
    let endpointType: PhotoDataEndpoint
    
    init(endpoint: PhotoDataEndpoint) {
        endpointType = endpoint
    }
    
    func getTargetURL(withArgument: AnyObject?) -> URL? {
        var remoteLocation: URL?
        switch endpointType {
        case .PHOTO_LISTING:
            remoteLocation = URL(string: FLICKR_PHOTO_SEARCH_PREFIX + PhotoSearchController.searchString! + FLICKR_PHOTO_SEARCH_SUFFIX + String(withArgument as! Int))
        case .PHOTO_IMAGE_THUMBNAIL:
            remoteLocation = (withArgument as! URL)
        }
        
        return remoteLocation
    }
}
