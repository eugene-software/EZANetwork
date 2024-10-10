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
import Combine

extension Publisher {
    
    func log(request: URLRequest) -> AnyPublisher<Self.Output, Self.Failure>
    where Self.Output == EZAResponse, Self.Failure == EZAError
    {
        handleEvents(receiveSubscription: { _ in
            request.networkRequestDidStart()
        }, receiveOutput: { output in
            if let _ = output.data {
                request.networkRequestDidComplete(response: output, error: nil)
            } else if let progress = output.progress {
                request.networkRequestProgress(progress: progress)
            }
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                if case .invalidResponse(let code, let response) = error {
                    request.networkRequestDidComplete(response: response, error: error)
                } else {
                    request.networkRequestDidComplete(response: nil, error: error)
                }
            }
        })
        .eraseToAnyPublisher()
    }
}

extension URLRequest {
    
    func networkRequestDidStart() {
        var message = [String]()
        
        message.append("\n⚪️ --> \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "")")
        
        if let headersString = self.allHTTPHeaderFields?.prettyPrintedJSONString {
            message.append("Headers:")
            message.append(headersString)
        }
        
        if let bodyString = self.httpBody?.prettyPrintedJSONString  {
            message.append("Body:")
            message.append(bodyString)
        }
        
        message.append("⚪️ --> END \(self.httpMethod ?? "")")
        EZALogger.log(message.joined(separator: "\n"), level: .debug)
    }
    
    func networkRequestProgress(progress: Progress) {
        
        guard let url = self.url else { return }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        var message = [String]()
        message.append("\n⚪️ <-- PROGRESS for: \(components?.url?.absoluteString ?? "")")
        message.append("\(progress.completedUnitCount)\\\(progress.totalUnitCount) bytes")
        message.append("⚪️ <-- END PROGRESS")
        EZALogger.log(message.joined(separator: "\n"), level: .verbose)
    }
    
    func networkRequestDidComplete(response: EZAResponse?, error: Error?) {
        
        let urlResponse = response?.urlResponse as? HTTPURLResponse
        let data = response?.data
        
        var message = [String]()
        
        if let error = error {
            message.append("\n❌ <-- \(urlResponse?.statusCode ?? 000) \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "")")
            message.append("\(error)")
            
        } else {
            message.append("\n✅ <-- \(urlResponse?.statusCode ?? 000) \(self.url?.absoluteString ?? "")")
        }
        
        if let headersString = urlResponse?.allHeaderFields.prettyPrintedJSONString {
            message.append("Headers:")
            message.append(headersString)
        }
        
        if let bodyString = data?.prettyPrintedJSONString {
            message.append("Body:")
            message.append(bodyString)
        }
        message.append("\(error != nil ? "🛑" : "⚪️") <-- END HTTP")
        EZALogger.log(message.joined(separator: "\n"), level: error != nil ? .error : .debug)
    }
}


private extension Data {
    
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes, .prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return String(prettyPrintedString)
    }
}

private extension Dictionary {
    
    var prettyPrintedJSONString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.withoutEscapingSlashes, .prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return String(prettyPrintedString)
    }
}
