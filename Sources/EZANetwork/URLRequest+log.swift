//
//  URLRequest+log.swift
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
import SwiftyBeaver
import Combine

extension Publisher {
    
    func log(request: URLRequest) -> Publishers.HandleEvents<Self>
    where Self.Output == URLSession.DataTaskPublisher.Output
    {
        handleEvents(receiveSubscription: { _ in
            request.networkRequestDidStart()
        }, receiveOutput: { output in
            request.networkRequestDidComplete(result: output.response as? HTTPURLResponse, currentData: output.data, error: nil, duration: 0)
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                request.networkRequestDidComplete(result: nil, currentData: nil, error: error, duration: 0)
            }
        })
    }
    
    func log(request: URLRequest) -> Publishers.HandleEvents<Self>
    where Self.Output == ProgressResponse
    {
        handleEvents(receiveSubscription: { _ in
            request.networkRequestDidStart()
        }, receiveOutput: { output in
            request.networkRequestDidComplete(result: output.response as? HTTPURLResponse, currentData: output.data, error: nil, duration: 0)
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                request.networkRequestDidComplete(result: nil, currentData: nil, error: error, duration: 0)
            }
        })
    }
}

extension URLRequest {
    
    func networkRequestDidStart() {
        var message = [String]()
        
        message.append("NETWORK_LOG \n--> \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "")")
        
        self.allHTTPHeaderFields?
            .map({ "\($0): \($1)" })
            .forEach { message.append($0) }
        
        if let body = self.httpBody {
            message.append(String(describing: body))
        }
        
        message.append("--> END \(self.httpMethod ?? "")")
        SwiftyBeaver.debug(message.joined(separator: "\n"))
    }
    
    func networkRequestDidComplete(result: HTTPURLResponse?, currentData: Data?, error: Error?, duration: Int) {
        var message = [String]()
        
        if error != nil {
            message.append("\n🛑 REQUEST ERROR\n<-- \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "") (\(duration)ms)")
            message.append("\(String(describing: error))")
            message.append("🛑 <-- END HTTP")
        } else {
            let divider = 200...299 ~= result!.statusCode ? "✅" : "❌"
            message.append("\n\(divider)<-- \(result?.statusCode ?? 000) \(self.url?.absoluteString ?? "") (\(duration)ms)")
            result?.allHeaderFields
                .map({ "\($0): \($1)" })
                .forEach { message.append($0) }
            
            message.append(String(currentData?.prettyPrintedJSONString ?? ""))
            message.append("\(divider)<-- END HTTP")
        }
        SwiftyBeaver.debug(message.joined(separator: "\n"))
    }
}


private extension Data {

    var prettyPrintedJSONString: NSString? { 
            guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
                  let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
                  let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
            return prettyPrintedString
        }
}
