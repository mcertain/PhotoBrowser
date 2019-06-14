//
//  PhotoListCell.swift
//  PhotoBrowser
//
//  Created by Matthew Certain on 6/13/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let PHOTO_LIST_CELL_HEIGHT: CGFloat = 90

class PhotoListCell : UITableViewCell {
    @IBOutlet var photoImage: UIImageView!
    @IBOutlet var photoTitle: UILabel!
    @IBOutlet var uploadDate: UILabel!
    @IBOutlet var numberUserViews: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImage.image = nil
        photoTitle.text = ""
        uploadDate.text = ""
        numberUserViews.text = ""
    }
}
