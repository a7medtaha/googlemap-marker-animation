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
    private let locationManager = CLLocationManager()
    
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
        
        let position = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let marker = GMSMarker(position: position)
        marker.title = "Hello World"
        marker.icon = imageWithImage(image: #imageLiteral(resourceName: "arrow"), scaledToSize: CGSize(width: 30.0, height: 30.0))
        marker.map = mapView
        locationManager.stopUpdatingLocation()
    }
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

}

