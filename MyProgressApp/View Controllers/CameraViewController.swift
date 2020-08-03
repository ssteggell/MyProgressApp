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
    
    var previousPhoto: UIImage!
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var dataController = DataController.shared.persistentContainer
    weak var albums: Albums!
    var savedPhotos = [Photos]()
    
    
    //let fetchPhotos(): PhotosCollectionViewController.fetchPhotos()
    
    
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
        
      
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = photoPreviewImageView.bounds
    }
    
    
    
    
    
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
    
   @IBAction func didPressPhotoButton() {
        print("taking Photo")
//    if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
//        videoConnection.videoOrientation = videoPreviewLayerOrientation!
//
    let seconds = 5.0
    print("taking Photo in 5 seconds")
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        self.flashAnimation()
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
//        }
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
        //        try? DataController.shared.persistentContainer.viewContext.save()
        do {
            try dataController.viewContext.save()
            print("Image is saved")
            print(savedPhotos.count)
        } catch {
            print("Image is not saved \(error.localizedDescription)")
            
            
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
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

    /*
     
     var image: UIImage?
     
     var captureSession = AVCaptureSession()
     var backCamera: AVCaptureDevice?
     var frontCamera: AVCaptureDevice?
     var currentCamera: AVCaptureDevice?
     var photoOutput: AVCapturePhotoOutput?
     var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
     
     //DELEGATE
     var delegate: AVCapturePhotoCaptureDelegate?
     
     func didTapRecord() {
     
     let settings = AVCapturePhotoSettings()
     photoOutput?.capturePhoto(with: settings, delegate: delegate!)
     
     }
     
     override func viewDidLoad() {
     super.viewDidLoad()
     setup()
     }
     func setup() {
     setupCaptureSession()
     setupDevice()
     setupInputOutput()
     setupPreviewLayer()
     startRunningCaptureSession()
     }
     func setupCaptureSession() {
     captureSession.sessionPreset = AVCaptureSession.Preset.photo
     }
     
     func setupDevice() {
     let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
     mediaType: AVMediaType.video,
     position: AVCaptureDevice.Position.unspecified)
     for device in deviceDiscoverySession.devices {
     
     switch device.position {
     case AVCaptureDevice.Position.front:
     self.frontCamera = device
     case AVCaptureDevice.Position.back:
     self.backCamera = device
     default:
     break
     }
     }
     
     self.currentCamera = self.backCamera
     }
     
     
     func setupInputOutput() {
     do {
     
     let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
     captureSession.addInput(captureDeviceInput)
     photoOutput = AVCapturePhotoOutput()
     photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
     captureSession.addOutput(photoOutput!)
     
     } catch {
     print(error)
     }
     
     }
     func setupPreviewLayer()
     {
     self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
     self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
     self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
     self.cameraPreviewLayer?.frame = self.view.frame
     self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
     
     }
     func startRunningCaptureSession(){
     captureSession.startRunning()
     }
     }
     
     
     struct CaptureButtonView: View {
     @State private var animationAmount: CGFloat = 1
     var body: some View {
     Image(systemName: "video").font(.largeTitle)
     .padding(30)
     .background(Color.red)
     .foregroundColor(.white)
     .clipShape(Circle())
     .overlay(
     Circle()
     .stroke(Color.red)
     .scaleEffect(animationAmount)
     .opacity(Double(2 - animationAmount))
     .animation(Animation.easeOut(duration: 1)
     .repeatForever(autoreverses: false))
     )
     .onAppear
     {
     self.animationAmount = 2
     }
     }
     }
     
     */
    
    //    override func viewWillAppear(_ animated: Bool) {
    //       super.viewWillAppear(animated)
    //        self.tabBarController?.tabBar.isHidden = true
    //
    //        session = AVCaptureSession()
    //        session!.sessionPreset = .medium
    //        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    //         else {
    //                print("Unable to access back camera!")
    //                return
    //        }
    //        do {
    //            let input = try AVCaptureDeviceInput(device: frontCamera)
    //           stillImageOutput = AVCapturePhotoOutput()
    //            if session!.canAddInput(input) && session!.canAddOutput(stillImageOutput!) {
    //                session!.addInput(input)
    //                session!.addOutput(stillImageOutput!)
    //                setupLivePreview()
    //            }
    //        }
    //        catch let error  {
    //            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
    //        }
    //    }
    
    ////        var error: NSError?
    ////        var input: AVCaptureDeviceInput!
    ////        do {
    ////          input = try AVCaptureDeviceInput(device: backCamera!)
    ////        } catch let error1 as NSError {
    ////          error = error1
    ////          input = nil
    ////          print(error!.localizedDescription)
    ////        if error == nil && session!.canAddInput(input) {
    ////        session!.addInput(input)
    ////            stillImageOutput = AVCapturePhotoOutput()
    ////            let settings = AVCapturePhotoSettings()
    ////            settings.livePhotoVideoCodecType = .jpeg
    //////            stillImageOutput!.capturePhoto(with: settings, delegate: self)
    //////            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
    ////            if session!.canAddOutput(stillImageOutput!) {
    ////                session!.addOutput(stillImageOutput!)
    ////                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
    ////                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
    ////                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    ////              photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
    ////              session!.startRunning()
    ////            }
    ////        }
    //
    //
    //    override func viewDidAppear(_ animated: Bool) {
    //       super.viewDidAppear(animated)
    //       videoPreviewLayer!.frame = photoPreviewImageView.bounds
    //    }
    //
    //    override func viewWillDisappear(_ animated: Bool) {
    //        super.viewWillDisappear(animated)
    //        self.session!.stopRunning()
    //    }
    //
    
    //
    //        //Step12
    //    }
    //
    //
    //    @IBAction func didTapOnTakePhotoButton(_ sender: Any) {
    //        print("button pressed")
    //
    //       let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    //        stillImageOutput!.capturePhoto(with: settings, delegate: self)
    //    }
    //
    //    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    //
    //        guard let image = photo.fileDataRepresentation() as? UIImage? else {
    //            print("No image found")
    //            return
    //        }
    //        // print out the image size as a test
    //        savePhotos(image: image!.pngData())
    //        print(image!.pngData()!)
    ////        guard let imageData = photo.fileDataRepresentation()
    ////            else { return }
    ////
    ////        let imageData = UIImage(data: imageData)
    ////        photoPreviewImageView.image = image
    ////        savePhotos(image: imageData.pngData())
    ////        print(imageData.pngData()!)
    //    }
    //
    //
    ////    func didPressTakingPhoto() {
    ////        print ("Taking Picture")
    ////        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
    ////            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    ////            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: )
    ////        }
    ////    }
    //
    //
    //         func savePhotos(image: Data?) {
    //        let photo = Photos(context: dataController.viewContext)
    //        photo.imageData = image
    //        photo.creationDate = Date()
    //        photo.albums = albums
    //        savedPhotos.append(photo)
    //        //        try? DataController.shared.persistentContainer.viewContext.save()
    //        do {
    //            try dataController.viewContext.save()
    //            print("Image is saved")
    //            print(savedPhotos.count)
    ////            showSavedResults()
    //        } catch {
    //            print("Image is not saved \(error.localizedDescription)")
    //
    //
    //        }
    //    }
    ///*
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //        self.tabBarController?.tabBar.isHidden = true
    //        session = AVCaptureSession()
    //        session!.sessionPreset = AVCaptureSession.Preset.photo
    //        let frontCamera =  AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    //        var error: NSError?
    //        var input: AVCaptureDeviceInput!
    //        do {
    //            input = try AVCaptureDeviceInput(device: frontCamera!)
    //        } catch let error1 as NSError {
    //            error = error1
    //            input = nil
    //            print(error!.localizedDescription)
    //        }
    //        if error == nil && session!.canAddInput(input) {
    //            session!.addInput(input)
    //            stillImageOutput = AVCapturePhotoOutput()
    ////            stillImageOutput?. = [AVVideoCodecKey:  AVVideoCodecJPEG]
    //            if session!.canAddOutput(stillImageOutput!) {
    //                session!.addOutput(stillImageOutput!)
    //                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
    //                videoPreviewLayer!.videoGravity =    AVLayerVideoGravity.resizeAspect
    //                videoPreviewLayer!.connection?.videoOrientation =   AVCaptureVideoOrientation.portrait
    //                photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
    //                session!.startRunning()
    //            }
    //        }
    //    }
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //        videoPreviewLayer!.frame = photoPreviewImageView.bounds
    //    }
    //
    //
    //
    //    func showCamera() {
    //
    //    }*/
    //}
    //
    //struct CustomCameraPhotoView: View {
    //
    //    @State private var image: Image?
    //    @State private var showingCustomCamera = false
    //    @State private var inputImage: UIImage?
    //
    //    var body: some View {
    //
    //        NavigationView {
    //            VStack {
    //                ZStack {
    //                    Rectangle().fill(Color.secondary)
    //
    //                    if image != nil
    //                    {
    //                        image?
    //                            .resizable()
    //                            .aspectRatio(contentMode: .fill)
    //                    }
    //                    else
    //                    {
    //                        Text("Take Photo").foregroundColor(.white).font(.headline)
    //                    }
    //                }
    //                .onTapGesture {
    //                    self.showingCustomCamera = true
    //                }
    //            }
    //            .sheet(isPresented: $showingCustomCamera, onDismiss: loadImage) {
    //                CustomCameraView(image: self.$inputImage)
    //            }
    //            .edgesIgnoringSafeArea(.all)
    //
    //        }
    //
    //    }
    //    func loadImage() {
    //        guard let inputImage = inputImage else { return }
    //        image = Image(uiImage: inputImage)
    //    }
    //}
    //
    //
    //struct CustomCameraView: View {
    //
    //    @Binding var image: UIImage?
    //    @State var didTapCapture: Bool = false
    //    var body: some View {
    //        ZStack(alignment: .bottom) {
    //
    //            CustomCameraRepresentable(image: self.$image, didTapCapture: $didTapCapture)
    //            CaptureButtonView().onTapGesture {
    //                self.didTapCapture = true
    //            }
    //        }
    //    }
    //
    //}
    //
    //
    //struct CustomCameraRepresentable: UIViewControllerRepresentable {
    //
    //    @Environment(\.presentationMode) var presentationMode
    //    @Binding var image: UIImage?
    //    @Binding var didTapCapture: Bool
    //
    //    func makeUIViewController(context: Context) -> CustomCameraController {
    //        let controller = CustomCameraController()
    //        controller.delegate = context.coordinator
    //        return controller
    //    }
    //
    //    func updateUIViewController(_ cameraViewController: CustomCameraController, context: Context) {
    //
    //        if(self.didTapCapture) {
    //            cameraViewController.didTapRecord()
    //        }
    //    }
    //    func makeCoordinator() -> Coordinator {
    //        Coordinator(self)
    //    }
    //
    //    class Coordinator: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    //        let parent: CustomCameraRepresentable
    //
    //        init(_ parent: CustomCameraRepresentable) {
    //            self.parent = parent
    //        }
    //
    //        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    //
    //            parent.didTapCapture = false
    //
    //            if let imageData = photo.fileDataRepresentation() {
    //                parent.image = UIImage(data: imageData)
    //            }
    //            parent.presentationMode.wrappedValue.dismiss()
    //        }
    //    }
    //}
//}
