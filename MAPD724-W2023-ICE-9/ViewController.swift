//
//  ViewController.swift
//  MAPD724-W2023-ICE-9
//
//  Created by Muhammad Bilal Dilbar on 2023-04-02.
//

import UIKit
import Vision
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var pictureChoosen: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func getImage(_ sender: UIButton)
    {
        getPhoto()
    }
    
    func getPhoto()
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
     {
         if let gotImage =
         info[UIImagePickerController.InfoKey.originalImage] as? UIImage
         {
             picker.dismiss(animated: true, completion: nil)
             pictureChoosen.image = gotImage
             analyzeImage(image: gotImage)
             identifyFacesWithLandmarks(image: gotImage)
         }
     }
    
    func analyzeImage(image: UIImage)
    {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [ : ])
        messageLabel.text = "Analyzing picture..."
        let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaceRecognition)
        request.usesCPUOnly = true
        try! handler.perform([request])
    }
    
    func handleFaceRecognition(request: VNRequest, error: Error?)
    {
        guard let foundFaces = request.results as? [VNFaceObservation] else
        {
            fatalError ("Can't find a face in the picture")
        }
        messageLabel.text = "Found \(foundFaces.count) faces in the picture"
    }
    
    func identifyFacesWithLandmarks(image: UIImage)
    {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [ : ])
        let request = VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksRecognition)
        request.usesCPUOnly = true
        try! handler.perform([request])
    }
    
    func handleFaceLandmarksRecognition(request: VNRequest, error: Error?)
    {
        guard let foundFaces = request.results as? [VNFaceObservation] else
        {
            fatalError ("Problem loading picture to examine faces")
        }

        for faceRectangle in foundFaces
        {
            guard let landmarks = faceRectangle.landmarks else
            {
                continue
            }
            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
     
            if let faceContour = landmarks.faceContour
            {
                landmarkRegions.append(faceContour)
            }
            if let leftEye = landmarks.leftEye
            {
                landmarkRegions.append(leftEye)
            }
     
            if let rightEye = landmarks.rightEye
            {
                landmarkRegions.append(rightEye)
            }
     
            if let nose = landmarks.nose
            {
                landmarkRegions.append(nose)
            }
            drawImage(source: pictureChoosen.image!,
            boundary: faceRectangle.boundingBox, faceLandmarkRegions: landmarkRegions)
        }
    }
    
    func drawImage(source: UIImage, boundary: CGRect, faceLandmarkRegions:[VNFaceLandmarkRegion2D])
    {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
         let context = UIGraphicsGetCurrentContext()!
         context.translateBy(x: 0, y: source.size.height)
         context.scaleBy(x: 1.0, y: -1.0)
         context.setLineJoin(.round)
         context.setLineCap(.round)
         context.setShouldAntialias(true)
         context.setAllowsAntialiasing(true)
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)

         //Drawing Rectangles Around Faces
         var fillColor = UIColor.systemGreen
         fillColor.setStroke()
         context.setLineWidth(10.0)
         let rectangleWidth = source.size.width * boundary.size.width
         let rectangleHeight = source.size.height * boundary.size.height
         context.addRect(CGRect(x: boundary.origin.x * source.size.width, y:boundary.origin.y * source.size.height,
          width: rectangleWidth,
          height: rectangleHeight))
         context.drawPath(using: CGPathDrawingMode.stroke)

//         //Drawing Facial Features
//         fillColor = UIColor.systemRed
//         fillColor.setStroke()
//         context.setLineWidth(5.0)
//        for faceLandmarkRegion in faceLandmarkRegions
//        {
//            var points: [CGPoint] = []
//            for i in 0..<faceLandmarkRegion.pointCount
//            {
//                let point = faceLandmarkRegion.normalizedPoints[i]
//                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
//                points.append(p)
//            }
//            let facialPoints = points.map { CGPoint(
//                x: boundary.origin.x * source.size.width + $0.x * rectangleWidth,
//                y: boundary.origin.y * source.size.height + $0.y * rectangleHeight)
//                
//            }
//            context.addLines(between: facialPoints)
//            context.drawPath(using: CGPathDrawingMode.stroke)
//        }

        let modifiedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        pictureChoosen.image = modifiedImage
    }
}
