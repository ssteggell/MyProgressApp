//
//  CameraViewController.swift
//  MyProgressApp
//
//  Created by Spencer Steggell on 6/18/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    @IBOutlet weak var previousPhotoImage: UIImageView!
    @IBOutlet weak var photoSlider: UISlider!
    @IBOutlet weak var lightView: UIView!
    @IBOutlet weak var takePhotoButton: UIBarButtonItem!
    @IBOutlet weak var countdownLabel: UILabel!
    
    var previousPhoto: UIImage!
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var myTimer: Timer = Timer()
    var count: Int = 5
    
    var dataController = DataController.shared.persistentContainer
    weak var albums: Albums!
    var savedPhotos = [Photos]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        if let getImage = previousPhoto
        {
            let flippedImage = getImage.withHorizontallyFlippedOrientation()
            
            previousPhotoImage.image = flippedImage
        } else {
            photoSlider.isHidden = true
        }
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = .photo
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            else {
                print("Unable to access back camera!")
                return
        }
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession!.canAddInput(input) && captureSession!.canAddOutput(stillImageOutput!) {
                captureSession!.addInput(input)
                captureSession!.addOutput(stillImageOutput!)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countdownLabel.isHidden = true
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = photoPreviewImageView.bounds
    }
    
    
    
    
    //MARK: Setting up live preview for camera
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        
        videoPreviewLayer!.videoGravity = .resizeAspectFill
        videoPreviewLayer?.connection?.videoOrientation = .portrait
        photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession!.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer?.frame = self.photoPreviewImageView.bounds
            }
        }
        
    }
    //MARK: Take photo: Starts countdown timer of 5, and does a flash to let user know a photo was taken.
    @IBAction func didPressPhotoButton() {
        print("taking Photo")
        takePhotoButton.isEnabled = false
        countdownLabel.isHidden = false
        let seconds = 5.0
        startCountdown()
        //countdownLabel.text = String(seconds)
        
        print("taking Photo in 5 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.flashAnimation()
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
            self.countdownLabel.isHidden = true
            self.takePhotoButton.isEnabled = true
            self.count = 5
        }
    }
    
    //Used to start the countdown
    func startCountdown(){
        myTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(myUpdate), userInfo: nil, repeats: true)
        
    }
    
    //Updates the countdown Label to reflect time left
    @objc func myUpdate() {
        if(count > 0) {
            count -= 1
            countdownLabel.text = "\(count)"
        }
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        let image = UIImage(data: imageData)
        let newImage = rotateImage(image: image!)
        savePhotos(image: newImage?.pngData())
        print(image!.pngData()!)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    //PHOTO saves in wrong orientation, rotates image to save in correct orientation
    func rotateImage(image: UIImage) -> UIImage? {
        if (image.imageOrientation == UIImage.Orientation.up ) {
            return image
        }
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return copy
    }
    
    func savePhotos(image: Data?) {
        
        let photo = Photos(context: dataController.viewContext)
        photo.imageData = image
        photo.creationDate = Date()
        photo.albums = albums
        savedPhotos.append(photo)
        
        do {
            try dataController.viewContext.save()
            print("Image is saved")
            print(savedPhotos.count)
        } catch {
            print("Image is not saved \(error.localizedDescription)")
            
            
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    //MARK: Slider to change the transparency of the previous photo
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        previousPhotoImage.alpha = CGFloat(sender.value)
    }
    
    //MARK: - Take Screenshot Animation
    func flashAnimation() {
        self.view.bringSubviewToFront(lightView)
        lightView.alpha = 0
        lightView.isHidden = false
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut], animations: {() -> Void in
            self.lightView.alpha = 1.0
            AudioServicesPlayAlertSound(1108)
        }, completion: {(finished: Bool) -> Void in
            self.hideFlashView()
        })
    }
    
    func hideFlashView() {
        UIView.animate(withDuration: 0.1, delay: 0.0, animations: {() -> Void in
            self.lightView.alpha = 0.0
        })
    }
}
