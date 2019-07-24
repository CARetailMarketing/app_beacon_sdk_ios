//
//  ImageDownloader.swift
//  AFNetworking
//
//  Created by 近藤 寛志 on 2019/03/29.
//

import Foundation
import AFNetworking

internal class ImageDownloader {
    func downloadWith(url: URL, result: @escaping (URL?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        let manager = AFURLSessionManager(sessionConfiguration: configuration)
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)
        
        let downloadTask = manager.downloadTask(
            with: request,
            progress: nil,
            destination: { (url, response) -> URL in
                guard let cache = try? FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true),
                    let fileName = response.suggestedFilename else {
                        return url
                }
                return cache.appendingPathComponent(fileName)
        }) { (response, url, error) in
            result(url, error)
        }
        downloadTask.resume()
    }
}
