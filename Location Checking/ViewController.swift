//
//  ViewController.swift
//  Location Checking
//
//  Created by Johhanes Nguyen on 2020-04-12.
//  Copyright © 2020 Johhanes Nguyen. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var findLocationButton: UIButton!
    
    
    // use let to not need change
    let locationManager = CLLocationManager();
    // location: use CLLocation type- location may be nil- it's optional
    var location: CLLocation?
    // updating location by default
    var isUpdatingLocation = false
    // last Location
    var lastLocationError: Error?
    
    // geo code - use let here because we won't change later on
    let geocoder = CLGeocoder()
   // this placemark is optional
    var placemark: CLPlacemark?
    
    var isPerformingReverseGeocoding = false
    
    var lastGeocodingError : Error?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func updateUI() {
        // do get location
        if let location = location {
            // need to populate the location Label with cordinate info
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text =  String(format: "%.8f", location.coordinate.longitude)
            statusLabel.text = " New Location Updated"
            
            if let placemark = placemark {
                addressLabel.text = getAddress(from: placemark)
            }else if isPerformingReverseGeocoding {
                addressLabel.text = "Searching for address..."
            }else if lastGeocodingError != nil {
                addressLabel.text = " Error finding a valid address"
            }else {
                addressLabel.text = " Not found "
            }
        }else{
            statusLabel.text = "Tap 'Find Location' to start";
            latitudeLabel.text = "..Loading..";
            longitudeLabel.text = "..Loading.."
            addressLabel.text = "..Loading.."
        }
        
    }
    // getAddress function
    func getAddress (from placemark: CLPlacemark)  -> String {
        // we need number- street- city Name- postal code - country
        
        var line1 = ""
        if let street1 = placemark.subThoroughfare {
            line1 += street1 + " "
        }
        
        if let street2 = placemark.subThoroughfare{
            line1 += street2
        }
        
        var line2 = ""
        if let city = placemark.locality{
            line2 += city + ", "
        }
        if let stateOrProvince = placemark.administrativeArea {
            line2 += stateOrProvince + " "
        }
        
        if let postalCode = placemark.postalCode{
            line2 += postalCode
        }
        
        var line3 = ""
        if let country = placemark.country {
            line3 += country
        }
        
        return line1  + line2 +  "\n" + line3
    }
    
    // Target -Action
    
    @IBAction func findLocation () {
        // get user's permission - use location services
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // report to user if permission is denied
        // user can be accidentally refused
        //or user's device is restricted
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            // report location
            reportLocationServicesDeniedError()
            return
        }
        
        // start or stop finding location
        if isUpdatingLocation {
            stopLocationManager()
        }else{
            // reset location
            location = nil
            lastLocationError = nil
            
            
            // reset placemark and lastgeocodingerror
            placemark = nil
            lastGeocodingError = nil
            
            startLocationManager()
        }
        
        updateUI()
        
    }
    func startLocationManager () {
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            isUpdatingLocation = true
        }
       }
    func stopLocationManager () {
        if isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            isUpdatingLocation = false
            
        }
        
    }
    func reportLocationServicesDeniedError () {
         let alert = UIAlertController(title: "Location Services are disabled", message: "Please turn on by setting-privacy to enable", preferredStyle: .alert)
         let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
         alert.addAction(okAction)
         present(alert, animated: true, completion: nil)
     }
    
    
   
    
 
}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR!! locationManager-didFailWithError: \(error)")
        if(error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateUI()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last!
        print("GOT IT! locationManager-didUpdateLocations:\(location)")
        stopLocationManager()
        updateUI()
        
        if location != nil {
            if !isPerformingReverseGeocoding {
                print("*** Start performing geocoding...")
                isPerformingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(location!) { (placemarks, error) in
                    self.lastGeocodingError = error
                    if error == nil, let placemarks = placemarks, !placemarks.isEmpty{
                        self.placemark = placemarks.last!
                    }else{
                        self.placemark = nil
                    }
                    
                    self.isPerformingReverseGeocoding = false
                    self.updateUI()
            }
        }
    }
    }
}
