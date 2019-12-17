//
//  VirtualTouristViewController.swift
//  VirtualTourist
//
//  Created by Hajar F on 12/3/19.
//  Copyright © 2019 Hajar F. All rights reserved.
//
 

import UIKit
import CoreData
import MapKit


class VirtualTouristViewController: UIViewController, MKMapViewDelegate {
    
    let segue = "PhotoCollectionSegue"
    var shouldDelete = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Pin] {
                for pin in result {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude),longitude: CLLocationDegrees(pin.longitude))
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            print("Couldn't find any Pins")
        }
        
    }
    
    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKPinAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin")
            as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.animatesDrop = true
        }
        
        return view
    }
    
    @IBAction func longPress(_ sender: Any) {
        if (sender as AnyObject).state == .began {
            let touchLocation = (sender as AnyObject).location(in: mapView)
            let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            let pin = Pin(context: CoreDataStack.shared.context)
            pin.latitude = Double(coordinate.latitude)
            pin.longitude = Double(coordinate.longitude)
            CoreDataStack.shared.save()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        if let annotation = view.annotation {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
            fetchRequest.predicate = predicate
            
            do {
                if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Pin], let pin = result.first {
                    if shouldDelete {
                        CoreDataStack.shared.context.delete(pin)
                        CoreDataStack.shared.save()
                        
                        mapView.removeAnnotation(annotation)
                    } else {
                        performSegue (withIdentifier: segue, sender: pin)
                    }
                }
            } catch {
                print("Couldn't find any Pins")
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segue {
            let vc = segue.destination as! PhotoAlbumViewController
            vc.pin = (sender as! Pin)
        }
    }
}
