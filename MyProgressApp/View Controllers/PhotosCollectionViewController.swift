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
    
    //MARK: OUTLETS
    weak var albums: Albums!
    var dataController = DataController.shared.persistentContainer
    var savedPhotos = [Photos]()
    @IBOutlet weak var photoCollectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    let numberOfColumns: CGFloat = 3
    var fetchedResultsController:NSFetchedResultsController<Photos>!
    var photoThumbnail: UIImage!
    
    
    //MARK: SETTING BAR BUTTON ITEMS
    
    @IBOutlet weak var editBtn: UIBarButtonItem! 
    
    lazy var cancelBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBtnPressed(_:)))
        return barBtnItem
    }()
    lazy var deleteBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteBtnPressed(_:)))
        return barBtnItem
    }()
    

    
 
    
    //MARK: FETCH
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
      // -------------------------------------------------------------------------
    //MARK: Make sure Camera is avaialble
    func initToolbars() {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
      // -------------------------------------------------------------------------
    //MARK: View did Load
    override func viewDidLoad() {
        super.viewDidLoad()
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
        setViewLayout()
        navigationItem.title = albums.name
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    @objc func loadList(notification: NSNotification){
        print("loading table from other view")
        savedPhotos = fetchPhotos()!
        showSavedResults()
    }
    
  
    // -------------------------------------------------------------------------
    //MARK: Set up Camera
    /*@IBAction func pickAnImageFromCamera(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
        let mainView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        
        //MARK: Setting the placeholder imagae overlay.
        //TODO: Make Imageview be the latest picture.
        //        let image = UIImage(named: "placeholder")
        //        let imageView = UIImageView(image: image!)
        //        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 600)
        ////        let blockView = UIImage(named: "placeholder")
        //        mainView.addSubview(imageView)
        //        imagePicker.cameraOverlayView = mainView
        //
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
    }*/
    
      // -------------------------------------------------------------------------
    //MARK: Editing Photos
    func savePhotos(image: Data?) {
        
        let photo = Photos(context: dataController.viewContext)
        photo.imageData = image
        photo.creationDate = Date()
        photo.albums = albums
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
    
    func deletePhotos() {
        //TODO: Delete Photos
    }
    
    public func showSavedResults() {
        DispatchQueue.main.async {
            
            self.photoCollectionView.reloadData()
        }
        
    }
      // -------------------------------------------------------------------------
      //MARK: Navigtion
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
////        if (segue.identifier == "photoViewSegue") {
//            if let cell = sender as? UICollectionViewCell,
//                let _ = collectionView.indexPath(for: cell) {
//                 let chosenCell = cell as! PhotoCollectionViewCell
//            photoThumbnail = chosenCell.img.image
//        let destViewController : PhotoDetailViewController = segue.destination as! PhotoDetailViewController
//        destViewController.selectedImage = photoThumbnail
//                destViewController.albums = self.albums
//
//            print("prepare ran")
//         }
//    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !self.collectionView.allowsMultipleSelection
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
        if (segue.identifier == "showCameraView") {
            let destViewController : CameraViewController = segue.destination as! CameraViewController
            destViewController.albums = self.albums
            print("prepare ran")
        }
        else{
             if editBtn.isEnabled == true {
            if let cell = sender as? UICollectionViewCell,
                let _ = collectionView.indexPath(for: cell) {
                let chosenCell = cell as! PhotoCollectionViewCell
                photoThumbnail = chosenCell.img.image
                let destViewController : PhotoDetailViewController = segue.destination as! PhotoDetailViewController
                destViewController.selectedImage = photoThumbnail
                destViewController.albums = self.albums
                }
            }
        }
    }
    
    
    
    //MARK: FUNCTIONS OF BAR BUTTON ITEMS
    
    @IBAction func editBtnPressed(_ sender: UIBarButtonItem) {
        editBtn.isEnabled = false
        navigationItem.leftBarButtonItems = [cancelBtn, deleteBtn]
        photoCollectionView.allowsMultipleSelection = true
    }
    
    
    @objc func cancelBtnPressed(_ sender: UIBarButtonItem) {
        editBtn.isEnabled = true
        navigationItem.leftBarButtonItems = nil
        photoCollectionView.allowsMultipleSelection = false
        deselectAllItems(animated: true)
        photoCollectionView.reloadData()
    }
    
    func deselectAllItems(animated: Bool) {
        guard let selectedItems = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in selectedItems { photoCollectionView.deselectItem(at: indexPath, animated: animated)
            
        }
    }
    
    @objc func deleteBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = photoCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                let savedPhoto = savedPhotos[indexPath.row]
                for photo in savedPhotos {
                    if photo.imageData == savedPhoto.imageData {
                        DataController.shared.viewContext.delete(photo)
                        try? DataController.shared.viewContext.save()
                    }
                }
            }
            savedPhotos = fetchPhotos()!
            showSavedResults()
            editBtn.isEnabled = true
            navigationItem.leftBarButtonItems = nil
        }
        
    }
    
    
    
    
    
    
}

  // -------------------------------------------------------------------------
  //MARK: Collection View Details

extension PhotosCollectionViewController  {
    
    func setViewLayout() {
        photoCollectionViewFlowLayout.scrollDirection = .vertical
        photoCollectionViewFlowLayout.minimumLineSpacing = 0
        photoCollectionViewFlowLayout.minimumInteritemSpacing = 0
        photoCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        print(fetchedResultsController.sections?.count ?? 0)
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photos = savedPhotos[indexPath.row]
        
        cell.img.image = UIImage(data: photos.imageData! as Data)

        if cell.isSelected == true {
            cell.layer.borderColor = UIColor.blue.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 3
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
           if editBtn.isEnabled == false {
               let cell = collectionView.cellForItem(at: indexPath)
                   cell?.layer.borderColor = UIColor.blue.cgColor
                   cell?.layer.borderWidth = 3
                   cell?.isSelected = true
               }
           }
    
    //FUNCTION FOR DESELECTING CELLS
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.clear.cgColor
            cell?.layer.borderWidth = 3
            cell?.isSelected = false
    }
    
//    func deselectAllItems(animated: Bool) {
//        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
//        for indexPath in selectedItems { deselectItem(at: indexPath, animated: animated) }
//    }
    
 
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
    
    //MARK: Set up collection View Layout
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = collectionView.frame.width / numberOfColumns
//        return CGSize(width: width, height: width)
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return .zero
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let totalwidth = collectionView.bounds.size.width;
        let numberOfCellsPerRow = 3
        let oddEven = indexPath.row / numberOfCellsPerRow % 2
        let dimensions = CGFloat(Int(totalwidth) / numberOfCellsPerRow)
        if (oddEven == 0) {
            return CGSize(width: dimensions, height: dimensions)
        } else {
            return CGSize(width: dimensions, height: dimensions / 2)
        }
    }
    
    
    
    
}
