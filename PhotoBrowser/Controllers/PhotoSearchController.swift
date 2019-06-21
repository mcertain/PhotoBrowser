//
//  PhotoSearchController.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import UIKit

class PhotoSearchController: UITableViewController, UITableViewDataSourcePrefetching, UISearchBarDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    static var searchString: String? = ""
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Clear Out Existing cache first
        PhotoDataManager.GetInstance()?.clearStoredCache()
        
        // Scroll back to beginnning of table
        if(self.tableView.numberOfRows(inSection: 0) > 0) {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
        // Now set the new search string criteria and load the first page
        PhotoSearchController.searchString = searchController.searchBar.text?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        self.fetchPhotoData(atPage: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTableView()
        
        // Register network change events and attempt to fetch the photo details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }

    
    func setupTableView() {
        tableView.prefetchDataSource = self
        tableView.register(UINib(nibName: "PhotoListCell", bundle: nil), forCellReuseIdentifier: "PhotoListCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = PHOTO_LIST_CELL_HEIGHT

        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = false
        searchController.searchBar.delegate = self
        tableView.tableHeaderView = searchController.searchBar
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        if(reachability.connection == .none) {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }
    
    func fetchPhotoData(atPage: Int, withIndexPaths: [IndexPath]?=nil) {
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        
        // If the page isn't in cache, then go ahead and download it
        if((pPhotoDataManager?.pageCacheExists(atPage: atPage))! == false) {
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                let fetchedPageIdx = (withArgument as! Int)
                guard (pPhotoDataManager?.storePhotoData(receivedJSONData: receivedData,
                                                         forPage: fetchedPageIdx))! else {
                    print("JSON data parsing failed.")
                    return
                }
                
                // When the data is successfully retrieved and stored, then reload the table data
                // from the Photo Data Manager's cache but only for the rows just loaded
                DispatchQueue.main.async {
                    let cachedIndexPaths = withIndexPaths
                    if(cachedIndexPaths == nil || cachedIndexPaths?.count == 0) {
                        // Reload all the rows for the first cache or when data is fetched outside of prefetch
                        self.tableView.reloadData()
                    }
                    else {
                        self.tableView.reloadRows(at: cachedIndexPaths!, with: .automatic)
                    }
                }
            }
        
            EndpointRequestor.requestEndpointData(endpointDescriptor: FlickrEndpointDescriptor(endpoint: .PHOTO_LISTING),
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: true,
                                                  withTargetArgument: atPage as AnyObject)
        }
    }
    
    func fetchPhotoThumbnailImage(forCell: PhotoListCell, atIndex: Int, withID: String) {
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        
        // If the photo cover image hasn't be stored in cache yet, then fetch and store it
        let photoDetails = pPhotoDataManager?.getPhotoDetails(atIndex: atIndex)
        let thumbnailImage = photoDetails?.getUIImageData()
        if(thumbnailImage == nil) {
            // Return early if there's no URL to fetch data
            guard let imageURL = photoDetails?.getImageThumbnailURL() else {
                print("There is no image index \(atIndex) for photo with ID: " + String((photoDetails?.getPhotoID())!))
                return
            }
            
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                guard let content = receivedData else {
                    print("There was no data at the requested URL.")
                    return
                }
                
                // Store the Photo Cover Image in the Photo Data Manager's cache
                PhotoDataManager.GetInstance()?.setThumbnailImage(atIndex: atIndex, withData: content)
                
                // Then update only the cell that needs to display the photo cover image
                DispatchQueue.main.async {
                    if(self.tableView.isCellVisible(section: 0, row: atIndex)) {
                        forCell.photoImage.image = UIImage(data: content)
                    }
                }
            }
            
            EndpointRequestor.requestEndpointData(endpointDescriptor: FlickrEndpointDescriptor(endpoint: .PHOTO_IMAGE_THUMBNAIL),
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: false,
                                                  withTargetArgument: imageURL as AnyObject)
        }
        else {
            // Otherwise, if it's already cached then display it
            DispatchQueue.main.async {
                if(self.tableView.isCellVisible(section: 0, row: atIndex)) {
                    forCell.photoImage.image = thumbnailImage
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (PhotoDataManager.GetInstance()?.getPhotoCount())!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PHOTO_LIST_CELL_HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: PhotoListCell
        let idx:Int = indexPath.row
        
        // Load the default cell layout and populate it
        cell = tableView.dequeueReusableCell(withIdentifier: "PhotoListCell", for: indexPath) as! PhotoListCell
        
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        let photoItem = pPhotoDataManager?.getPhotoDetails(atIndex: idx)
        if(photoItem != nil) {
            cell.photoTitle.text = String(idx+1) + ". " + (photoItem?.getPhotoTitle())!
            cell.uploadDate.text = photoItem?.getUploadDate()
            cell.numberUserViews.text = photoItem?.getNumberViews()
            cell.photoImage.image = photoItem?.getUIImageData()
            let photoID: String? = pPhotoDataManager?.getPhotoDetails(atIndex: idx)?.getPhotoID()
            self.fetchPhotoThumbnailImage(forCell: cell, atIndex: idx,
                                      withID: photoID!)
        }
        else {
            print("Photo Cache is not available")
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let finalPrefetchItem = indexPaths[indexPaths.count-1].row
        let prefetchPage = (finalPrefetchItem / RESULTS_PER_PAGE) + 1
        
        // Load all cached pages prior to the current one that haven't been loaded yet
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        var pageFetchCount: Int = pPhotoDataManager?.getPageCount() ?? 0
        while(pageFetchCount <= prefetchPage) {
            self.fetchPhotoData(atPage: pageFetchCount)
            pageFetchCount = pageFetchCount+1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a table cell is touched, then load and open photo details view for photo selected
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let pPhotoDetailsController = mainStoryBoard.instantiateViewController(withIdentifier: "PhotoDetailsController") as? PhotoDetailsController {
            let idx:Int = indexPath.row
            let pPhotoDataManager = PhotoDataManager.GetInstance()
            let photoDetails = pPhotoDataManager?.getPhotoDetails(atIndex: idx)
            pPhotoDetailsController.photoID = photoDetails?.getPhotoID()
            pPhotoDetailsController.photoDetails = photoDetails
            if(pPhotoDetailsController.photoID != nil) {
                navigationController?.pushViewController(pPhotoDetailsController, animated: true)
            }
        }
        else {
            print("Could not load the Photo Details View")
            return
        }
    }


}

