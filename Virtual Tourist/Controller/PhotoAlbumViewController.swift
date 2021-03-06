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
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var placeholerImages: [UIImage] = []
    var photos: [Photo] = []
    
    var selectedPin: Pin!
    
    var imagesURL = [String]()
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0

    var totalPages: Int? = 0
    var perPage: Int = 0
    
    let annotationOnMap = MKPointAnnotation()
    
    var itemsSelected = [IndexPath]()
    
    var loaded = false
        
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
    
    func configureUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        collectionView.isHidden = false
        collectionView.isUserInteractionEnabled = true
        
        noImagesLabel.isHidden = true
        
        mMode = .view
        
        annotationOnMap.coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        map.addAnnotation(annotationOnMap)
        map.showAnnotations(self.map.annotations, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        guard let loadedPhotos = loadSavedPhotos() else {
            return
        }
        
        if loadedPhotos.count > 0 {
            noImagesLabel.isHidden = true
            loaded = true
            photos = loadedPhotos
        } else {
            requestFlickrPhotos()
        }

    }
    
    func requestFlickrPhotos() {
        FlickrAPI.getPhotosJSON(completion: completion(success:error:response:), lat: selectedPin.latitude, long: selectedPin.longitude, page: 1)
    }
    
    func completion(success: Bool, error: Error?, response: FlickrResponse?) {
        DispatchQueue.main.async {
            self.collectionView.isUserInteractionEnabled = false
        }
        
        removeFromCoreData(photos: photos)
        photos.removeAll()
        imagesURL.removeAll()
        if success {
            if let pages = response?.photos.pages {
                totalPages = pages
            }
            if let perPage = response?.photos.perpage {
                self.perPage = perPage
            }
            
            var url = ""
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            if let photos = response?.photos.photo {
                for photo in photos {
                    url = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_q.jpg"
                    imagesURL.append(url)
                    //print(url)
                }
            }
            
            if imagesURL.count > 0 {
                addToCoreData(at: self.selectedPin, of: imagesURL)
                self.photos = loadSavedPhotos()!
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.noImagesLabel.isHidden = true
                    self.newCollectionButton.isEnabled = true
                    self.collectionView.isUserInteractionEnabled = true
                }
                loaded = true
            } else {
                loaded = false
                DispatchQueue.main.async {
                    self.noImagesLabel.isHidden = false
                    self.collectionView.isHidden = true
                    self.newCollectionButton.isEnabled = false
                }
            }
        } else {
            guard Utils.connectedToNetwork() == true else {
                Utils.showAlert(title: "Error", message: "No Internet Connection", view: self)
                return
            }
            Utils.showAlert(title: "Error", message: "Something went wrong", view: self)
        }
    }
    
    func setImage(from url: String) -> Data? {
        guard let imageURL = URL(string: url) else { return nil }
        guard let imageData = try? Data(contentsOf: imageURL) else { return nil }

        if let image = UIImage(data: imageData) {
            let newImage = UIImage.resize(image: image, targetSize: CGSize(width: 39, height: 39))
            return newImage.jpegData(compressionQuality: 1.0)
        } else {
            return nil
        }
    }
    
    func addToCoreData(at pin: Pin?, of urls: [String]) {
        for index in 0..<urls.count {
            let photo = Photo(context: DataController.shared.viewContext)
            photo.pin = pin
            photo.image = setImage(from: urls[index])
            photos.append(photo)

            do {
                try DataController.shared.viewContext.save()
            } catch {
                Utils.showAlert(title: "Error", message: "Something went wrong", view: self)
            }
        }
    }
    
    func removeFromCoreData(photos: [Photo]) {
        for photo in photos {
            DataController.shared.viewContext.delete(photo)
        }
    }
    
    func getIndexes() -> [Int] {
        var indexes:[Int] = []
        let indexPaths = collectionView.indexPathsForSelectedItems!

        for indexPath in indexPaths {
            indexes.append(indexPath.row)
        }
        return indexes
    }
    
    func loadNewCollection() {
        var page: Int {
           if let totalPages = totalPages {
               let page = min(totalPages, 4000/21)
               return Int(arc4random_uniform(UInt32(page)) + 1)
           }
           return 1
       }
        loaded = false
        FlickrAPI.getPhotosJSON(completion: completion(success:error:response:), lat: selectedPin.latitude, long: selectedPin.longitude, page: page)
    }
    
    func loadSavedPhotos() -> [Photo]? {
        do {
            var photos: [Photo] = []
            let fetchedResultsController = self.fetchedResultsController()
            try fetchedResultsController.performFetch()
            
            let photosCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            for index in 0..<photosCount {
                photos.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)) as! Photo)
            }
            return photos
        } catch {
            return nil
        }
    }
    
    func fetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [selectedPin!])
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultController.delegate = self
        return fetchResultController
    }
    
    
    @IBAction func onButtonClick(_ sender: Any) {
        switch mMode {
        case .select:
            if let selectedCells = collectionView.indexPathsForSelectedItems {
                let items = selectedCells.map { $0.item }.sorted().reversed()

                for item in items {
                    DataController.shared.viewContext.delete(photos[item])
                    photos.remove(at: item)
                }
                collectionView.deleteItems(at: selectedCells)
                
                do {
                    try DataController.shared.viewContext.save()
                } catch {
                    Utils.showAlert(title: "Error", message: "Something went wrong", view: self)
                }

            }
            mMode = .view
        case .view:
            removeFromCoreData(photos: photos)
            loadNewCollection()
            newCollectionButton.isEnabled = false   
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if loaded {
            return photos.count
        } else {
            return Constants.PHOTOSPERPAGE
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellCollection = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        if loaded {
            cellCollection.activityIndicator.stopAnimating()
            let photo = photos[indexPath.row]
            cellCollection.imageCell.image = UIImage(data: photo.image!)
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
}
