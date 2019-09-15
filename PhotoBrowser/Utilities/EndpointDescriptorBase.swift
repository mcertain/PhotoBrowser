//
//  EndpointDescriptorBase.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/21/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

typealias EndpointErrorHandler  = (() -> Void)
typealias EndpointSuccessHandler = ((_ receivedData: Data?, _ withArgument: AnyObject?) -> Void)

protocol EndpointDescriptorBase {
    func getTargetURL() -> URL?
    func getAssociatedViewController() -> UIViewController?
    func shouldShowBusyIndicator() -> Bool
    func getErrorHandler() -> EndpointErrorHandler?
    func getSuccessHandler() -> EndpointSuccessHandler?
    func getTargetArgument() -> AnyObject?
    func getEndpointRequestTask() -> AbstractEndpointRequestTask?
    func getSearchString() -> String?
    func getCachedPageIndex() -> Int?
}

struct TargetArguments {
    let cachedPageIndex: Int?
    let searchString: String?
    let pageURL: URL?
}
