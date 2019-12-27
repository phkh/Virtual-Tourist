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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var placeholerImages: [UIImage] = []
    var images: [UIImage] = []
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var radius: Int = 5
    
    let annotation = MKPointAnnotation()
    var itemsSelected = [IndexPath]()
    
    var loaded = false
    var changeButtonLabel = false
    
    enum Mode {
        case view
        case select
    }
    
    var mMode: Mode = .select {
        didSet {
            switch mMode {
            case .select:
                newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
                newCollectionButton.titleLabel?.adjustsFontSizeToFitWidth = true
            case .view:
                newCollectionButton.setTitle("New Collection", for: .normal)
                newCollectionButton.titleLabel?.adjustsFontSizeToFitWidth = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        noImagesLabel.isHidden = true
        collectionView.allowsMultipleSelection = true
        
        mMode = .view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if latitude != 0.0 && longitude != 0.0 {
            FlickrAPI.getPhotosJSON(completion: completion(success:error:response:), lat: latitude, long: longitude, radius: 5)
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            map.addAnnotation(annotation)
            map.showAnnotations(self.map.annotations, animated: true)
        }
    }
    
    func completion(success: Bool, error: Error?, response: FlickrResponse?) {
        if success {
            downloadPhotos(response: response)
        } else {
            
        }
    }
    
    func downloadPhotos(response: FlickrResponse?) {
        var url = ""
        let download = DispatchQueue(label: "download")
        DispatchQueue.main.async {
            self.collectionView.isScrollEnabled = false
        }
        if let photos = response?.photos.photo {
            for element in photos {
                url = "https://farm\(element.farm).staticflickr.com/\(element.server)/\(element.id)_\(element.secret)_q.jpg"
                print(url)
                self.setImage(from: url)
            }
        }
        
        DispatchQueue.main.async {
            if self.images.count == 0 {
                self.noImagesLabel.isHidden = false
        }
            self.collectionView.reloadData()
            self.collectionView.isScrollEnabled = true
            self.newCollectionButton.isEnabled = true
        }
        loaded = true

    }
    
    func setImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        guard let imageData = try? Data(contentsOf: imageURL) else { return }

        let image = UIImage(data: imageData)!
        let newImage = UIImage.resize(image: image, targetSize: CGSize(width: 118, height: 118))
        images.append(newImage)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if loaded {
            return images.count
        } else {
            return 21
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellCollection = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        if loaded {
            cellCollection.activityIndicator.stopAnimating()
            cellCollection.imageCell.image = images[indexPath.row]
        } else {
            cellCollection.imageCell.image = UIImage(named: "placeholder")
            cellCollection.activityIndicator.startAnimating()
        }
        return cellCollection
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mMode = .select
    
        switch mMode {
        case .view:
            break
        case .select:
            if !(itemsSelected.contains(indexPath)) {
                itemsSelected.append(indexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch mMode {
        case .view:
            break
        case .select:
            if itemsSelected.contains(indexPath) {
                itemsSelected.remove(at: itemsSelected.firstIndex(of: indexPath)!)
            }
        }
        

        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count == 0 {
            mMode = .view
        }
    }
    
    @IBAction func onButtonClick(_ sender: Any) {
        switch mMode {
        case .select:
            if let selectedCells = collectionView.indexPathsForSelectedItems {
                let items = selectedCells.map { $0.item }.sorted().reversed()

                for item in items {
                    images.remove(at: item)
                }
                collectionView.deleteItems(at: selectedCells)

            }
            mMode = .view
        case .view:
            loadNewCollection()
        }
    }
    
    func loadNewCollection() {
        if radius != 32 {
            radius += 3
        }
        images.removeAll()
        loaded = false
        FlickrAPI.getPhotosJSON(completion: completion(success:error:response:), lat: latitude, long: longitude, radius: radius)
        collectionView.reloadData()
    }
}
