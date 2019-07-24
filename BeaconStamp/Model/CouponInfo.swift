//
//  CouponInfo.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/26.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

struct CouponInfo: Codable {
    let beacon: Beacon
    let creative: Creative
    
    static func decode(data: Data) -> CouponInfo? {
        return try? JSONDecoder().decode(self, from: data)
    }
    
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }

    struct Beacon: Codable {
        let uuid: String
        let major: Int
        let minor: Int
    }
    
    struct Creative: Codable {
        let couponId: String
        let title: String
        let body: String
        let thumbnail: String
        let image: String
        let coupon: String
    }
}
