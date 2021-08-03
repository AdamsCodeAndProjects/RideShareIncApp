//
//  RiderViewController.swift
//  UberApp
//
//  Created by adam janusewski on 7/26/21.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth


class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callARideButton: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var rideHasBeenCalled = false
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = FirebaseAuth.Auth.auth().currentUser?.email {
            FirebaseDatabase.Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                self.rideHasBeenCalled = true
                self.callARideButton.setTitle("Cancel Ride", for: .normal)
                FirebaseDatabase.Database.database().reference().child("RideRequests").removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            if let email = FirebaseAuth.Auth.auth().currentUser?.email {
                                FirebaseDatabase.Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged) { snapshot in
                                    if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                        if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                            if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                self.driverOnTheWay = true
                                                self.displayDriverAndRider()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance) * 100 / 100
        callARideButton.setTitle("Your Driver is \(roundedDistance)km away!", for: .normal)
        map.removeAnnotations(map.annotations)
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = userLocation
        riderAnno.title = "Your Location"
        map.addAnnotation(riderAnno)
        
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Your Driver"
        map.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate{
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            userLocation = center
            
            
            if rideHasBeenCalled {
                displayDriverAndRider()
                
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                map.removeAnnotations(map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        try? FirebaseAuth.Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    @IBAction func rideTapped(_ sender: UIButton) {
        if !driverOnTheWay {
            if let email = FirebaseAuth.Auth.auth().currentUser?.email {
                if rideHasBeenCalled {
                    rideHasBeenCalled = false
                    callARideButton.setTitle("Call For A Ride", for: .normal)
                    FirebaseDatabase.Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                        snapshot.ref.removeValue()
                        FirebaseDatabase.Database.database().reference().child("RideRequests").removeAllObservers()
                        
                        
                    })
                } else {
                    let rideRequestDictionary = ["email": email, "lat": userLocation.latitude, "lon": userLocation.longitude] as [String : Any]
                    
                    FirebaseDatabase.Database.database().reference().child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
                    
                    rideHasBeenCalled = true
                    callARideButton.setTitle("Cancel Ride", for: .normal)
                }
            }
            
        }
        
    }
    
    
}
