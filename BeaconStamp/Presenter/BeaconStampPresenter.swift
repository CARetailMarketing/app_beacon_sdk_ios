//
//  BeaconStampPresenter.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/27.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import UserNotifications
import AdSupport
import CoreLocation

class BeaconStampPresenter {
    
    internal static let KEY_UUID_LIST = "key_beacon_uuid_list"
    private static let KEY_USER_ID = "key_beacon_user_id"
    private static let KEY_TOKEN = "key_beacon_token"
    private static let KEY_LAST_SEND_ANALYTICS = "key_last_send_analytics"
    private static let KEY_LAST_GET_COUPON = "key_last_get_coupon"
    internal static let KEY_WAITING_COUPON = "key_waiting_coupon"

    internal static let KEY_USER_INFO = "coupon_info"
    
    var token: String = "" {
        didSet {
            UserDefaults.standard.set(token, forKey: BeaconStampPresenter.KEY_TOKEN)
            analytics.addGlobalAttribute(key: .token, value: token)
        }
    }
    var dryRun: Bool = false {
        didSet {
            if dryRun {
                // 検証環境
                BeaconStamp.baseUrl = "https://5skgpvb6va.execute-api.ap-northeast-1.amazonaws.com/dev/"
                BeaconStamp.baseS3Url = "https://s3-ap-northeast-1.amazonaws.com/beacon-assets-dev/"
            } else {
                // 本番環境
                BeaconStamp.baseUrl = "https://zaskaozu8f.execute-api.ap-northeast-1.amazonaws.com/v1/"
                BeaconStamp.baseS3Url = "https://s3-ap-northeast-1.amazonaws.com/beacon-assets-v1/"
            }
        }
    }
    var lazyShow: Bool = false
    var uuidList: [String]? = nil
    var pendingCouponInfo: CouponInfo? = nil
    var requestLocationAuthorization: Bool = false {
        didSet {
            if requestLocationAuthorization {
                if let uuidList = uuidList {
                    self.initializeBeaconDetector(uuidList: uuidList)
                }
            }
        }
    }
    
    lazy var idfa = getIdfa()
    lazy var userId = getUserId()
    
    let analytics = BeaconAnalytics()
    
    var beaconDetector: BeaconDetector?
    
    var backgroundTaskID : UIBackgroundTaskIdentifier = .invalid
    
    var lastSendAnalytics: String = UserDefaults.standard.string(forKey: BeaconStampPresenter.KEY_LAST_SEND_ANALYTICS) ?? "" {
        didSet {
            UserDefaults.standard.set(lastSendAnalytics, forKey: BeaconStampPresenter.KEY_LAST_SEND_ANALYTICS)
        }
    }
    
    var lastGetCoupon: String = UserDefaults.standard.string(forKey: BeaconStampPresenter.KEY_LAST_GET_COUPON) ?? "" {
        didSet {
            UserDefaults.standard.set(lastGetCoupon, forKey: BeaconStampPresenter.KEY_LAST_GET_COUPON)
        }
    }

    func initialize(application: UIApplicationProtocol = UIApplication.shared) {
        checkPermissionRequested()
        getUuidList(application: application)
        
        analytics.addGlobalAttribute(key: .userId, value: userId)
        analytics.addGlobalAttribute(key: .adId, value: idfa)
        analytics.addGlobalAttribute(key: .os, value: "iOS")
        
        // フォアグラウンドに復帰を監視
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(type(of: self).willEnterForeground(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func willEnterForeground(notification: Notification) {
        Log.debugLog()
        // フォアグラウンドに復帰した際に未表示のクーポンがあれば表示
        showWaitingCoupon()
    }
    
    func startShowAd() {
        lazyShow = false
        showAd()
    }
    
    func getUuidList(uuidRepository: UuidRepository = UuidRepository(), application: UIApplicationProtocol = UIApplication.shared) {
        if application.applicationState == .background {
            // アプリ未起動時にBeacon受信した場合
            // Beacon受信している＝requestLocationAuthorizationがtrueになったことがあるためここではチェックしない
            if let uuidList = getCachedUuidList(), beaconDetector == nil {
                beaconDetector = BeaconDetector(uuidList: uuidList, delegate: self)
            }
            return
        }

        uuidRepository.getAll(token: token) { (response, error) in
            if let response = response as? [String : [String]],
                let beaconList = response["beaconList"] {
                let uuidList = beaconList.compactMap({ $0.lowercased() })
                UserDefaults.standard.set(beaconList, forKey: BeaconStampPresenter.KEY_UUID_LIST)
                self.uuidList = uuidList
                self.initializeBeaconDetector(uuidList: uuidList)
                Log.debugLog("response: \(response)")
            } else {
                if let uuidList = self.getCachedUuidList() {
                    self.initializeBeaconDetector(uuidList: uuidList)
                }
                Log.debugLog("error or can not handling UuidRepository response: \(response ?? "nil"), error: \(error?.localizedDescription ?? "nil")")
            }
            
            self.showWaitingCoupon()
        }
    }
    
    private func checkPermissionRequested() {
        // 位置情報使用権限リクエスト済みの場合はtrueを入れておく
        requestLocationAuthorization = CLLocationManager.authorizationStatus() != .notDetermined
    }

    private func initializeBeaconDetector(uuidList: [String]) {
        if requestLocationAuthorization && beaconDetector == nil {
            self.beaconDetector = BeaconDetector(uuidList: uuidList, delegate: self)
        }
    }

    private func getCachedUuidList() -> [String]? {
        if let uuidList = uuidList {
            return uuidList
        } else {
            return UserDefaults.standard.array(forKey: BeaconStampPresenter.KEY_UUID_LIST) as? Array<String>
        }
    }
    
    private func getCachedToken() -> String {
        return token != "" ? self.token : UserDefaults.standard.string(forKey: BeaconStampPresenter.KEY_TOKEN) ?? ""
    }
    
    internal func getCouponInfo(uuid: String, major: NSNumber, minor: NSNumber, couponInfoRepository: CouponInfoRepository = CouponInfoRepository()) {
        Log.debugLog("getCouponInfo uuid: \(uuid)")
        guard let uuidList = getCachedUuidList() else {
            return
        }
        
        let token = getCachedToken()
        if token == "" {
            return
        }
        
        let uuid = uuid.lowercased()
        
        if !uuidList.contains(uuid) {
            Log.debugLog("not contains uuid: \(uuid)")
            return
        }
        
        receiveBeaconAnalytics(uuid: uuid, major: major, minor: minor)
        
        // 今日クーポンを取得済みの場合は取得しない
        if isGetCouponToday() {
            return
        }
        
        couponInfoRepository.get(userId: userId,
                                   token: token,
                                   uuid: uuid,
                                   major: major,
                                   minor: minor,
                                   idfa: idfa) { (response, error) in
            if let response = response as? Data,
                let couponInfo = CouponInfo.decode(data: response) {
                self.updateGetCouponToday()
                self.showAd(couponInfo: couponInfo)
                return
            } else if let error = error {
                Log.debugLog("error: \(error)")
            } else {
                Log.debugLog("can not handling CouponInfoRepository response: \(response ?? "nil"), uuid: \(uuid), major: \(major), minor: \(minor), error: \(error?.localizedDescription ?? "nil")")
            }
            self.endBackgroundTask()
        }
    }
    
    func didReceive(notification: UILocalNotification) {
        guard let data = notification.userInfo?[BeaconStampPresenter.KEY_USER_INFO] as? Data else {
            return
        }
        
        didReceive(data: data)
    }
    
    @available(iOS 10.0, *)
    func didReceive(notification: UNNotification) {
        guard let data = notification.request.content.userInfo[BeaconStampPresenter.KEY_USER_INFO] as? Data else {
            return
        }
        
        didReceive(data: data)
    }
    
    private func didReceive(data: Data) {
        
        if let couponInfo = CouponInfo.decode(data: data) {
            openLocalNotificationAnalytics(couponInfo: couponInfo)
            removeWaitingCoupon()
            showCoupon(couponInfo: couponInfo, closeOld: true)
        }
    }
    
    internal func receiveBeaconAnalytics(uuid: String,
                                major: NSNumber,
                                minor: NSNumber) {
        let event = analytics.createEvent(name: .receiveBeacon)
        event.set(uuid: uuid)
        event.set(major: major.intValue)
        event.set(minor: minor.intValue)
        
        analytics.record(event: event)
        
        // ビーコン受信時のイベントは1日1回リアルタイムに送信する
        if !isSendAnalyticsToday() {
            analytics.sendEvents()
            updateSendAnalyticsToday()
        } else {
            Log.debugLog("isSendAnalyticsToday: true")
        }
    }
    
    internal func openLocalNotificationAnalytics(couponInfo: CouponInfo) {
        recordAnalytics(couponInfo: couponInfo, eventName: .openLocalNotification)
    }
    
    internal func showLocalNotificationAnalytics(couponInfo: CouponInfo) {
        recordAnalytics(couponInfo: couponInfo, eventName: .showLocalNotification)
    }
    
    internal func showCouponAnalytics(couponInfo: CouponInfo) {
        recordAnalytics(couponInfo: couponInfo, eventName: .showCoupon)
        analytics.sendEvents()
    }
    
    private func recordAnalytics(couponInfo: CouponInfo,
                                 eventName: BeaconAnalytics.AnalyticsEvent) {
        let event = analytics.createEvent(name: eventName)
        event.set(uuid: couponInfo.beacon.uuid)
        event.set(major: couponInfo.beacon.major)
        event.set(minor: couponInfo.beacon.minor)
        event.set(couponId: couponInfo.creative.couponId)
        
        analytics.record(event: event)
    }
    
    private func getIdfa() -> String {
        let manager = ASIdentifierManager.shared()

        return manager.isAdvertisingTrackingEnabled ? manager.advertisingIdentifier.uuidString : ""
    }
    
    private func getUserId() -> String {
        return UserDefaults.standard.string(forKey: BeaconStampPresenter.KEY_USER_ID) ?? createUserId()
    }
    
    private func createUserId() -> String {
        let userId = UUID().uuidString
        UserDefaults.standard.set(userId, forKey: BeaconStampPresenter.KEY_USER_ID)

        return userId
    }
    
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: Date())
    }
    
    internal func isSendAnalyticsToday() -> Bool {
        return lastSendAnalytics == getTodayString()
    }
    
    internal func updateSendAnalyticsToday() {
        lastSendAnalytics = getTodayString()
    }
    
    internal func isGetCouponToday() -> Bool {
        return lastGetCoupon == getTodayString()
    }
    
    internal func updateGetCouponToday() {
        lastGetCoupon = getTodayString()
    }
    
    private func showAd(couponInfo: CouponInfo? = nil) {
        guard let info = couponInfo ?? pendingCouponInfo else {
            return
        }
        pendingCouponInfo = nil
        
        if UIApplication.shared.applicationState == .active {
            self.endBackgroundTask()

            // フォアグラウンドならクーポン表示
            showCoupon(couponInfo: info)
        } else {
            // ローカル通知以外からのアプリ起動/フォアグラウンド復帰のために保存しておく。
            saveWaitingCoupon(couponInfo: info)
            
            // フォアグラウンド以外はローカル通知を出す
            showLocalNotification(couponInfo: info)
        }
    }
    
    internal func showWaitingCoupon() {
        // 未表示のクーポンが保存されている場合は表示する
        if let data = UserDefaults.standard.data(forKey: BeaconStampPresenter.KEY_WAITING_COUPON),
            let couponInfo = CouponInfo.decode(data: data) {
            removeWaitingCoupon()
            showCoupon(couponInfo: couponInfo)
        }
    }
    
    internal func removeWaitingCoupon() {
        UserDefaults.standard.removeObject(forKey: BeaconStampPresenter.KEY_WAITING_COUPON)
    }
    
    internal func showCoupon(couponInfo: CouponInfo, closeOld: Bool = false) {
        if lazyShow {
            pendingCouponInfo = couponInfo
            Log.debugLog("showCoupon lazyShow: \(lazyShow), couponInfo: \(couponInfo)")
            return
        }
        
        Log.debugLog("\(couponInfo)")
        if let window = UIApplication.shared.keyWindow {
            let couponView = CouponView(frame: window.bounds)
            couponView.show(view: window, couponInfo: couponInfo, closeOld: closeOld, token: token)
            showCouponAnalytics(couponInfo: couponInfo)
        }
    }
    
    internal func saveWaitingCoupon(couponInfo: CouponInfo) {
        if let data = couponInfo.encode() {
            UserDefaults.standard.set(data, forKey: BeaconStampPresenter.KEY_WAITING_COUPON)
        }
    }
    
    private func showLocalNotification(couponInfo: CouponInfo) {
        if #available(iOS 10.0, *) {
            showLocalNotificationOverIos10(couponInfo: couponInfo,
                                           imageDownloader: couponInfo.creative.thumbnail != "" ? ImageDownloader() : nil)
        } else {
            showLocalNotificationIos9(couponInfo: couponInfo)
        }
    }
    
    @available(iOS 10.0, *)
    internal func showLocalNotificationOverIos10(couponInfo: CouponInfo,
                                                 notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current(),
                                                 imageDownloader: ImageDownloader? = nil) {
        Log.debugLog("showLocalNotificationOverIos10 couponInfo: \(couponInfo), notificationCenter: \(notificationCenter), imageDownloader: \(String(describing: imageDownloader))")
        //　通知設定に必要なクラスをインスタンス化
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let content = UNMutableNotificationContent()
        
        // 通知内容の設定
        content.title = couponInfo.creative.title
        content.body = couponInfo.creative.body
        content.sound = UNNotificationSound.default
        if let data = couponInfo.encode() {
            content.userInfo = [BeaconStampPresenter.KEY_USER_INFO: data]
        }
        if couponInfo.creative.thumbnail != "", let url = URL(string: couponInfo.creative.thumbnail), let imageDownloader = imageDownloader {
            Log.debugLog("\(url.absoluteString)")
            
            imageDownloader.downloadWith(url: url) { (url, error) in
                if let url = url, let attachment = try? UNNotificationAttachment(identifier: "image", url: url, options: nil) {
                    content.attachments = [attachment]
                }
                
                self.addNotification(couponInfo: couponInfo, notificationCenter: notificationCenter, content: content, trigger: trigger)
            }
            
            return
        }
        
        addNotification(couponInfo: couponInfo, notificationCenter: notificationCenter, content: content, trigger: trigger)
    }

    @available(iOS 10.0, *)
    private func addNotification(couponInfo: CouponInfo,
                                 notificationCenter: UNUserNotificationCenterProtocol,
                                 content: UNNotificationContent,
                                 trigger: UNNotificationTrigger) {
        // 通知スタイルを指定
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        // 通知をセット
        notificationCenter.add(request, withCompletionHandler: nil)

        showLocalNotificationAnalytics(couponInfo: couponInfo)
    }

    internal func showLocalNotificationIos9(couponInfo: CouponInfo,
                                            application: UIApplicationProtocol = UIApplication.shared) {
        Log.debugLog("showLocalNotificationIos9 couponInfo: \(couponInfo), application: \(application)")

        let notification = UILocalNotification.init()
        notification.fireDate = Date()
        notification.timeZone = NSTimeZone.default
        
        notification.alertTitle = couponInfo.creative.title
        notification.alertBody = couponInfo.creative.body
        notification.soundName = UILocalNotificationDefaultSoundName
        if let data = couponInfo.encode() {
            notification.userInfo = [BeaconStampPresenter.KEY_USER_INFO: data]
        }
        
        application.scheduleLocalNotification(notification)

        showLocalNotificationAnalytics(couponInfo: couponInfo)
    }
    
    internal func startBackgroundTask(application: UIApplication = UIApplication.shared) {
        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            Log.debugLog("backgroundTaskID is not invalid. id: \(backgroundTaskID.rawValue)")
            return
        }
        
        backgroundTaskID = application.beginBackgroundTask() {
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

extension BeaconStampPresenter: BeaconDetectorDelegate {
    func didReceiveBeacon(uuid: String, major: NSNumber, minor: NSNumber) {
        Log.debugLog("BeaconStampPresenter.didEnterRegion applicationState: \(UIApplication.shared.applicationState.rawValue)")
        if UIApplication.shared.applicationState != .active {
            startBackgroundTask()
        }
        getCouponInfo(uuid: uuid,
                      major: major,
                      minor: minor)
    }
}
