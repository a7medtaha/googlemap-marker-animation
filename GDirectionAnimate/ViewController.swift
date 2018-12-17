//
//  ViewController.swift
//  GDirectionAnimate
//
//  Created by Ria and Dev on 17/12/18.
//  Copyright © 2018 Quantorix. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import Alamofire
class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    var stepsCoords:[CLLocationCoordinate2D] = []
    private let locationManager = CLLocationManager()
    var marker:GMSMarker?
    var iPosition:Int = 0;
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json?origin=22.84122,88.091615&destination=tarakeswar&key=AIzaSyBBdOOBplgXq9Uvd3i5c1UbjxLNEUnaHbo").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            guard let jsonObject = response.result.value as? [String: Any] else {
                return
            }
            
            guard let routes = jsonObject["routes"] as? [[String : Any]] else {
                return
            }
            
            guard let overviewPolyline = routes[0]["overview_polyline"] as? [String : Any] else {
                return
            }
            //print(overviewPolyline["points"])
            let path = GMSPath(fromEncodedPath: overviewPolyline["points"] as! String)
            
            let singleLine:GMSPolyline = GMSPolyline(path: path)
            singleLine.strokeWidth = 7
            singleLine.strokeColor = UIColor.green
            singleLine.map = self.mapView
            
            guard let legs = routes[0]["legs"] as? [[String : Any]] else {
                return
            }
            
            guard let steps = legs[0]["steps"] as? [[String : Any]] else {
                return
            }
            
            print(steps.count)
            
            for step in steps {
                let startLocation = step["start_location"] as! [String : Any]
                let endLocation = step["end_location"] as! [String : Any]
                
                let startLat = String(describing: startLocation["lat"]!)
                let startLng = String(describing: startLocation["lng"]!)
                
                let endLat = String(describing: endLocation["lat"]!)
                let endLng = String(describing: endLocation["lng"]!)
                
                print(Double(startLat)!)
                
                let startCoord = CLLocationCoordinate2D(latitude: Double(startLat)!, longitude: Double(startLng)!)
                let endCoord = CLLocationCoordinate2D(latitude: Double(endLat)!, longitude: Double(endLng)!)
                print(startCoord)
                print(endCoord)
                
                self.stepsCoords.append(startCoord)
                self.stepsCoords.append(endCoord)
                
                
                print(self.stepsCoords.count)
                
            }
            print(self.getHeadingForDirection(fromCoordinate: self.stepsCoords[0], toCoordinate: self.stepsCoords[1]))
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true, block: { (_) in
                self.payAnimation()
            })
            
            RunLoop.current.add(self.timer, forMode: RunLoop.Mode.common)
            
        }
    }
    func payAnimation(){
        if iPosition <= self.stepsCoords.count - 1 {
            let position = self.stepsCoords[iPosition]
            self.marker = GMSMarker(position: position)
            self.marker!.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            self.marker!.icon = self.imageWithImage(image: #imageLiteral(resourceName: "arrow"), scaledToSize: CGSize(width: 30.0, height: 30.0))
            self.marker!.rotation = CLLocationDegrees(exactly: self.getHeadingForDirection(fromCoordinate: self.stepsCoords[iPosition], toCoordinate: self.stepsCoords[iPosition + 1]))!
            self.marker!.map = self.mapView
            CATransaction.begin()
            CATransaction.setValue(Int(2.0), forKey: kCATransactionAnimationDuration)
            
            CATransaction.setCompletionBlock({() -> Void in
                self.marker!.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
                //self.marker!.rotation = CDouble(data.value(forKey: "bearing"))
                
            })
            if iPosition != self.stepsCoords.count - 1 {
                self.marker!.position = self.stepsCoords[iPosition+1]
                //this can be new position after car moved from old position to new position with animation
                self.marker!.map = self.mapView
                self.marker!.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
                self.marker!.rotation = CLLocationDegrees(self.getHeadingForDirection(fromCoordinate: self.stepsCoords[iPosition], toCoordinate: self.stepsCoords[iPosition+1]))
            }
            
            if iPosition == (self.stepsCoords.count - 1)
            {
                // timer close
                timer.invalidate()
                
                iPosition = 0
            }
            
            //CATransaction.commit()
            iPosition += 1
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        guard status == .authorizedWhenInUse else {
            return
        }
        
        locationManager.startUpdatingLocation()
        
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        
        locationManager.stopUpdatingLocation()
    }
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    func getHeadingForDirection(fromCoordinate fromLoc: CLLocationCoordinate2D, toCoordinate toLoc: CLLocationCoordinate2D) -> Float {
        
        let fLat: Float = Float((fromLoc.latitude).degreesToRadians)
        let fLng: Float = Float((fromLoc.longitude).degreesToRadians)
        let tLat: Float = Float((toLoc.latitude).degreesToRadians)
        let tLng: Float = Float((toLoc.longitude).degreesToRadians)
        let degree: Float = (atan2(sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))).radiansToDegrees
        if degree >= 0 {
            return degree - 180.0
        }
        else {
            return (360 + degree) - 180
        }
    }

}
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

