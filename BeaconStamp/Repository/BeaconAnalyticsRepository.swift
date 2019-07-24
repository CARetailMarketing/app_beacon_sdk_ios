//
//  BeaconAnalyticsRepository.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/05/13.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import AFNetworking

class BeaconAnalyticsRepository {
    func send(parameters: [[String : Any]],
              result: @escaping (Any?, Error?) -> Void) {
        let url = BeaconStamp.baseUrl + "analytics"
        
        let manager = AFHTTPSessionManager()
        
        Log.debugLog("url: \(url), parameters: \(parameters)")
        
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.requestSerializer.cachePolicy = .reloadIgnoringLocalCacheData
        manager.post(url, parameters: ["analytics":parameters], progress: nil, success: { (task, response) in
            result(response, nil)
        }) { (task, error) in
            result(nil, error)
        }
    }
}
