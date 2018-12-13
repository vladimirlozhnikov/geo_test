//
//  ViewController.swift
//  geo_test
//
//  Created by Владимир on 13.12.2018.
//  Copyright © 2018 Vladimir Lozhnikov. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var view4: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longtitudeLabel: UILabel!
    @IBOutlet weak var degreesLabel: UILabel!
    
    // MARK: Properties
    
    let locationManager = CLLocationManager()
    var lastLocation: CLLocation!
    var view3Actived = false
    var isCompleted = false
    
    // MARK: Closures
    
    // MARK: Controller methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let dx = self.scrollView.bounds.width
        let dy = self.scrollView.bounds.height
        
        self.scrollView.contentSize = CGSize(width: dx*4.0, height: dy)
        self.view1.frame = CGRect(x: 0.0, y: 0.0, width: dx, height: dy)
        self.view2.frame = CGRect(x: dx, y: 0.0, width: dx, height: dy)
        self.view3.frame = CGRect(x: dx*2.0, y: 0.0, width: dx, height: dy)
        self.view4.frame = CGRect(x: dx*3.0, y: 0.0, width: dx, height: dy)
        
        showView1()
        getLocation()
    }

    // MARK: Methods
    
    func getLocation() {
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            self.locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            break
            
        case .authorizedWhenInUse:
            showView3()
            break
            
        case .authorizedAlways:
            break
        }
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
    }
    
    func showView1() {
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func showView2() {
        self.scrollView.setContentOffset(CGPoint(x: self.view2.frame.origin.x, y: 0.0), animated: true)
    }
    
    func showView3() {
        self.view3Actived = true
        self.scrollView.setContentOffset(CGPoint(x: self.view3.frame.origin.x, y: 0.0), animated: true)
    }
    
    func showView4() {
        self.scrollView.setContentOffset(CGPoint(x: self.view4.frame.origin.x, y: 0.0), animated: true)
    }
    
    func getCity(_ completed: ((_ city: String?) -> Void)?) {
        
        guard let location = self.lastLocation else { completed?(nil); return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let last = placemarks?.last {
                completed?(last.addressDictionary?["City"] as? String)
                return
            }
            
            completed?(nil)
        }
    }
    
    func getDegrees(city: String, location: CLLocation, _ completed: ((_ city: String, _ degrees: Float?) -> Void)?) {
        
        guard let url = URL(string: "https://api.darksky.net/forecast/0308e0be7154a55ab217ca78b31b34d0/\(location.coordinate.latitude),\(location.coordinate.longitude)") else { completed?(city, nil); return }
        
        URLSession.shared.dataTask(with:url)
        {
            (data, response, error) in
            
            if let error = error {
                print(error)
                completed?(city, nil)
            }
            else {
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                    
                    let currently = parsedData["currently"] as! [String:AnyObject]
                    let f = currently["temperature"] as! NSNumber // in F
                    
                    let temperature = (f.floatValue - 32.0)*5.0/9.0 // in C
                    completed?(city, temperature)
                }
                catch let error as NSError {
                    print(error)
                    completed?(city, nil)
                }
            }
            
        }.resume()
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            
            self.lastLocation = last
            self.nextButton.isHidden = false
            
            self.latitudeLabel.text = "Latitude: \(last.coordinate.latitude)"
            self.longtitudeLabel.text = "Longitude: \(last.coordinate.longitude)"
            
            getCity { [unowned self] (city) in
                
                if let city = city {
                    print(city)
                    
                    self.getDegrees(city: city, location: self.lastLocation) { [unowned self] (city, degrees) in
                        
                        DispatchQueue.main.async {
                            if let degrees = degrees {
                                self.isCompleted = true
                                self.degreesLabel.text = "\(String(format: "%.1f", degrees))\u{00B0}C degrees in \(city)"
                            }
                            else {
                                self.degreesLabel.text = "Some error is happened"
                            }
                            
                            if self.view3Actived {
                                self.showView4()
                            }
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.degreesLabel.text = "City is not found"
                    }
                }
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func nextClicked(_ sender: Any) {
        showView2()
    }
    
    @IBAction func okClicked(_ sender: Any) {
        
        if self.isCompleted {
            showView4()
        }
        else {
            showView3()
        }
    }
}

