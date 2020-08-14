//
//  MotviationViewController.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 7/30/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class MotivationViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout  {
    
    @IBOutlet var flickrCollectionView: UICollectionView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    
    var fPhotos : [FlickrPhoto] = []
    var savedPhotos = [Photo]()
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var currentPage = 0
    let numberOfColumns: CGFloat = 3
    var flickrClient = FlickrClient()
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        flickrCollectionView.delegate = self
        flickrCollectionView.dataSource = self
        
        let savedPhoto = fetchPhotos()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            savedPhotos = savedPhoto!
            showSavedResult()
            print("Showing saved results")
        } else {
            showNewResult()
            print("showing new results")
        }
    }
    
    //MARK: Fetch request to pull URL Strings
    fileprivate func fetchPhotos() -> [Photo]? {
        var photoArray: [Photo] = []
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "urlString", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            
            for index in 0..<photoCount {
                
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
                print("Photo Array: \(photoArray.count)")
            }
            return photoArray
        } catch {
            print("error performing fetch")
            let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alertVC, animated: true)
            return nil
        }
    }
    
    
    
    // API Request to pull the photos
    func getFlickrPhotos(page: Int){
        
        FlickrClient.sharedInstance.getPhotoUrl(page: currentPage) { (photos, error) in
            
            if let error = error {
                print("Error pulling data from Flickr")
                let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alertVC, animated: true)
                print(error.localizedDescription)
                return
            } else {
                if let photos = photos {
                    DispatchQueue.main.async {
                        self.fPhotos = photos
                        self.saveToCoreData(photos : photos)
                        if photos.count == 0 {
                            let alertVC = UIAlertController(title: "Error", message: "No Photos From Flickr Found", preferredStyle: .alert)
                            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                            self.present(alertVC, animated: true)
                        } else {
                            print("\(photos.count) fetched")
                            self.flickrCollectionView.reloadData()
                            self.savedPhotos = self.fetchPhotos()!
                            self.showSavedResult()
                            print("\(photos.count) fetched")
                        }
                    }
                }
            }
        }
    }
    
    //SAVE to Core Data, refresh, delete from Core Data, Update view
    func saveToCoreData(photos: [FlickrPhoto]) {
        for flickrPhoto in photos {
            let photo = Photo(context: DataController.shared.viewContext)
            photo.urlString = flickrPhoto.imageURLString()
            savedPhotos.append(photo)
            DataController.shared.save()
            print("\(savedPhotos.count) saved")
        }
    }
    
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        
        deleteFromCoreData()
        currentPage += 1
        getFlickrPhotos(page: currentPage)
    }
    
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.flickrCollectionView.reloadData()
            
        }
    }
    
    func showNewResult() {
        savedPhotos.removeAll()
        getFlickrPhotos(page: currentPage)
    }
    
    
    func deleteFromCoreData() {
        
        for image in savedPhotos {
            DataController.shared.viewContext.delete(image)
        }
    }
    
    //MARK: Creating the collection view cells, number of cells, sections, and what is in each cell.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(savedPhotos.count)
        return savedPhotos.count
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! FlickrViewCell
        
        let photo = savedPhotos[indexPath.row]
        cell.flickrImage.image = UIImage(named: "placeholder")
        cell.activityIndicator.startAnimating()
        
        cell.initWithPhoto(photo)
        cell.activityIndicator.stopAnimating()
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / numberOfColumns
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
//    MARK: Next update: Click on flickr photo to enlarge photo
    //    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //       let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
    //        photoThumbnail = cell.img.image
    //
    //
    //        performSegue(withIdentifier: "photoViewSegue", sender: self)
    //        print("didselectran")
    
    //        let item = self.savedPhotos[indexPath.row]
    //        self.img.image = UIImage(data: item.imageData! as Data)
    //        self.performSegueWithIdentifier("yourIdentifier")
    
    //         let selectedCell = collectionView.cellForItem(at: indexPath)
    //        let cellInYourType = selectedCell as! PhotoCollectionViewCell
    //        let image = cellInYourType.img.image
    //        self.performSegue(withIdentifier: "SelectedPhoto", sender: any)
    //        let vc = sender as? UICollectionViewCell as! PhotoCollectionViewCell
    //        vc.imageEnlarged = image;
    //        self.present(vc, animated: true, completion: nil)
    //    }
    
}


