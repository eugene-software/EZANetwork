//
//  EZARequest+internal.swift
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

extension EZARequest {
    
    var urlRequestPublisher: AnyPublisher<URLRequest, Error> {
        
        switch task {
        case .uploadMultipart(let data, let parameters):
            
            let request = self
            return Just(urlComponents.url!)
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .tryMap { url in
                    try request.createMultipartDataRequest(url: url, fileParts: data, parameters: parameters)
                }
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        default:
            var currentRequest = URLRequest(url: urlComponents.url!)
            currentRequest.httpMethod = method.rawValue
            currentRequest.allHTTPHeaderFields = headers
            currentRequest.httpBody = httpBody
            return Just(currentRequest).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
    }
}


extension EZARequest {
    
    func taskPublisher(for request: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        switch task {
        case .uploadData, .uploadFile:
            return URLSession.shared.uploadTaskPublisher(for: request, task: task)
        default:
            return URLSession.shared.dataTaskPublisher(for: request).mapError { $0 as Error}.eraseToAnyPublisher()
        }
    }
}

private extension URLSession {
    
    func uploadTaskPublisher(for request: URLRequest, task: EZATask) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        
        let subject: PassthroughSubject<URLSession.DataTaskPublisher.Output, Error> = .init()
        
        var uploadTask = uploadTask(with: task, request: request) { data, response, error in
            guard let data = data, let response = response else {
                subject.send(completion: .failure(error as? URLError ?? URLError(.badServerResponse)))
                return
            }
            subject.send((data: data, response: response))
        }
        uploadTask?.resume()
        return subject.eraseToAnyPublisher()
    }
    
    func uploadTask(with task: EZATask, request: URLRequest, completion: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionUploadTask? {
        switch task {
        case .uploadFile(let url):
            return URLSession.shared.uploadTask(with: request, fromFile: url, completionHandler: completion)
        case .uploadData(let data):
            return URLSession.shared.uploadTask(with: request, from: data, completionHandler: completion)
        default:
            return nil
        }
    }
}

private extension EZARequest {
    
    var queryParams: [URLQueryItem]? {
        
        switch task {
        case .query(let params):
            return params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        default:
            return nil
        }
    }
    
    var httpBody: Data? {
        
        switch task {
        case .empty, .uploadFile, .uploadData, .query, .uploadMultipart:
            return nil
        case .bodyData(let data):
            return data
        case .bodyParameters(let parameters):
            let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
            return jsonData
        case .bodyEncodable(let json, let encoder):
            let encoder = encoder ?? JSONEncoder()
            return try? encoder.encode(json)
        }
    }
    
    var fullURL: URL {
        path != nil ? url.appendingPathComponent(path!) : url
    }
    
    var urlComponents: URLComponents {
        
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)!
        
        if let query = queryParams {
            components.queryItems = query
        }
        return components
    }
}

extension PassthroughSubject: @unchecked @retroactive Sendable { }
