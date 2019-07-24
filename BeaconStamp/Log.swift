//
//  Log.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/22.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

// for debug
public protocol DebugLogDelegate {
    func addLog(log: String)
}

class Log {
    
    static var showDebugLog: Bool = false
    static var debugLogDelegate: DebugLogDelegate?

    class func debugLog(_ message: String = "", function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        
        var log = ""
        if let fileName = URL(string: file.description)?.lastPathComponent {
            log = "time: \(NSDate()), message: \(message), function: \(function), file: \(fileName), line: \(line)"
        } else {
            log = "time: \(NSDate()), message: \(message), function: \(function), file: \(file), line: \(line)"
        }

        #if DEBUG
        if showDebugLog {
            print(log)
        }
        #endif
        
        debugLogDelegate?.addLog(log: log)
    }

}
