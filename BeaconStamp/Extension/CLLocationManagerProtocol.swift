//
//  CLLocationManagerProtocol.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/04/11.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import CoreLocation

protocol CLLocationManagerProtocol : class {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    
    func requestAlwaysAuthorization()
    func startMonitoring(for region: CLRegion)
    func startRangingBeacons(in region: CLBeaconRegion)
    func stopRangingBeacons(in region: CLBeaconRegion)
}

extension CLLocationManager: CLLocationManagerProtocol {}
