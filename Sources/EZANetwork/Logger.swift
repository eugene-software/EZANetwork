//
//  Logger.swift
//  EZANetwork
//
//  Created by Eugeniy Zaychenko on 10/8/24.
//

import Foundation

class Logger {
    
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // Log function that includes a timestamp and only prints in debug mode
    static func log(_ message: String, level: LogLevel = .info) {
        #if DEBUG
        let timestamp = formatter.string(from: Date())
        print("\(timestamp) EZANetwork: [\(level.rawValue)] \(message)")
        #endif
    }
    
    // Enumeration to represent different log levels
    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case debug = "DEBUG"
    }
}
