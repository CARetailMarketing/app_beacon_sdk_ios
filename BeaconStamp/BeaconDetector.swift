//
//  BeaconDetector.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/04/03.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import CoreLocation

public protocol BeaconDetectorDelegate {
    func didReceiveBeacon(uuid: String, major: NSNumber, minor: NSNumber)
}

class BeaconDetector: NSObject, CLLocationManagerDelegate {

    internal let locationManager: CLLocationManagerProtocol
    internal let uuidList: [String]
    internal var delegate: BeaconDetectorDelegate
    internal var detectedBeacons = [String : [NSNumber : [NSNumber]]]()
    
    init(uuidList: [String],
         delegate: BeaconDetectorDelegate,
         locationManager: CLLocationManagerProtocol = CLLocationManager(),
         status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()) {
        self.uuidList = uuidList
        self.delegate = delegate
        self.locationManager = locationManager
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        Log.debugLog("CLAuthorizedStatus: \(status.rawValue)")
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    internal func startMonitoring() {
        Log.debugLog("startMonitoring")
        
        uuidList.enumerated().forEach { (index, uuidString) in
            detectedBeacons[uuidString] = [NSNumber : [NSNumber]]()
            if let uuid = UUID(uuidString: uuidString) {
                let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "BeaconStampSdk\(index)")
                beaconRegion.notifyOnEntry = true
                beaconRegion.notifyOnExit = true
                locationManager.startMonitoring(for: beaconRegion)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Log.debugLog("didChangeAuthorizationStatus: \(status.rawValue)")
        switch (status) {
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()

        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        beacons.forEach { (beacon) in
            let uuid = beacon.proximityUUID.uuidString.lowercased()
            let major = beacon.major
            let minor = beacon.minor
            
            self.didRangeBeacon(uuid: uuid, major: major, minor: minor)
        }
    }
    
    func didRangeBeacon(uuid: String, major: NSNumber, minor: NSNumber) {
        // すでに検出済みのビーコンは送らない。
        if !isDetectedBeacon(uuid: uuid, major: major, minor: minor) {
            Log.debugLog("uuid: \(uuid), major: \(major), minor: \(minor)")
            delegate.didReceiveBeacon(uuid: uuid, major: major, minor: minor)
        }
    }
    
    func isDetectedBeacon(uuid: String, major: NSNumber, minor: NSNumber) -> Bool {
        if detectedBeacons[uuid]?[major]?.contains(minor) == true {
            return true
        }

        if detectedBeacons[uuid]?[major] == nil {
            detectedBeacons[uuid]?[major] = [NSNumber]()
        }
        detectedBeacons[uuid]?[major]?.append(minor)
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLBeaconRegion {
            detectedBeacons[region.proximityUUID.uuidString.lowercased()]?.removeAll()
            Log.debugLog("didEnterRegion: iBeacon found uuid: \(region.proximityUUID)")
            locationManager.startRangingBeacons(in: region)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLBeaconRegion {
            Log.debugLog("didExitRegion: uuid: \(region.proximityUUID)")
            locationManager.stopRangingBeacons(in: region)
        }
    }
    
}
