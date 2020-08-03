//
//  PhotoAlbumViewController.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 6/14/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import CoreData
import UIKit

//TODO: FIX SEGUE  AND FIX THE DATA CONTROLLER CLASS SO DATACONTROLLER = DATACONTROLLER!

class PhotoAlbumViewController: UITableViewController {
    
    @IBOutlet var photoAlbumTable: UITableView!
    var dataController = DataController.shared.persistentContainer
    
   var fetchedResultsController:NSFetchedResultsController<Albums>!
    
    fileprivate func setUpFetchedResultsController() {
        let context = dataController.viewContext
        let fetchRequest:NSFetchRequest<Albums> = Albums.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        print("performingfetchagain")
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "albums")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch Request Failed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Loaded, attempting fetch")
        setUpFetchedResultsController()
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        fetchedResultsController = nil
    }
    
    @IBAction func addNewAlbum(_ sender: Any) {
        presentNewNotebookAlert()
       DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
    
    
    func presentNewNotebookAlert() {
        let alert = UIAlertController(title: "New Photo Album", message: "Enter name for album", preferredStyle: .alert)

        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.addPhotoAlbum(name: name)

            }
        }
        saveAction.isEnabled = false

        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
            
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
    
    }
    
    func addPhotoAlbum(name: String) {
        let album = Albums(context: dataController.viewContext)
        album.name = name
        album.creationDate = Date()
        try? dataController.viewContext.save()

        
    }
    
    func updateEditButtonState() {
           if let sections = fetchedResultsController.sections {
               navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
           }
       }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func deleteAlbum(at indexPath: IndexPath) {

           let albumToDelete = fetchedResultsController.object(at: indexPath)
          dataController.viewContext.delete(albumToDelete)
          try? dataController.viewContext.save()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCell

        // Configure cell
//        cell.nameLabel.text = album.name
        cell.nameLabel.text = album.name
//        cell.imageView = UIImage(named: "placeholder")
        //TODO: MAKE LATEST OR FIRST PHOTO THE DEFAULT IMAGE

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
           switch editingStyle {
           case .delete: deleteAlbum(at: indexPath)
           default: () // Unsupported
           }
       }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if let vc = segue.destination as? PhotosCollectionViewController {
           if let indexPath = tableView.indexPathForSelectedRow {
            vc.albums = fetchedResultsController.object(at: indexPath)
//            vc.dataController = dataController
//            self.navigationController?.popViewController(animated: true)
           }
//        navigationController?.pushViewController(vc, animated: true)
       }
   }
//    let CellDetailIdentifier = "CellDetailIdentifier"
//
//     func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        switch segue.identifier! {
//        case CellDetailIdentifier:
//            let destination = segue.destination as! PhotosCollectionViewController
//            let indexPath = tableView.indexPathForSelectedRow!
//            let selectedObject = fetchedResultsController.object(at: indexPath)
//            destination.albums = selectedObject
//        default:
//            print("Unknown segue: \(segue.identifier)")
//        }
//    }
    
    
    
}


extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange andObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        default:
            break
        }
    }

}

