//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapView: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var firstTimeButtonClick = true
    
    var dataController:DataController!
    
    var pins: [Pin] = []
    var selectedAnnotation: MKPointAnnotation!
    var fetchedResults: NSFetchedResultsController<Pin>!

    
    enum Mode {
         case normal
         case deletion
     }
    var mMode: Mode = .normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.title = "Virtual Tourist"
        deleteButton.isHidden = true
        setupMap()
        
        var appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        setupFetchedResults()
        
        for pin in fetchedResults.fetchedObjects ?? [] {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            pins.append(pin)
            mapView.addAnnotation(annotation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResults()
    }
    
    func setupMap() {
        mapView.delegate = self
        let mapPress = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapView.addAnnotation(_:)))
        mapPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(mapPress)
        
    }
    
    @objc func addAnnotation(_ recognizer: UIGestureRecognizer){
        if recognizer.state == UIGestureRecognizer.State.began {
            let annotations = self.mapView.annotations
            let touchedAt = recognizer.location(in: self.mapView)
            let newCoordinates : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = newCoordinates.latitude
            pin.longitude = newCoordinates.longitude
            pin.coordinateString = "&lat=\(pin.latitude)&lon=\(pin.longitude)"

            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            self.mapView.addAnnotation(annotation)
            
            try? dataController.viewContext.save()
            pins.append(pin)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pinAnnotation"
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier: identifier)
            annotationView.isEnabled = true
            annotationView.canShowCallout = true

            return annotationView
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAnnotation = view.annotation as? MKPointAnnotation
        if view.isSelected {
            switch mMode {
            case .normal:
                performSegue(withIdentifier: "moveToPhotos", sender: self)
                self.mapView.deselectAnnotation(selectedAnnotation!, animated: true)
                
            case .deletion:
                
                if let annotation = selectedAnnotation {
                    
                    for pin in pins {
                        if pin.latitude == (annotation.coordinate.latitude) && pin.longitude == (annotation.coordinate.longitude) {
                            
                            let annotationToRemove = view.annotation
                            self.mapView.removeAnnotation(annotationToRemove!)
                            dataController.viewContext.delete(pin)
                            try? dataController.viewContext.save()
                            
                            break
                        }
                    }
                    self.mapView.removeAnnotation(annotation)
                    self.mapView.deselectAnnotation(annotation, animated: true)
                    
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moveToPhotos" {
            if let viewController = segue.destination as? PhotoAlbumViewController {
                var touchedPin: Pin?
                
                for pin in pins {
                    let latitudeMatch = selectedAnnotation!.coordinate.latitude == pin.latitude
                    let longitudeMatch = selectedAnnotation!.coordinate.longitude == pin.longitude

                    if latitudeMatch && longitudeMatch {
                        touchedPin = pin
                        break
                    }
                }
                viewController.selectedPin = touchedPin
                viewController.dataController = dataController
            }
        }
    }
    
    @IBAction func onEditClick(_ sender: Any) {
        if firstTimeButtonClick {
            editButton.title = "Done"
            firstTimeButtonClick = false
            deleteButton.isHidden = false
            mMode = .deletion
        } else {
            editButton.title = "Edit"
            deleteButton.isHidden = true
            firstTimeButtonClick = true
            mMode = .normal
        }
    }
}


extension TravelLocationMapView: NSFetchedResultsControllerDelegate {
    func setupFetchedResults() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "coordinateString", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResults = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResults.delegate = self
        do {
            try fetchedResults.performFetch()
        } catch {
            fatalError("Error: \(error.localizedDescription)")
        }
    }

}
