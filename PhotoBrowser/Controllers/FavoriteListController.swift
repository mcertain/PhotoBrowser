//
//  FavoriteListController.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import UIKit

class FavoriteListController: UITableViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Register network change events and attempt to fetch the photo details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        if(reachability.connection != .none) {
            // Once the network is confirmed to be available, then reload the photo watch list data
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (PhotoDataManager.GetInstance()?.GetFavoriteListCount())!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PHOTO_LIST_CELL_HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: PhotoListCell
        let idx:Int = indexPath.row
        let pPhotoDataManager = PhotoDataManager.GetInstance()
        
        // Load the default cell layout and populate it
        cell = Bundle.main.loadNibNamed("PhotoListCell", owner: self, options: nil)?.first as! PhotoListCell
        
        let photoItem = pPhotoDataManager?.GetFavoriteListItem(atIndex: idx)
        cell.photoTitle.text = photoItem?.getPhotoTitle()
        cell.uploadDate.text = photoItem?.getUploadDate()
        cell.numberUserViews.text = photoItem?.getNumberViews()
        cell.photoImage.image = photoItem?.getUIImageData()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a table cell is touched, then load and open photo details view for photo selected
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if let pPhotoDetailsController = mainStoryBoard.instantiateViewController(withIdentifier: "PhotoDetailsController") as? PhotoDetailsController {
            let idx:Int = indexPath.row
            let pPhotoDataManager = PhotoDataManager.GetInstance()
            let photoDetails = pPhotoDataManager?.GetFavoriteListItem(atIndex: idx)
            pPhotoDetailsController.photoID = photoDetails?.getPhotoID()
            pPhotoDetailsController.photoDetails = photoDetails
            navigationController?.pushViewController(pPhotoDetailsController, animated: true)
        }
        else {
            print("Could not load the Photo Details View")
            return
        }
    }


}

