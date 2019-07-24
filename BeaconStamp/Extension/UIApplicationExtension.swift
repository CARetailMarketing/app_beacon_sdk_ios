//
//  UIApplicationExtension.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/04/09.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

protocol UIApplicationProtocol : class {
    
    var applicationState: UIApplication.State { get }
    
    func scheduleLocalNotification(_ notification: UILocalNotification)
}

extension UIApplication : UIApplicationProtocol {}
