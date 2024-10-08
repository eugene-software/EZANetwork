//
//  EZALogger+Internal.swift
//  EZANetwork
//
//  Created by Eugene Software on 5/18/21.
//
//  Copyright (c) 2024 Eugene Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

extension EZALogger {
    
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    static func log(_ message: String, level: LogLevel = .info) {
        #if DEBUG
        if level.priority >= logLevel.priority {
            let timestamp = formatter.string(from: Date())
            print("\n\(timestamp) EZANetwork: [\(level.rawValue)] \(message)\n")
        }
        #endif
    }
}

private extension EZALogger.LogLevel {
    
    var priority: Int {
        switch self {
        case .verbose: 0
        case .debug: 1
        case .info: 2
        case .warning: 3
        case .error: 4
        case .disabled: 5
        }
    }
}
