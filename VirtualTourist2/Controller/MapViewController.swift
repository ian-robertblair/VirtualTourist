//
//  MapViewController.swift
//  VirtualTourist2
//
//  Created by ian robert blair on 2021/11/30.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import OSLog

class MapViewController: UIViewController {

    // MARK: -  Properties
    let defaultLog = Logger()
    var dataManager:NSManagedObjectContext!
    var databaseLocations = [NSManagedObject]()
    var location = CLLocationCoordinate2D()
    
    // MARK: -  Outlets
    @IBOutlet weak var map: MKMapView!
    
    
    // MARK: -  Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = appDelegate.persistentContainer.viewContext
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for eachLocation in databaseLocations {
            let point = MKPointAnnotation()
            let longitude = eachLocation.value(forKey: "longitude") as! Double
            let latitude = eachLocation.value(forKey: "latitude") as! Double
            point.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.map.addAnnotation(point)
        }
    }
    
    //MARK: -  Functions
    func fetchData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Pin")
        do {
            let result = try dataManager.fetch(fetchRequest)
            databaseLocations = result as! [NSManagedObject]
            defaultLog.info("Database Locations Fetched.")
            for eachLocation in databaseLocations {
                let longitude = eachLocation.value(forKey: "longitude") as! Double
                let latitude = eachLocation.value(forKey: "latitude") as! Double
                defaultLog.info("Database Entry.  Longitude: \(longitude)   Latitude: \(latitude)")
            }
        } catch {
            defaultLog.info("Failed to retrieve locations from database.  \(error.localizedDescription)")
        }
    }
    
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "picturesViewSegue" {
            let controller = segue.destination as! PicturesViewController
            controller.location = location
            controller.dataManager = dataManager
        }
    }
    
    //MARK: -  Actions
    @IBAction func longpressDetected(_ sender: UILongPressGestureRecognizer) {
        defaultLog.info("Long press detected.")
        
        //Add map point
        let point = MKPointAnnotation()
        let touchPoint = sender.location(in: map)
        let touchMapCoordinate = map.convert(touchPoint, toCoordinateFrom: map)
        point.coordinate = CLLocationCoordinate2D(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
        map.addAnnotation(point)
        
        //Add location to database
        let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: dataManager)
        newEntity.setValue(touchMapCoordinate.latitude, forKey: "latitude")
        newEntity.setValue(touchMapCoordinate.longitude, forKey: "longitude")
        do {
            try self.dataManager.save()
            defaultLog.info("Saved to database: lon: \(touchMapCoordinate.longitude), lat: \(touchMapCoordinate.latitude)")
        } catch {
            defaultLog.info("Failed to save location.  \(error.localizedDescription)")
        }
    }
}

//MARK: - Extensions
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //TODO: - remove callout
        guard annotation is MKPointAnnotation else {return nil}
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
            annotationView!.rightCalloutAccessoryView = UIButton(type: .infoLight)
        } else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        location = view.annotation!.coordinate
        performSegue(withIdentifier: "picturesViewSegue", sender: self)
    }
}
