//
//  FlickrViewCell.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 8/4/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit

class FlickrViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var flickrImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //Initialize cell with photo
    func initWithPhoto(_ photo: Photo) {
        if photo.imageData != nil {
            DispatchQueue.main.async {
                self.flickrImage.image = UIImage(data: photo.imageData! as Data)
            }
        } else {
            downloadImage(photo)
        }
    }
    
    //Download Image if image is not available.
   func downloadImage(_ photo: Photo) {
          URLSession.shared.dataTask(with: URL(string: photo.urlString!)!) { (data, response, error) in
              if error == nil {
                  DispatchQueue.main.async {
                      self.flickrImage.image = UIImage(data: data! as Data)
                      self.saveImageDataToCoreData(photo, imageData: data! as Data)
                  }
              }
          }
          .resume()
      }
    
    
    //Save Image to Core Data
    func saveImageDataToCoreData(_ photo: Photo, imageData: Data) {
        do {
            photo.imageData = imageData
            try DataController.shared.viewContext.save()
        } catch {
            print("saving photo image failed")
        }
    }


}
