//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import Foundation
import UIKit
import MapKit

private let sectionInsets = UIEdgeInsets(top: 60.0, left: 10.0, bottom: 60.0, right: 10.0)

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var imagesInfo: [FlickrResponse.PhotoInfo.Photo] = []
    var images: [UIImage] = []
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        FlickrAPI.getPhotosJSON(completion: completion(success:error:response:))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    func completion(success: Bool, error: Error?, response: FlickrResponse?) {
        if success {
            var url = ""
            for element in (response?.photos.photo)! {
                url = "https://farm\(element.farm).staticflickr.com/\(element.server)/\(element.id)_\(element.secret).jpg"
                print(url)
                imagesInfo.append(element)
                setImage(from: url)
            }
            print(images.count)
        }
    }
    
    func setImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        guard let imageData = try? Data(contentsOf: imageURL) else { return }

        let image = UIImage(data: imageData)!
        images.append(image)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellCollection = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
         
        cellCollection.imageCell.image = images[indexPath.row]
            
        return cellCollection
        
    }
    

    @IBAction func onButtonClick(_ sender: Any) {
        collectionView.reloadData()
    }
}
