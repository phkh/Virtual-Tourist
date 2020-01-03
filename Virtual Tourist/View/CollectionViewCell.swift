//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var highlightingView: UIView!
    
    override var isHighlighted: Bool {
        didSet {
            highlightingView.isHidden = !isHighlighted
        }
    }
    
    override var isSelected: Bool {
        didSet {
            highlightingView.isHidden = !isSelected
        }
    }
    
    func initWithPhoto(_ photo: Photo) {
        if photo.image == nil {
            
        } else {
            
        }
    }
    
    func downloadPhoto(_ photo: Photo) {
        
    }
}
