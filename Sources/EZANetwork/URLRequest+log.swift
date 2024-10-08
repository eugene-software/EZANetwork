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
    
    func log(request: URLRequest) -> Publishers.HandleEvents<Self>
    where Self.Output == URLSession.DataTaskPublisher.Output
    {
        handleEvents(receiveSubscription: { _ in
            request.networkRequestDidStart()
        }, receiveOutput: { output in
            request.networkRequestDidComplete(result: output.response as? HTTPURLResponse, currentData: output.data, error: nil)
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                request.networkRequestDidComplete(result: nil, currentData: nil, error: error)
            }
        })
    }
    
    func log(request: URLRequest) -> Publishers.HandleEvents<Self>
    where Self.Output == ProgressResponse
    {
        handleEvents(receiveSubscription: { _ in
            request.networkRequestDidStart()
        }, receiveOutput: { output in
            if let _ = output.data {
                request.networkRequestDidComplete(result: output.response as? HTTPURLResponse, currentData: output.data, error: nil)
            } else if let progress = output.progress {
                request.networkRequestProgress(progress: progress)
            }
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                request.networkRequestDidComplete(result: nil, currentData: nil, error: error)
            }
        })
    }
}

extension URLRequest {
    
    func networkRequestDidStart() {
        var message = [String]()
        
        message.append("\n⚪️ --> \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "")")
        
        if let headers = self.allHTTPHeaderFields {
            message.append("Headers:")
            message.append(headers.prettyPrintedJSONString ?? "")
        }
        
        if let body = self.httpBody {
            message.append("Body:")
            message.append(body.prettyPrintedJSONString ?? "")
        }
        
        message.append("--> END \(self.httpMethod ?? "")")
        Logger.log(message.joined(separator: "\n"))
    }
    
    func networkRequestProgress(progress: Progress) {
        
        guard let url = self.url else { return }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        var message = [String]()
        message.append("\n⚪️ <-- PROGRESS for: \(components?.url?.absoluteString ?? "")")
        message.append("\(progress.completedUnitCount)\\\(progress.totalUnitCount) bytes")
        message.append("⚪️ <-- END PROGRESS")
        Logger.log(message.joined(separator: "\n"))
    }
    
    func networkRequestDidComplete(result: HTTPURLResponse?, currentData: Data?, error: Error?) {
        var message = [String]()
        
        if error != nil {
            message.append("\n🛑 REQUEST ERROR\n<-- \(self.httpMethod ?? "") \(self.url?.absoluteString ?? "")")
            message.append("\(String(describing: error))")
            
        } else {
            let divider = 200...299 ~= result!.statusCode ? "✅" : "❌"
            message.append("\n\(divider) <-- \(result?.statusCode ?? 000) \(self.url?.absoluteString ?? "")")
        }
        
        if let headers = result?.allHeaderFields {
            message.append("Headers:")
            message.append(headers.prettyPrintedJSONString ?? "")
        }
        
        if let body = currentData {
            message.append("Body:")
            message.append(body.prettyPrintedJSONString ?? "")
        }
        message.append("⚪️ <-- END HTTP")
        Logger.log(message.joined(separator: "\n"))
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
