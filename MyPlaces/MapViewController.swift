//
//  MapViewController.swift
//  Pods-MyPlaces
//
//  Created by Ivan Abramov on 12/01/2020.
//  Copyright © 2020 Ivan Abramov. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //map.mapType = .mutedStandard
        map.delegate = self
        map.showsScale = true
        setupMapView()
        checkLocationServices()
        map.showsCompass = false
    }
    
    var place = Place()
    let annotationidentifier = "annotationidentifier"
    var incomeSegueIdentifier = ""
    @IBOutlet weak var pin: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var footer: UIImageView!
    @IBOutlet weak var address: UILabel!
    var currentScale = 1000
    
    @IBAction func scale(_ sender: UIButton) {
        let location = map.centerCoordinate
        if sender.tag == 0 {
            if currentScale - 500 <= 0 {
                return
            }
            currentScale -= 500
            let regions = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(exactly: currentScale)!, longitudinalMeters: CLLocationDistance(exactly: currentScale)!)
            map.setRegion(map.regionThatFits(regions), animated: true)
        }
        else {
            currentScale += 500
            let regions = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(exactly: currentScale)!, longitudinalMeters: CLLocationDistance(exactly: currentScale)!)
            map.setRegion(map.regionThatFits(regions), animated: true)
        }
        
        
    }
    
    
    @IBAction func centerUserLocation() {
        showUserLocation()
    }
    
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: 1000,
                                            longitudinalMeters: 1000)
            map.setRegion(map.regionThatFits(region), animated: true)
        }
    }
    
    @IBAction func cancelACtion(_ sender: Any) {
        dismiss(animated: true)
    }
 
    @IBOutlet weak var map: MKMapView!
    let locationManager = CLLocationManager()
    
    private func setupPlacemark() {
        guard let location = place.location else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placeMarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placeMarkLocation.coordinate
            self.map.showAnnotations([annotation], animated: true)
            self.map.selectAnnotation(annotation, animated: true)
            
        }
    }
}

extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotatioview = map.dequeueReusableAnnotationView(withIdentifier: annotationidentifier) as? MKPinAnnotationView
        
        if annotatioview == nil {
            annotatioview = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationidentifier)
            annotatioview?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotatioview?.rightCalloutAccessoryView = imageView
        }
        
        
        
        return annotatioview
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location services are disabled",
                    message: "Please, go to Settings and enable geoposition"
                )
            }
        }
    }
    
    private func showAlert(title : String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
    }
    
    private func setupMapView() {
        if incomeSegueIdentifier == "showPlace" {
            setupPlacemark()
            doneButton.isHidden = true
            address.isHidden = true
            footer.isHidden = true
            pin.isHidden = true
        }
    }
    
    private func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            map.showsUserLocation = true
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location services are disabled",
                    message: "Please, go to Settings and enable geoposition"
                )
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location services are disabled",
                    message: "Please, go to Settings and enable geoposition"
                )
            }
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is avaiable")
        
        }
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard incomeSegueIdentifier != "showPlace" else { return }
        let center = mapView.centerCoordinate
        let getLat: CLLocationDegrees = center.latitude
        let getLon: CLLocationDegrees = center.longitude
        let location: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
        
        setAddress(to: location)
    }
    
    func setAddress(to location : CLLocation) {
        let geocoder = CLGeocoder()
                
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    if let street = firstLocation?.thoroughfare {
                        if let buildingNumber = firstLocation?.subThoroughfare {
                            self.address.text =  "\(street), \(buildingNumber)"
                        }
                        else {
                            self.address.text =  "\(street)"
                        }
                    }
                    else {
                        self.address.text = "Не удалось определить адрес"
                    }
                    
                }
                else {
                  print("Error")
                }
            })
        
    }
    
    func map(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        currentScale = zoomFactor
    }
}

 

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
