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
import Polyline
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
        
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json?origin=22.84122,88.091615&destination=rajarhat&key=AIzaSyBBdOOBplgXq9Uvd3i5c1UbjxLNEUnaHbo").responseJSON { response in
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
            
            let path = GMSPath(fromEncodedPath: overviewPolyline["points"] as! String)
            
            let singleLine:GMSPolyline = GMSPolyline(path: path)
            singleLine.strokeWidth = 7
            singleLine.strokeColor = UIColor.green
            singleLine.map = self.mapView
            
            
            self.stepsCoords = decodePolyline(overviewPolyline["points"] as! String)!
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (_) in
                self.playAnimation()
            })
            
            RunLoop.current.add(self.timer, forMode: RunLoop.Mode.common)
            
            
        }
    }
    func playAnimation(){
        if iPosition <= self.stepsCoords.count - 1 {
            let position = self.stepsCoords[iPosition]
            self.marker?.position = position
             mapView.camera = GMSCameraPosition(target: position, zoom: 15, bearing: 0, viewingAngle: 0)
            self.marker!.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            if iPosition != self.stepsCoords.count - 1 {
                self.marker!.rotation = CLLocationDegrees(exactly: self.getHeadingForDirection(fromCoordinate: self.stepsCoords[iPosition], toCoordinate: self.stepsCoords[iPosition+1]))!
            }
            
            
            if iPosition == self.stepsCoords.count - 1 {
                iPosition = 0;
                timer.invalidate()
            }
            
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
        
        let position = location.coordinate
        self.marker = GMSMarker(position: position)
        self.marker!.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        self.marker!.icon = self.imageWithImage(image: #imageLiteral(resourceName: "arrow"), scaledToSize: CGSize(width: 30.0, height: 30.0))
        self.marker!.map = self.mapView
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

