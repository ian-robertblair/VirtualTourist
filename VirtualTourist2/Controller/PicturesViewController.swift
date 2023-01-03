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
    var photos = [Photo]()
    var pin:NSManagedObject!
    let pictureLimit = 20  //Limit the number of pictures downloaded
    var firstPage = 1  //photos page
    var numberOfPages = 1
    
    // MARK: -  Outlets
    @IBOutlet weak var picturesCollection: UICollectionView!
    @IBOutlet weak var downloadMessageLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // MARK: -  Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
            let longitude = pin?.value(forKey: "longitude") as! Double
            let latitude = pin?.value(forKey: "latitude") as! Double
            downloadPhotos(FlickrClient.Endpoints.searchLocation( longitude, latitude, firstPage).url)
        } else {
            fetchPhotos()
        }
    }
    
    // MARK: -  Functions
    fileprivate func downloadPhotos(_ url:URL) {
        DispatchQueue.main.async {
            self.downloadMessageLabel.text = "Downloading..."
            self.progressBar.isHidden = false
        }
        
        //put placeholders in DB
        for _ in 1...self.pictureLimit {
            let image = UIImage(named: "placeholder.jpeg")!
            let imageData = NSData(data: image.jpegData(compressionQuality: 1.0)!)
            let newEntry = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: self.dataManager)
            newEntry.setValue(self.pin, forKey: "pin")
            newEntry.setValue(imageData, forKey: "picture")
            newEntry.setValue("placeholder", forKey: "name")
            self.photos.append(newEntry as! Photo)
        }
        
        //Get list of from Flicker
        FlickrClient.searchByLocation(url: url) { flickrPictures, error in
            if let error = error {
                self.defaultLog.info("Failed to download picture URLS.  \(error.localizedDescription)")
                self.FlickrURLsAlert()
            }
            
            DispatchQueue.main.async {
                self.picturesCollection.reloadData()
            }
            
            
            if let flickrPictures = flickrPictures {
                self.defaultLog.info("Search completed.  Page:\(flickrPictures.photos.page)   Pages:\(flickrPictures.photos.pages)  Total: \(flickrPictures.photos.total)")
                for i in 1...self.pictureLimit {
                    self.numberOfPages =  flickrPictures.photos.pages
                    FlickrClient.getPicture(url: FlickrClient.Endpoints.getPicture(flickrPictures.photos.photo[i].server, flickrPictures.photos.photo[i].id, flickrPictures.photos.photo[i].secret).url) { [self] data, error in
                        
                        //Add picture to database
                        let newEntry = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: self.dataManager)
                        newEntry.setValue(self.pin, forKey: "pin")
                        newEntry.setValue(data, forKey: "picture")
                        
                        do {
                            try self.dataManager.save()
                            self.defaultLog.info("Pic saved.")
                        }catch {
                            self.defaultLog.info("Failed to save pictures.")
                        }
                        
                        //Add to array
                        self.photos[i - 1] = newEntry as! Photo
                        
                        // Reload() collection
                        DispatchQueue.main.async {
                            self.picturesCollection.reloadData()
                        }
                        
                        if i == self.pictureLimit {
                            DispatchQueue.main.async {
                                self.progressBar.isHidden = true
                                self.downloadMessageLabel.text = ""
                            }
                            
                            //Delete placeholders
                            let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                            fetchRequest.predicate = NSPredicate(format: "name == %@", "placeholder")
                            var result = [NSManagedObject]()
                            do {
                                result = try self.dataManager.fetch(fetchRequest)
                                for eachPhoto in result {
                                    dataManager.delete(eachPhoto)
                                }
                                try dataManager.save()
                            } catch {
                                defaultLog.info("Failed to delete placeholders from database.  \(error.localizedDescription)")
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.progressBar.progress += 0.05
                            }
                        }
                    }
                }
                
            }
        }
        pin.setValue(true, forKey: "hasPhotos")  ///check if context needs to be saved
    }
    
    fileprivate func fetchPhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "picture", ascending: true)]
        
        do {
            let result = try dataManager.fetch(fetchRequest)
            for eachPhoto in result {
                photos.append(eachPhoto)
            }
        } catch {
            defaultLog.info("Failed to retrieve pictures from database.  \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
            self.picturesCollection.reloadData()
        }
        defaultLog.info("Images Fetched.")
        
    }
    
    fileprivate func FlickrURLsAlert() {
        DispatchQueue.main.async {
            let controller = UIAlertController()
            controller.title = "Flickr Error"
            controller.message = "Failed to download a list of pictures from Flickr."
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { action in
                self.dismiss(animated: true, completion: nil)
            }
            controller.addAction(okAction)
            self.present(controller, animated: true, completion: nil)
        }
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
        self.progressBar.progress = 0.0
        
        //Delete exiting pictures
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "picture", ascending: true)]
        
        var result = [NSManagedObject]()
        do {
            result = try dataManager.fetch(fetchRequest)
            for eachPhoto in result {
                dataManager.delete(eachPhoto)
            }
            try dataManager.save()
        } catch {
            defaultLog.info("Failed to delete pictures from database.  \(error.localizedDescription)")
        }
        
        self.photos.removeAll()
        DispatchQueue.main.async {
            self.picturesCollection.reloadData()
        }
        
        //Download new pictures
        let longitude = pin?.value(forKey: "longitude") as! Double
        let latitude = pin?.value(forKey: "latitude") as! Double
        let randomPage = Int.random(in: 1...numberOfPages)
        downloadPhotos(FlickrClient.Endpoints.searchLocation( longitude, latitude, randomPage).url)
    }
}

//MARK: - Extensions
extension PicturesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "picturesCellView", for: indexPath) as! PicturesCollectionViewCell
        let picture = photos[indexPath.row].value(forKey: "picture") as? Data
        if let picture = picture {
            cell.picture.image = UIImage(data: picture)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defaultLog.info("Item selected: \(indexPath.row)")
        
        dataManager.delete(photos[indexPath.row])
        do {
            try dataManager.save()
        } catch {
            defaultLog.info("Failed to delete photo by selection.  \(error.localizedDescription)")
        }
        
        photos.remove(at: indexPath.row)
        var selectedCell = [IndexPath]()
        selectedCell.append(indexPath)
        DispatchQueue.main.async {
            self.picturesCollection.deleteItems(at: selectedCell)
        }
    }
}


