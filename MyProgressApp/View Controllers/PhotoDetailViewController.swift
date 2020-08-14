//
//  NewPicViewController.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 6/14/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import AVFoundation

class PhotoDetailViewController: UIViewController {
    
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var selectedImage: UIImage!
    var albums: Albums!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let getImage = selectedImage
        {
            selectedImageView.image = getImage
        }
    }
    
    //Prepare for camera segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "showCameraView") {
            
            let destViewController : CameraViewController = segue.destination as! CameraViewController
            destViewController.previousPhoto = selectedImage.self
            destViewController.albums = self.albums
            print("prepare ran")
        }
    }
    
    //Share button pressed to save photo or send to others
    @IBAction func sharePressed(_ sender: Any) {
        let controller = UIActivityViewController(activityItems: [selectedImage!], applicationActivities: nil)
        
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> () in
            if (completed) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.present(controller, animated: true, completion: nil)
    }
}
