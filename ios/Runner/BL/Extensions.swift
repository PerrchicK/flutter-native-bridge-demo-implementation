//
//  Extensions.swift
//  Runner
//
//  Created by Perry Shalom on 23/01/2019.
//  Copyright © 2019 My TimeBank. All rights reserved.
//

import Foundation
import CoreLocation

extension NotificationCenter {
    static func notify(notificationName: Notification.Name, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
}

extension Notification.Name {
    static let ADS_PRESENTATION_CHANGED: Notification.Name = Notification.Name("com.perrchick.notification.name.ADS_PRESENTATION_CHANGED")
    static let UPDATE_LOCATION: Notification.Name = Notification.Name("com.perrchick.notification.name.UPDATE_LOCATION")
    static let ON_FLUTTER_IS_READY: Notification.Name = Notification.Name("com.perrchick.notification.name.ON_FLUTTER_IS_READY")
    static let ON_IMAGE_PICKED: Notification.Name = Notification.Name("com.perrchick.notification.name.ON_IMAGE_PICKED")
}

extension Timestamp {
    static var now: Timestamp {
        return Date().timestamp
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self) / 1000)
    }
}

extension Date {
    /// The timestamp in milliseconds
    var timestamp: Timestamp {
        // Attempting to fix crash by calling `.rounded()` method, the solution taken from: https://stackoverflow.com/questions/40134323/date-to-milliseconds-and-back-to-date-in-swift
        return UInt64((timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: UInt64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
    
    func toString(dateFormat: String = "yyyy-MM-dd HH:mm:ss:SSS") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        let timesamp = formatter.string(from: Date())
        
        return timesamp
    }
}
