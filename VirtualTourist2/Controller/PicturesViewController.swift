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
    var dataManager:NSManagedObjectContext!
    var location:CLLocationCoordinate2D!
    //var images = [UIImage]()
    var images = [UIImage](repeating: UIImage(named: "NewYork1.png")!, count: 20)
    
    
    // MARK Outlets
    @IBOutlet weak var picturesCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    // MARK Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        picturesCollection.dataSource = self
        //picturesCollection.delegate = self
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
