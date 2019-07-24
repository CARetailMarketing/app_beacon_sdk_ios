//
//  BeaconAnalytics.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/05/10.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

class BeaconAnalytics {
    
    enum AnalyticsEvent: String {
        case receiveBeacon
        case showLocalNotification
        case openLocalNotification
        case showCoupon
    }
    
    private static let KEY_EVENTS = "beacon_analytics_events"
    private static let BACKGROUND_TASK_NAME = "beacon_analytics"
    
    var globalAttributes = [String : Any]()
    
    var backgroundTaskID : UIBackgroundTaskIdentifier = .invalid
    
    func createEvent(name: AnalyticsEvent) -> BeaconAnalyticsEvent {
        return BeaconAnalyticsEvent(name: name.rawValue)
    }
    
    func addGlobalAttribute(key: BeaconAnalyticsEvent.AttributeKeys, value: Any) {
        globalAttributes[key.rawValue] = value
    }
    
    func record(event: BeaconAnalyticsEvent) {
        var events = getSavedEvents()
        
        globalAttributes.forEach { (key, value) in
            event.setAttribute(key: key, value: value)
        }
        events.append(event.attributes)
        saveEvents(events: events)
    }
    
    internal func resaveEvents(events: [[String : Any]]) {
        var events = events
        getSavedEvents().forEach({ (event) in
            events.append(event)
        })
        saveEvents(events: events)
    }
    
    internal func saveEvents(events: [[String : Any]]) {
        guard let data = try? JSONSerialization.data(withJSONObject: events, options: []) else {
            return
        }
        UserDefaults.standard.set(data, forKey: BeaconAnalytics.KEY_EVENTS)
    }
    
    internal func getSavedEvents() -> [[String : Any]] {
        guard let data = getSavedEventsData() else {
            return [[String : Any]]()
        }
        do {
            if let events = try JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]] {
                return events
            }
        } catch {
        }
        
        return [[String : Any]]()
    }
    
    internal func getSavedEventsData() -> Data? {
        return UserDefaults.standard.data(forKey: BeaconAnalytics.KEY_EVENTS)
    }
    
    func sendEvents(repository: BeaconAnalyticsRepository = BeaconAnalyticsRepository()) {
        let events = getSavedEvents()
        
        Log.debugLog("\(events)")
        
        if events.count == 0 {
            return
        }
            
        UserDefaults.standard.set(nil, forKey: BeaconAnalytics.KEY_EVENTS)
        
        startBackgroundTask()
        repository.send(parameters: events) { (result, error) in
            if error != nil {
                // エラーの場合は再度送るために保持しておく。
                self.resaveEvents(events: events)
            }
            self.endBackgroundTask()
        }
    }
    
    internal func startBackgroundTask(application: UIApplication = UIApplication.shared) {
        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            Log.debugLog("backgroundTaskID is not invalid. id: \(backgroundTaskID.rawValue)")
            return
        }
        
        backgroundTaskID = application.beginBackgroundTask(withName: BeaconAnalytics.BACKGROUND_TASK_NAME) {
            [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    internal func endBackgroundTask(application: UIApplication = UIApplication.shared) {
        if self.backgroundTaskID != .invalid {
            application.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
    }
}
