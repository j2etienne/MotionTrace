//
//  LocateMotion.swift
//  MotionTrace
//
//  Created by liuzhihui on 16/8/20.
//  Copyright © 2016年 liuzhihui. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class LocateMotion: NSObject {
    var location: CLLocation
    var activity: CMMotionActivity
    
    
    init(location: CLLocation, activity:CMMotionActivity) {
        self.location = location
        self.activity = activity
    }
    
    func isSameActivity(anotherLocateMotion:LocateMotion) -> Bool {
        if activity.stationary == anotherLocateMotion.activity.stationary
        && activity.walking == anotherLocateMotion.activity.walking
        && activity.running == anotherLocateMotion.activity.running
        && activity.automotive == anotherLocateMotion.activity.automotive
        && activity.unknown == anotherLocateMotion.activity.unknown{
            return true
        }
        
        return false
    }
    
}
