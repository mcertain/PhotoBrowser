//
//  PhotoDataManager.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let RESULTS_PER_PAGE: Int = 50

struct ResultsPage: Decodable, Encodable  {
    let stat:       String
    let code:       Int?
    let message:    String?
    var photos:     PhotoListPage?
}

struct PhotoListPage: Decodable, Encodable  {
    let page:    Int
    let pages:   Int
    let perpage: Int
    var photo:   [PhotoAttributes]?
    let total:   String
}

class PhotoAttributes: Decodable, Encodable, Equatable {
    let id:         String
    let views:      String?
    let dateupload: String?
    let farm:       Int?
    let isfamily:   Int?
    let isfriend:   Int?
    let ispublic:   Int?
    let owner:      String?
    let secret:     String?
    let server:     String?
    let title:      String?
    let url_s:      String?
    let height_s:   String?
    let width_s:    String?
    let url_m:      String?
    let height_m:   String?
    let width_m:    String?
    var imageThumbnailData:  Data?
    
    static func == (lhs: PhotoAttributes, rhs: PhotoAttributes) -> Bool {
        if(lhs.id == rhs.id) {
            return true
        }
        return false
    }
    
    func getPhotoID() -> String {
        return String(self.id)
    }
    
    func getNumberViews() -> String? {
        return String("Views: " + Int(self.views ?? "0")!.commaDelimited)
    }
    
    func getUIImageData() -> UIImage? {
        guard imageThumbnailData != nil else {
            return nil
        }
        return UIImage(data: imageThumbnailData!)
    }
    
    func getPhotoTitle() -> String? {
        return self.title
    }
    
    func getImageThumbnailURL() -> URL? {
        guard self.url_s != nil else {
            return nil
        }
        return URL(string: self.url_s!)
    }
    
    func getUploadDate() -> String? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "MMM d yyyy h:mma"
        let dateText = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(self.dateupload!)!))
        return dateText
    }
}

class PhotoDataManager {
    
    // PhotoDataManager should be singleton since we only need one instance for
    // helper parsing functions and to store the Photo List Items
    static var singletonInstance:PhotoDataManager? = nil
    fileprivate var cachedPages: [ResultsPage?] = []
    fileprivate var favoriteList: [PhotoAttributes] = []

    private init() { }
    
    static func GetInstance() ->PhotoDataManager? {
        if(PhotoDataManager.singletonInstance == nil) {
            PhotoDataManager.singletonInstance = PhotoDataManager()
        }
        return PhotoDataManager.singletonInstance
    }
    
    func clearStoredCache() {
        for i in 0..<cachedPages.count {
            cachedPages[i]?.photos?.photo?.removeAll()
            cachedPages[i]?.photos?.photo = nil
            cachedPages[i]?.photos = nil
        }
        cachedPages.removeAll()
    }
    
    // Provide the ability to archive favorites list into a JSON file
    // Anytime the app goes to the background the favorites list should be saved if it's not empty
    func archiveFavoritesList() {
        if(favoriteList.count > 0) {
            let fileManager = FileManager.default
            let saveURL = try! fileManager.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fullPath = saveURL.appendingPathComponent("FavoritesList.json")
            
            let encoder = JSONEncoder()
            let storageString: String? = String(decoding: try! encoder.encode(favoriteList), as: UTF8.self)
            
            if(storageString != nil)
            {
                do {
                    try storageString?.write(to: fullPath, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Couldn't save favorites list to archive file.")
                }
            }
        }
    }
    
    // Provide the ability to unarchive favorites list from a saved JSON file
    // Anytime the app returns from the background the favorites list should be loaded if one isn't already loaded
    func unarchiveFavoritesList() {
        if(favoriteList.count == 0) {
            let fileManager = FileManager.default
            let saveURL = try! fileManager.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fullPath = saveURL.appendingPathComponent("FavoritesList.json")
            var storagedData: Data?
            
            do {
                storagedData = try Data(contentsOf: fullPath)
            }
            catch let decodeError {
                print("Failed to read favorites list from file: \(decodeError)")
                return
            }
            
            if(storagedData != nil) {
                do {
                    favoriteList = try JSONDecoder().decode([PhotoAttributes].self, from: storagedData!)
                }
                catch let decodeError {
                    print("Failed to decode favorites list from file: \(decodeError)")
                }
            }
        }
    }
    
    func storePhotoData(receivedJSONData: Data?, forPage: Int) -> Bool {
        var receivedPage: ResultsPage
        if(receivedJSONData != nil) {
            do {  
                receivedPage = try JSONDecoder().decode(ResultsPage.self, from: receivedJSONData!)
            }
            catch let decodeError {
                print("Failed to decode Photo DB JSON Data: \(decodeError)")
                return false
            }
            
            if( (receivedPage.stat == "ok") && (cachedPages.count == (forPage-1)) ) {
                cachedPages.append(receivedPage)
            }
            else {
                return false
            }
        }
        return true
    }
    
    func getPhotoCount() -> Int {
        guard cachedPages.indices.contains(0) == true else {
            return 0
        }
        
        return Int((cachedPages[0]?.photos?.total)!) ?? 0
    }
    
    func getPageCount() -> Int {        
        return cachedPages.count
    }
    
    func pageCacheExists(atPage: Int) -> Bool {
        return cachedPages.indices.contains(atPage-1)
    }
    
    func getPhotoDetails(atIndex: Int) -> PhotoAttributes? {
        let pageCount = atIndex / RESULTS_PER_PAGE
        let pageIdx = atIndex % RESULTS_PER_PAGE
        
        guard cachedPages.indices.contains(pageCount) == true else {
            return nil
        }
        guard ((cachedPages[pageCount]?.photos) != nil) else {
            return nil
        }
        guard cachedPages[pageCount]?.photos?.photo?.indices.contains(pageIdx) == true else {
            return nil
        }
        guard cachedPages[pageCount]?.photos?.photo?[pageIdx] != nil else {
            return nil
        }
        return cachedPages[pageCount]?.photos?.photo?[pageIdx]
    }
    
    func setThumbnailImage(atIndex: Int, withData: Data) {
        let pageCount = atIndex / RESULTS_PER_PAGE
        let pageIdx = atIndex % RESULTS_PER_PAGE
        cachedPages[pageCount]?.photos?.photo?[pageIdx].imageThumbnailData = withData
    }
    
    func GetFavoriteList() -> [PhotoAttributes] {
        return favoriteList
    }
    func GetFavoriteListCount() -> Int {
        return favoriteList.count
    }
    func AddToFavoriteList(newItem: PhotoAttributes) {
        favoriteList.append(newItem)
    }
    
    func RemoveFromFavoriteList(withID: String) {
        let updateFavoriteList = favoriteList.filter { (item) -> Bool in
            return (String(item.id) != withID)
        }
        favoriteList = updateFavoriteList
    }
    
    func ExistsInFavoriteList(withID: String) -> Bool {
        let foundItems = favoriteList.filter { (item) -> Bool in
            return (String(item.id) == withID)
        }
        if(foundItems.count != 0) {
            return true
        }
        else {
            return false
        }
    }
    
    func GetFavoriteListItem(atIndex: Int) -> PhotoAttributes {
        return favoriteList[atIndex]
    }

}
