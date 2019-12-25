//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationMapView: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var selectedAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            self.mapView.addAnnotation(annotation)
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
        self.selectedAnnotation = view.annotation as! MKPointAnnotation
        performSegue(withIdentifier: "moveToPhotos", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moveToPhotos" {
            if let viewController = segue.destination as? PhotoAlbumViewController {
                viewController.latitude = (self.selectedAnnotation?.coordinate.latitude)!
                viewController.longitude = (self.selectedAnnotation?.coordinate.longitude)!
            }
        }
    }
    
}

