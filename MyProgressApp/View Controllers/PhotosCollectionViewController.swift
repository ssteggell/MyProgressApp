//
//  PhotosCollectionViewController.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 6/15/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PhotosCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
//    var albums: Albums!
    weak var albums: Albums!
    var dataController = DataController.shared.persistentContainer
    var savedPhotos = [Photos]()
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    var fetchedResultsController:NSFetchedResultsController<Photos>!
    
    
    func fetchPhotos() -> [Photos]? {
        var photoArray: [Photos] = []
        let fetchRequest: NSFetchRequest<Photos> = Photos.fetchRequest()
        let context = dataController.viewContext 
        let predicate = NSPredicate(format: "albums == %@", albums)

        print("Predicate: \(predicate)")
//        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
//            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            print("photoCount: \(photoCount)")
            print("Performing Fetch")
            for index in 0..<photoCount {
                print("Counting Photos")
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
                print("Photo Array: \(photoArray.count)")
            }
            print("Photo Array: \(photoArray.count)")
            return photoArray
        } catch {
            fatalError("Fetch Request Failed: \(error.localizedDescription)")
        }
    }
    
    /*func fetchImage() -> [Photos]? {
        var fetchingImage: [Photos] = []
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
        let context = DataController.shared.persistentContainer.viewContext
//        let predicate = NSPredicate(format: "albums == %@", argumentArray: [albums!])
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
//        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
    do {
        fetchingImage = try context.fetch(fetchRequest) as! [Photos]
    } catch {
    print("Error while fetching the image")
    }

        print("fetching...")
        print(fetchingImage.count)
    return fetchingImage
    }*/
    
    func initToolbars() {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let savedPhoto = fetchImage()
      let savedPhoto = fetchPhotos()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            savedPhotos = savedPhoto!
          showSavedResults()
            print("Showing saved results")
        } else {
            //            showNewResult()
            print("No photos, add some!")
        }
        initToolbars()
        navigationItem.title = albums.name
        //            navigationItem.rightBarButtonItem = editButtonItem
        
        
        
        
    }
    
    //    func pickAnImage(sourceType: UIImagePickerController.SourceType) {
    //        let imagePicker = UIImagePickerController()
    //        imagePicker.delegate = self
    //        imagePicker.sourceType = sourceType
    //        present(imagePicker, animated: true, completion: nil)
    //
    //    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        //         pickAnImage(sourceType: .camera)
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
        let mainView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height-150))
        let blockView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 150))
        blockView.backgroundColor = UIColor.red
        mainView.addSubview(blockView)
        imagePicker.cameraOverlayView = mainView
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        // print out the image size as a test
        savePhotos(image: image.pngData())
        print(image.pngData()!)
        
    }
    
    func savePhotos(image: Data?) {
       
        let photo = Photos(context: dataController.viewContext)
        photo.imageData = image
        photo.creationDate = Date()
        savedPhotos.append(photo)
        //        try? DataController.shared.persistentContainer.viewContext.save()
        do {
            try dataController.viewContext.save()
            print("Image is saved")
            print(savedPhotos.count)
            showSavedResults()
        } catch {
            print("Image is not saved \(error.localizedDescription)")
            
            
        }
    }
    
    func showSavedResults() {
        DispatchQueue.main.async {
            
            self.photoCollectionView.reloadData()
            //                   self.newCollectionButton.isEnabled = true
        }
        
    }
    
}
extension PhotosCollectionViewController  {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        print(fetchedResultsController.sections?.count ?? 0)
       return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //         let photos = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        
        //        let photo = photos[indexPath.row]
//        let photos = [Photos].self
        let photos = savedPhotos[indexPath.row]
        //        if photo. != nil {
        //        DispatchQueue.main.async {
        cell.img.image = UIImage(data: photos.imageData! as Data)
        //           cell.img.image = UIImage(named: "placeholder")
        //           cell.activityIndicator.startAnimating()
        
        //           cell.initWithPhoto(photo)
        //           cell.activityIndicator.stopAnimating()
        
        if cell.isSelected {
            cell.layer.borderColor = UIColor.blue.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 3
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3
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
    
    
    
    
}
