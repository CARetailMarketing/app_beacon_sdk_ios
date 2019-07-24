//
//  BeaconAnalyticsEvent.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/05/10.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

class BeaconAnalyticsEvent {
    
    enum AttributeKeys: String {
        case eventName
        case os
        case token
        case userId
        case uuid
        case major
        case minor
        case couponId
        case date
        case adId
    }
    
    var attributes = [String : Any]()
    
    init(name: String) {
        setAttribute(key: AttributeKeys.eventName.rawValue, value: name)
        setAttribute(key: AttributeKeys.date.rawValue, value: getDateString())
    }
    
    private func getDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        return formatter.string(from: Date())
    }
    
    func set(os: String) {
        setAttribute(key: AttributeKeys.os.rawValue, value: os)
    }
    
    func set(token: String) {
        setAttribute(key: AttributeKeys.token.rawValue, value: token)
    }
    
    func set(userId: String) {
        setAttribute(key: AttributeKeys.userId.rawValue, value: userId)
    }
    
    func set(uuid: String) {
        setAttribute(key: AttributeKeys.uuid.rawValue, value: uuid)
    }
    
    func set(major: Int) {
        setAttribute(key: AttributeKeys.major.rawValue, value: major)
    }
    
    func set(minor: Int) {
        setAttribute(key: AttributeKeys.minor.rawValue, value: minor)
    }
    
    func set(couponId: String) {
        setAttribute(key: AttributeKeys.couponId.rawValue, value: couponId)
    }
    
    func set(adId: String) {
        setAttribute(key: AttributeKeys.adId.rawValue, value: adId)
    }
    
    func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
}
