//
//  PhotoBrowserUnitTests.swift
//  PhotoBrowserUnitTests
//
//  Created by Matthew Certain on 9/12/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import XCTest

class PBDataModelUnitTests: XCTestCase {
    
    var photoDataManager: PhotoDataManager?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        photoDataManager = PhotoDataManager.GetInstance()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        photoDataManager = nil
        PhotoDataManager.RemoveInstance()
    }
    
    func testAccessorsWhenModelIsEmpty() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let photoCount = photoDataManager?.getPhotoCount()
        XCTAssert(photoCount == 0)
        
        let pageCount = photoDataManager?.getPageCount()
        XCTAssert(pageCount == 0)
        
        let pageCacheExists = photoDataManager?.pageCacheExists(atPage: 1)
        XCTAssert(pageCacheExists == false)
        
        let photoDetails = photoDataManager?.getPhotoDetails(atIndex: 1)
        XCTAssert(photoDetails == nil)
        
        photoDataManager?.setThumbnailImage(atIndex: 1, withData: Data(capacity: 5))
        let photoCacheExistsNow = photoDataManager?.getPhotoDetails(atIndex: 1)
        XCTAssert(photoCacheExistsNow == nil)
        
        let favoritesListArray = photoDataManager?.GetFavoriteList()
        XCTAssert(favoritesListArray?.count == 0)
        
        let favoritesListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoritesListCount == 0)
        
        let favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 0)
        
        let existsInFavoriteList = photoDataManager?.ExistsInFavoriteList(withID: "12345678")
        XCTAssert(existsInFavoriteList == false)
        
        let favoriteListItem = photoDataManager?.GetFavoriteListItem(atIndex: 1)
        XCTAssert(favoriteListItem == nil)
    }
    
    func testAccessorsWhenModelIsFilled() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Load 1 cached page of data from vector file and store data in model
        let loadedData = TestVectors.loadCachedPage(searchString: "Cats", pageNumber: 1)
        XCTAssert(loadedData != nil)
        let storePhotoDataStat = photoDataManager?.storePhotoData(receivedJSONData: loadedData, forPage: 1)
        XCTAssert(storePhotoDataStat == true)
        
        let photoCount = photoDataManager?.getPhotoCount()
        XCTAssert(photoCount == 2589493) // Total results count in data set
        
        let pageCount = photoDataManager?.getPageCount()
        XCTAssert(pageCount == 1)
        
        let pageCacheExistsValid = photoDataManager?.pageCacheExists(atPage: 1)
        XCTAssert(pageCacheExistsValid == true)
        
        let pageCacheExistsInvalid = photoDataManager?.pageCacheExists(atPage: 3)
        XCTAssert(pageCacheExistsInvalid == false)
        
        let photoDetails = photoDataManager?.getPhotoDetails(atIndex: 10)
        XCTAssert(photoDetails != nil)
        
        photoDataManager?.setThumbnailImage(atIndex: 15, withData: Data(capacity: 5))
        let photoCacheExistsNow = photoDataManager?.getPhotoDetails(atIndex: 15)
        XCTAssert(photoCacheExistsNow != nil)
        

        // Add photos to favorites list
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 1))!)
        var favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 1)
        
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 21))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 32))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 43))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 15))!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 5)
        
        // Attempt to add a duplicate and confirm it doesn't exist
        let duplicateAdd = photoDataManager?.getPhotoDetails(atIndex: 5)
        photoDataManager?.AddToFavoriteList(newItem: duplicateAdd!)
        photoDataManager?.AddToFavoriteList(newItem: duplicateAdd!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 6)
        var existsAlready = photoDataManager?.ExistsInFavoriteList(withID: duplicateAdd!.id)
        XCTAssert(existsAlready == true)
        
        // Confirm a single remove doesn't leave one after a duplicate add
        photoDataManager?.RemoveFromFavoriteList(withID: duplicateAdd!.id)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 5)
        let existsStill = photoDataManager?.ExistsInFavoriteList(withID: duplicateAdd!.id)
        XCTAssert(existsStill == false)
        
        let favoriteListItem = photoDataManager?.GetFavoriteListItem(atIndex: 1)
        XCTAssert(favoriteListItem != nil)
        
        let existsInFavoriteList = photoDataManager?.ExistsInFavoriteList(withID: favoriteListItem!.id)
        XCTAssert(existsInFavoriteList == true)
        
        photoDataManager?.RemoveFromFavoriteList(withID: (photoDataManager?.GetFavoriteListItem(atIndex: 4)!.id)!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 4)
        
        photoDataManager?.RemoveFromFavoriteList(withID: (photoDataManager?.GetFavoriteListItem(atIndex: 2)!.id)!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 3)
        
        photoDataManager?.RemoveFromFavoriteList(withID: (photoDataManager?.GetFavoriteListItem(atIndex: 1)!.id)!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 2)
        
        photoDataManager?.RemoveFromFavoriteList(withID: (photoDataManager?.GetFavoriteListItem(atIndex: 1)!.id)!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 1)
        
        photoDataManager?.RemoveFromFavoriteList(withID: (photoDataManager?.GetFavoriteListItem(atIndex: 0)!.id)!)
        favoriteListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoriteListCount == 0)
    }
    
    func testArchiveAndUnarchiveFavoritesList() {
        
        // Load 1st cached page of data from vector file and store data in model
        let loadedData1 = TestVectors.loadCachedPage(searchString: "Cats", pageNumber: 1)
        XCTAssert(loadedData1 != nil)
        let storePhotoDataStat1 = photoDataManager?.storePhotoData(receivedJSONData: loadedData1, forPage: 1)
        XCTAssert(storePhotoDataStat1 == true)
        
        // Load 2nd cached page of data from vector file and store data in model
        let loadedData2 = TestVectors.loadCachedPage(searchString: "Cats", pageNumber: 2)
        XCTAssert(loadedData2 != nil)
        let storePhotoDataStat2 = photoDataManager?.storePhotoData(receivedJSONData: loadedData2, forPage: 2)
        XCTAssert(storePhotoDataStat2 == true)
        
        // Load 3rd cached page of data from vector file and store data in model
        let loadedData3 = TestVectors.loadCachedPage(searchString: "Cats", pageNumber: 3)
        XCTAssert(loadedData3 != nil)
        let storePhotoDataStat3 = photoDataManager?.storePhotoData(receivedJSONData: loadedData3, forPage: 3)
        XCTAssert(storePhotoDataStat3 == true)
        
        var favoritesListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoritesListCount == 0)
        
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 99))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 77))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 88))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 2))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 22))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 12))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 34))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 56))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 78))!)
        photoDataManager?.AddToFavoriteList(newItem: (photoDataManager?.getPhotoDetails(atIndex: 100))!)
        favoritesListCount = photoDataManager?.GetFavoriteListCount()
        XCTAssert(favoritesListCount == 10)
        
        // Archive the favorites list
        photoDataManager?.archiveFavoritesList()
        
        // Simulate killing and re-opening the application
        self.tearDown()
        self.setUp()
        
        // Confirm the favorites list is empty
        let photoCount = photoDataManager?.getPhotoCount()
        XCTAssert(photoCount == 0)
        
        let pageCount = photoDataManager?.getPageCount()
        XCTAssert(pageCount == 0)
        
        let emptyFavorites = photoDataManager?.GetFavoriteListCount()
        XCTAssert(emptyFavorites == 0)
        
        // Now reload the favorites list from the archive file
        photoDataManager?.unarchiveFavoritesList()
        
        let reloadedFavorites = photoDataManager?.GetFavoriteListCount()
        XCTAssert(reloadedFavorites == 10)
    }
}

/*
class PhotoBrowserUnitTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
*/
