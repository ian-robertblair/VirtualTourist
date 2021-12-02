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

    
    // MARK Properties
    let defaultLog = Logger()
    var dataManager:NSManagedObjectContext!
    var location:CLLocationCoordinate2D!
    var images = [UIImage](repeating: UIImage(named: "NewYork1.png")!, count: 20)
    
    
    // MARK Outlets
    @IBOutlet weak var picturesCollection: UICollectionView!
    @IBOutlet weak var downloadMessageLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // MARK Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        picturesCollection.dataSource = self
        downloadMessageLabel.text = ""
        progressBar.isHidden = true
        progressBar.progress = 0.0
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let picturesExtist = false
        
        if picturesExtist {
            //TODO: - write code to replace placeholders with pictures from the database as they are retrived.
        } else {
            //TODO: - Set label to "downloading...", make progressbar visable, download flickr picture list, get the pictures, add to progressBar for each picture downloaded, store them in db, update the UI, clear label, hide progressBar
            downloadMessageLabel.text = "Downloading..."
            progressBar.isHidden = false
            FlickrClient.searchByLocation(url: FlickrClient.Endpoints.searchLocation( location.longitude, location.latitude).url) { flickrPictures, error in
                if let error = error {
                    self.defaultLog.info("Failed to download picture URLS.  \(error.localizedDescription)")
                }
                
                if let flickrPictures = flickrPictures {
                    for flickrPicture in flickrPictures.photos.photo {
                        self.defaultLog.info("Picture id: \(flickrPicture.id) name: \(flickrPicture.title)")
                        FlickrClient.getPicture(url: FlickrClient.Endpoints.getPicture(flickrPicture.server, flickrPicture.id, flickrPicture.secret).url) { data, error in
                            //TODO: - Add to database
                            print("Picture Size:", data!)
                            DispatchQueue.main.async {
                                                        self.progressBar.progress += 0.02
                                                    }
                        }
                    }
                }
            }
        }
    }
    
    // MARK Functions
    
    
    // MARK Actions
    @IBAction func downButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension PicturesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "picturesCellView", for: indexPath) as! PicturesCollectionViewCell
        cell.picture.image = images[indexPath.row]
        return cell
    }
}
