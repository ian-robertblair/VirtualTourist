//
//  PicturesViewController.swift
//  VirtualTourist2
//
//  Created by ian robert blair on 2021/11/30.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import OSLog

class PicturesViewController: UIViewController {

    
    // MARK: -  Properties
    let defaultLog = Logger()
    var dataManager:NSManagedObjectContext!
    var images = [UIImage]()
    var pin:NSManagedObject!
    let pictureLimit = 30  //Limit the number of pictures downloaded
    
    // MARK: -  Outlets
    @IBOutlet weak var picturesCollection: UICollectionView!
    @IBOutlet weak var downloadMessageLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // MARK: -  Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResults()
        picturesCollection.dataSource = self
        picturesCollection.delegate = self
        downloadMessageLabel.text = ""
        progressBar.isHidden = true
        progressBar.progress = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let hasPhotos = pin.value(forKey: "hasPhotos") as! Bool
        if !hasPhotos {
        images = [UIImage](repeating: UIImage(named: "placeholder.jpeg")!, count: pictureLimit)
            downloadPhotos()
        } else {
            setupFetchedResults()
        }
    }
    
    // MARK: -  Functions
    fileprivate func downloadPhotos() {
        DispatchQueue.main.async {
            self.downloadMessageLabel.text = "Downloading..."
            self.progressBar.isHidden = false
        }
        
        //Get list of from Flicker
        let longitude = pin?.value(forKey: "longitude") as! Double
        let latitude = pin?.value(forKey: "latitude") as! Double
        FlickrClient.searchByLocation(url: FlickrClient.Endpoints.searchLocation( longitude, latitude).url) { flickrPictures, error in
            if let error = error {
                self.defaultLog.info("Failed to download picture URLS.  \(error.localizedDescription)")
                self.FlickrURLsAlert()
            }
            
            if let flickrPictures = flickrPictures {
                for i in 1...self.pictureLimit {
                    FlickrClient.getPicture(url: FlickrClient.Endpoints.getPicture(flickrPictures.photos.photo[i].server, flickrPictures.photos.photo[i].id, flickrPictures.photos.photo[i].secret).url) { data, error in

                        let newEntry = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: self.dataManager)
                        newEntry.setValue(self.pin, forKey: "pin")
                        newEntry.setValue(data, forKey: "picture")
                        do {
                            try self.dataManager.save()
                            self.defaultLog.info("Pic saved. \(flickrPictures.photos.photo[i].title)")
                        }catch {
                            self.defaultLog.info("Failed to save pic. \(flickrPictures.photos.photo[i].title)")
                            self.FlickrPictureDownloadAlert(imageName: flickrPictures.photos.photo[i].title)
                        }
                        
                        self.images[i-1] = UIImage(data: data!)!
                        if i == self.pictureLimit {
                            DispatchQueue.main.async {
                                self.progressBar.isHidden = true
                               self.downloadMessageLabel.isHidden = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.progressBar.progress += 0.05
                                self.picturesCollection.reloadData()
                            }
                        }
                    } //end getPicture
                }
            }
        }
        pin.setValue(true, forKey: "hasPhotos")  ///check if context needs to be saved
    }
    
    fileprivate func setupFetchedResults() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "picture", ascending: true)]

        do {
            let result = try dataManager.fetch(fetchRequest)
            //try fetchedResultsController.performFetch()
            for eachPhoto in result {
                self.images.append(UIImage(data: eachPhoto.picture!)!)
            }
        } catch {
            defaultLog.info("Failed to retrieve pictures from database.  \(error.localizedDescription)")
        }
        defaultLog.info("Images Fetched. \(self.images)")

    }
    
    fileprivate func FlickrURLsAlert() {
        let controller = UIAlertController()
        controller.title = "Flickr Error"
        controller.message = "Failed to download a list of pictures from Flickr."
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }
    
    fileprivate func FlickrPictureDownloadAlert(imageName:String) {
        let controller = UIAlertController()
        controller.title = "Flickr Error"
        controller.message = "Failed to download photo: \(imageName)"
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }
    
    // MARK: -  Actions
    @IBAction func downButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func newCollectionButtonTapped(_ sender: UIButton) {
        images = [UIImage](repeating: UIImage(named: "placeholder.jpeg")!, count: pictureLimit)
        downloadPhotos()
    }
}

//MARK: - Extensions
extension PicturesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //TODO: - add placeholder image
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "picturesCellView", for: indexPath) as! PicturesCollectionViewCell
        let picture = images[indexPath.row]
        cell.picture.image = picture
        return cell
    }
}


