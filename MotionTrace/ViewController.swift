//
//  ViewController.swift
//  MotionTrace
//
//  Created by liuzhihui on 16/8/20.
//  Copyright © 2016年 liuzhihui. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion

class ColorPolyline: MKPolyline {
    var drawColor: UIColor?
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            self.mapView.delegate = self
        }
    }
    
    var locationManager: CLLocationManager!
    var locationItems:[LocateMotion] = [LocateMotion]()
    var activityManager: CMMotionActivityManager?
    var motionActivity: CMMotionActivity?
    var deferredLocationUpdates: Bool!
    var lastAnnotation: String?
    
    //MARK: - view controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionActivity = nil
        deferredLocationUpdates = false
        lastAnnotation = ""
        
        if CMMotionActivityManager.isActivityAvailable() {
            self.startGettingMotionActivity()
        }
        
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.activityType = CLActivityType.Fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        if CMMotionActivityManager.isActivityAvailable() {
            self.stopGettingMotionActivity()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for loc in locations {
            guard let theMotionActivity = motionActivity else {
                continue
            }
            
            let lm = LocateMotion.init(location: loc, activity: theMotionActivity)
            
            if locationItems.count > 1 {
                guard let lastLM = locationItems.last else {
                    continue
                }
                if !lastLM.isSameActivity(lm) {
                    self.drawActivity()
                }
            }
            
            self.locationItems.append(lm)
        }
        
        if !deferredLocationUpdates {
            let distance:CLLocationDistance = 100.0
            let time:NSTimeInterval = 30.0
            
            locationManager.allowDeferredLocationUpdatesUntilTraveled(distance, timeout: time)
            
            deferredLocationUpdates = true
        }

    }
    
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        deferredLocationUpdates = false
        self.drawActivity()
    }
    
    //MARK: - Motion Job
    
    func startGettingMotionActivity() {
        activityManager = CMMotionActivityManager()
        
        activityManager?.startActivityUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (activity) in
            dispatch_async(dispatch_get_main_queue()) {
                self.motionActivity = activity
            }
        })
    }
    
    func stopGettingMotionActivity() {
        activityManager?.stopActivityUpdates()
        activityManager = nil
    }
    
    func drawActivity() {
        if locationItems.count > 0 {
            //annotation
            let dateFormatter = NSDateFormatter()
            let outputDateFormatterStr = "HH:mm"
            dateFormatter.timeZone = NSTimeZone.defaultTimeZone()
            dateFormatter.dateFormat = outputDateFormatterStr
            
            var coordinates = [CLLocationCoordinate2D]()
            
            for lm in locationItems {
                let coordinate = lm.location.coordinate
                coordinates.append(coordinate)
                
                guard let annStr = dateFormatter.stringForObjectValue(lm.location.timestamp) else {
                    continue
                }
                
                guard let minute = Int(annStr.substringFromIndex(annStr.startIndex.advancedBy(3))) else {
                    continue
                }
                
                if minute % 5 == 0 {
                    if annStr != lastAnnotation! {
                        let point = MKPointAnnotation()
                        point.coordinate = coordinate
                        point.title = annStr
                        mapView.addAnnotation(point)
                        mapView.selectAnnotation(point, animated: true)
                        
                        lastAnnotation = annStr
                    }
                }
            }
            
            //draw the polyline
            let polyline = ColorPolyline.init(coordinates:&coordinates, count:locationItems.count)
            polyline.drawColor = self.getActivityColor(locationItems.last)
            dispatch_sync(dispatch_get_main_queue()) {
                self.mapView.addOverlay(polyline, level: MKOverlayLevel.AboveRoads)
            }
            
            locationItems.removeAll()
            
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polyline = overlay as! ColorPolyline
        let renderer = MKPolylineRenderer.init(polyline: polyline)
        renderer.strokeColor = polyline.drawColor?.colorWithAlphaComponent(0.7)
        renderer.lineWidth = 10.0
        
        return renderer
    }
    
    func getActivityColor(locateMotion:LocateMotion?) -> UIColor {
        
        guard let lm = locateMotion else {
            return UIColor.grayColor()
        }
        
        if lm.activity.stationary {
            return UIColor.blueColor()
        }
        
        if lm.activity.walking {
            return UIColor.greenColor()
        }
        
        if lm.activity.running {
            return UIColor.orangeColor()
        }
        
        if lm.activity.automotive {
            return UIColor.redColor()
        }
        
        return UIColor.grayColor()
    }

}

