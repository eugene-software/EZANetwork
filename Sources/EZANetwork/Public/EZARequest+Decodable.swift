//
//  EZARequest+Decodable.swift
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

public extension Publisher where Output == EZAResponse, Failure == EZAError {
    
    func decode<ResponseType: Decodable>(with decoder: JSONDecoder = .init()) -> AnyPublisher<ResponseType, EZAError> {
        
        self.flatMap { response -> AnyPublisher<ResponseType, EZAError> in
            guard let data = response.data, !data.isEmpty else {
                return Fail<ResponseType, EZAError>(error: EZAError.noData).eraseToAnyPublisher()
            }
        
            return Just(data)
                .decode(type: ResponseType.self, decoder: decoder)
                .mapError { error in
                    EZAError.decoding(error)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
