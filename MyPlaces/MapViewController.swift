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
        route.isHidden = true
        map.showsCompass = false
        setupMapView()
        checkLocationServices()
    }
    
    var place = Place()
    let annotationidentifier = "annotationidentifier"
    var incomeSegueIdentifier = ""
    @IBOutlet weak var pin: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var footer: UIImageView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var route: UIButton!
    var currentScale = 1000
    var placeLocation : CLPlacemark?

    @IBAction func scale(_ sender: UIButton) {
        let location = map.centerCoordinate
        print("\(map.region.span.longitudeDelta)")
        if sender.tag == 0 {
            
            let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: map.region.span.latitudeDelta * 0.8,
                                                           longitudeDelta: map.region.span.longitudeDelta * 0.8)
            let regions = MKCoordinateRegion(center: location, span : span)
            DispatchQueue.main.async {
                self.map.setRegion(self.map.regionThatFits(regions), animated: true)
            }
        }
        else {
            //currentScale += 500
            let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: map.region.span.latitudeDelta * 1.2,
                                                           longitudeDelta: map.region.span.longitudeDelta * 1.2)
            let regions = MKCoordinateRegion(center: location, span : span)
            DispatchQueue.main.async {
                self.map.setRegion(self.map.regionThatFits(regions), animated: true)
            }
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
            self.placeLocation = placemark
            
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
            route.isHidden = false
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
                            DispatchQueue.main.async {
                                self.address.text =  "\(street), \(buildingNumber)"
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                self.address.text =  "\(street)"
                            }
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
    
    @IBAction func makeRoute(_ sender: UIButton) {
        requestRoute()
    }
    
    func  requestRoute() {
        let request = MKDirections.Request()
        
        guard let source = locationManager.location?.coordinate else { return }
        guard let destination = placeLocation?.location?.coordinate else { return }
        
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else {
                self.showAlert(title: "Error", message: "Cannot get directionions!")
                return
                
            }

            for route in unwrappedResponse.routes {
                self.map.addOverlay(route.polyline)
                self.map.setVisibleMapRect(route.polyline.boundingMapRect.insetBy(dx: -800000, dy: -800000), animated: true)
                
                let distance = String(format: "%1.f",  route.distance / 1000)
                let timeTravel = String(format: "%1.f", route.expectedTravelTime / 3600 )
                
                self.address.isHidden = false
                self.address.isHighlighted = true
                self.address.textAlignment = .right
                self.address.textColor = .blue
                self.footer.isHidden = false
                self.doneButton.isHidden = false
                
                self.address.text = "Distance: \(distance) km\nTime travel: \(timeTravel) hours"
            }
        }
    }
    
    @IBAction func doneButtonPresed() {
        if incomeSegueIdentifier == "showPlace" {
            guard let destination = placeLocation?.location?.coordinate else { return }
                       
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary:nil))
            mapItem.name = "\(self.place.name)"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
        else {
            performSegue(withIdentifier: "test", sender: self)
        }

    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
           let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
           renderer.strokeColor = UIColor.blue
           return renderer
       }
}

 

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
