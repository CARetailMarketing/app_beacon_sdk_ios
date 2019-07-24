//
//  BeaconStamp.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/20.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import UserNotifications

public class BeaconStamp {
    
    private static let presenter = BeaconStampPresenter()

    internal static var baseUrl = ""
    internal static var baseS3Url = ""
    
    private class var token: String {
        get {
            return presenter.token
        }
        set {
            presenter.token = newValue
        }
    }
    
    public private(set) class var dryRun: Bool {
        get {
            return presenter.dryRun
        }
        set {
            presenter.dryRun = newValue
        }
    }
    
    public class var showDebugLog: Bool {
        get {
            return Log.showDebugLog
        }
        set {
            Log.showDebugLog = newValue
        }
    }
    
    public private(set) class var lazyShow: Bool {
        get {
            return presenter.lazyShow
        }
        set {
            presenter.lazyShow = newValue
        }
    }
    
    private init() {}
    
    public class func initWith(token: String,
                               dryRun: Bool = false,
                               showDebugLog: Bool = false,
                               lazyShow: Bool = false) {
        self.initialize(token: token, dryRun: dryRun, showDebugLog: showDebugLog, lazyShow: lazyShow)
    }
    
    internal class func initialize(token: String,
                                 dryRun: Bool = false,
                                 showDebugLog: Bool = false,
                                 lazyShow: Bool = false,
                                 application: UIApplicationProtocol = UIApplication.shared) {
        self.token = token
        self.dryRun = dryRun
        self.showDebugLog = showDebugLog
        self.lazyShow = lazyShow
        
        presenter.initialize(application: application)
    }
    
    public class func startShowAd() {
        presenter.startShowAd()
    }
    
    public class func didReceive(notification: UILocalNotification) {
        presenter.didReceive(notification: notification)
    }
    
    @available(iOS 10.0, *)
    public class func didReceive(notification: UNNotification) {
        presenter.didReceive(notification: notification)
    }
    
    public class func requestLocationAuthorization() {
        presenter.requestLocationAuthorization = true
    }
    
    public class func requestNotificationAuthorization() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
            })
        } else {
            let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    // ビーコン受信をエミュレートするためのデバッグ用。不要になったタイミングで削除する
    public class func getCouponInfo(uuid: String) {
        // for debug
        presenter.getCouponInfo(uuid: uuid.lowercased(), major: 10000, minor: 1170)
    }
    
    public class func setDebugLogDelegate(_ delegate: DebugLogDelegate) {
        Log.debugLogDelegate = delegate
    }
}
