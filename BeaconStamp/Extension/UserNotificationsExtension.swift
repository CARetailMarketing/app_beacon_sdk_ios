//
//  UserNotificationsExtension.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/04/09.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import UserNotifications

@available(iOS 10.0, *)
protocol UNUserNotificationCenterProtocol : class {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
}

@available(iOS 10.0, *)
extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {
    
}
