//
//  NetworkApiError.swift
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

public enum EZANetworkError: Error {
    
    case noRequest
    case decoding(Error)
    case server(code: Int, Data?)
    case badResponse(Error)
    case unknown(Error)
    case networkFailure
    
    init(_ error: Error) {

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed: self = .networkFailure
            default: self = .badResponse(urlError)
            }
        } else if let error = error as? DecodingError {
            self = .decoding(error)
        } else {
            self = .unknown(error)
        }
    }
}


extension Publisher {
    
    func filterStatusCodes() -> Publishers.TryMap<Self, ProgressResponse>
    where Self.Output == ProgressResponse
    {
        return tryMap { element -> ProgressResponse in
            guard let httpResponse = element.response as? HTTPURLResponse else {
                throw EZANetworkError.badResponse(URLError(.badServerResponse))
            }
            if 200..<300 ~= httpResponse.statusCode {
                return element
            } else {
                throw EZANetworkError.server(code: httpResponse.statusCode, element.data)
            }
        }
    }
    
    func filterStatusCodes() -> Publishers.TryMap<Self, Data>
    where Self.Output == URLSession.DataTaskPublisher.Output
    {
        return tryMap { element -> Data in
            guard let httpResponse = element.response as? HTTPURLResponse else {
                throw EZANetworkError.badResponse(URLError(.badServerResponse))
            }
            if 200..<300 ~= httpResponse.statusCode {
                return element.data
            } else {
                throw EZANetworkError.server(code: httpResponse.statusCode, element.data)
            }
        }
    }
    
    func mapInternalError() -> Publishers.MapError<Self, EZANetworkError> {
        return mapError {
            return ($0 is EZANetworkError) ? $0 as! EZANetworkError : EZANetworkError($0)
        }
    }
}
