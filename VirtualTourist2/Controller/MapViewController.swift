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
    var location = ""
    
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
            point.title = eachLocation.value(forKey: "title") as? String
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
                let name = eachLocation.value(forKey: "locationName") as! String
                let longitude = eachLocation.value(forKey: "longitude") as! Double
                let latitude = eachLocation.value(forKey: "latitude") as! Double
                defaultLog.info("Database Entry.  Name: \(name)  Longitude: \(longitude)   Latitude: \(latitude)")
            }
            
        } catch {
            defaultLog.info("Failed to retrieve locations from database.  \(error.localizedDescription)")
        }
    }
    
    //MARK: - Preare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PictureViewSegue" {
            let controller = segue.destination as! PicturesViewController
            controller.location = location
            controller.dataManager = dataManager
        }
    }
    
    //MARK: -  Actions
    
}

//MARK: - Extensions
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegue(withIdentifier: "savedPicturesSegue", sender: self)
    }
}
