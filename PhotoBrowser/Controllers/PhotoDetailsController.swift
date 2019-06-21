//
//  PhotoDetailsController.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let addToFavoriteListString: String = "Add to Favorites ♡"
let removeToFavoriteListString: String = "Remove From Favorites ♡"

class PhotoDetailsController : UIViewController, UINavigationControllerDelegate {
    
    var photoID: String?
    var photoDetails: PhotoAttributes?
    @IBOutlet var photoTitleLabel: UILabel!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var favoriteListButton: UIButton!
    
    @IBAction func addToFavoriteListButtonAction(_ sender: Any) {
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        guard photoDetails != nil else {
            return
        }
        
        let pressedButton = (sender as! UIButton)
        if(pressedButton.tag == 0) {
            pPhotoDataManager?.AddToFavoriteList(newItem: photoDetails!)
            pressedButton.tag = 1
            pressedButton.setTitle(removeToFavoriteListString, for: .normal)
        }
        else {
            pPhotoDataManager?.RemoveFromFavoriteList(withID: self.photoID!)
            pressedButton.tag = 0
            pressedButton.setTitle(addToFavoriteListString, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPhotoDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Register for network change events and attempt to fetch the photo details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        if(reachability.connection != .none) {
            // When the network returns, try to fetch (or refresh the current) photo details
            self.fetchPhotoDetailsAfterNetworkReturned()
        }
        else {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }

    func fetchPhotoDetailsAfterNetworkReturned() {
        // When the network returns, wait momentarily and then try to fetch the photo details again
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.fetchPhotoDetails()
        }
    }
    
    func setupDefaultView() {
        // Used when the network is down and/or the cached data isn't available, use the following
        self.photoTitleLabel.text = "Unavailable"
        self.photoImageView.image = UIImage(named: "NoConnection")
        self.favoriteListButton.isHidden = true
    }
    
    func setupView() {
        // Used when there is a valid cache entry to display photo details
        photoTitleLabel.text = photoDetails?.title
        photoImageView.image = photoDetails?.getUIImageData()
        if(photoImageView.image == nil) {
            self.photoImageView.image = UIImage(named: "NoConnection")
        }
        
        if(photoImageView.image != nil) {
            let heightInPoints:CGFloat = photoImageView.image!.size.height
            let widthInPoints:CGFloat = photoImageView.image!.size.width
            let imageRatio:CGFloat = 343 / widthInPoints
            let newWidth:CGFloat = CGFloat(widthInPoints * imageRatio)
            let newHeight:CGFloat = CGFloat(heightInPoints * imageRatio)
            
            self.photoImageView.frame = CGRect(x: photoImageView.frame.origin.x,
                                                    y: photoImageView.frame.origin.y,
                                                    width:  newWidth,
                                                    height: newHeight)
            
            favoriteListButton.setAnchors(top: photoImageView.bottomAnchor, topPad: 30,
                                          centerHorizontal: photoImageView.centerXAnchor,
                                          height: 30,
                                          width: 175)
        }
        
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        let existsOnFavoriteList = pPhotoDataManager?.ExistsInFavoriteList(withID: self.photoID!)
        if(existsOnFavoriteList == true) {
            self.favoriteListButton.tag = 1
            self.favoriteListButton.setTitle(removeToFavoriteListString, for: .normal)
        }
        else {
            self.favoriteListButton.tag = 0
            self.favoriteListButton.setTitle(addToFavoriteListString, for: .normal)
        }
    }
    
    func dispatchViewUpdate () {
        DispatchQueue.main.async {
            // If the photo details are missing, then just show the default view
            // indicating the information is unavailable
            guard self.photoDetails != nil else {
                self.setupDefaultView()
                return
            }
            // Otherwise, take the information from cache and show the photo details
            self.setupView()
        }
    }
    
    func requestPhotoDetails() {
        // Fetch the Photo Thumbnail Image if it's not already cached
        self.fetchPhotoThumbnailImage()
        
        // And then update the view with what was just stored in cache
        self.dispatchViewUpdate()
    }
    
    func fetchPhotoDetails() {
        // When the photo ID is valid
        if(photoID != nil && photoID != "") {
            // When the network is available, request any additional photo data
            if( NetworkAvailability.networkAvailable() == true) {
                self.requestPhotoDetails()
            }
            else {
                // Otherwise, since the network is down just show what's cached already
                self.dispatchViewUpdate()
            }
        }
        else {
            // Show default view, network might have went offline
            self.setupDefaultView()
        }
    }
    func fetchPhotoThumbnailImage() {
        // If the photo poster image hasn't be stored in cache yet, then fetch and store it
        let thumbnailImage = photoDetails?.imageThumbnailData
        if(thumbnailImage == nil) {
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                guard let thumbnailImageData = receivedData else {
                    print("There was no data at the requested URL.")
                    return
                }
                
                // Store the Photo Thumbnail Image
                self.photoDetails?.imageThumbnailData = thumbnailImageData
                
                // Then update the view to display the photo poster image
                DispatchQueue.main.async {
                    self.photoImageView.image = self.photoDetails?.getUIImageData()
                }
            }
            
            guard let imageURL = photoDetails?.getImageThumbnailURL() else {
                print("There is no image for photo with ID: " + String((photoDetails?.getPhotoID())!))
                return
            }
            EndpointRequestor.requestEndpointData(endpoint: .PHOTO_IMAGE_THUMBNAIL,
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: false,
                                                  withArgument: imageURL as AnyObject)
        }
    }
}
