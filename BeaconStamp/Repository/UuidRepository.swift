//
//  UuidRepository.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/27.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation
import AFNetworking

class UuidRepository {
    func getAll(token: String, result: @escaping (Any?, Error?) -> Void) {
        let url = BeaconStamp.baseS3Url + "\(token)/beaconlist.json"
        
        let manager = AFHTTPSessionManager()
        
        manager.requestSerializer.cachePolicy = .reloadIgnoringLocalCacheData
        manager.get(url, parameters: nil, progress: nil, success: { (task, response) in
            result(response, nil)
        }) { (task, error) in
            result(nil, error)
        }
    }
}
