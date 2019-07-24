//
//  CouponInfoRepository.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/27.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import AFNetworking

class CouponInfoRepository {
    func get(userId: String,
             token: String,
             uuid: String,
             major: NSNumber,
             minor: NSNumber,
             idfa: String,
             result: @escaping (Any?, Error?) -> Void) {
        let url = BeaconStamp.baseUrl + "coupons/search"
        
        let manager = AFHTTPSessionManager()
        let parameters : [String : Any] = ["userId": userId,
                          "token": token,
                          "uuid": uuid,
                          "major": major,
                          "minor": minor,
                          "adId": idfa,
                          "os": "iOS"]
        
        Log.debugLog("url: \(url), parameters: \(parameters)")
        
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer.cachePolicy = .reloadIgnoringLocalCacheData
        manager.get(url, parameters: parameters, progress: nil, success: { (task, response) in
            result(response, nil)
        }) { (task, error) in
            result(nil, error)
        }
    }
}
