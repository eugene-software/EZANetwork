//
//  EZARequest
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
import MobileCoreServices

public protocol EZARequest {
    
    var url: URL { get }
    var path: String? { get }
    var method: EZANetwork.HTTPMethod { get }
    var task: EZATask { get }
    var headers: [String: String]? { get }
}

public enum EZATask {
    
    case empty
    
    case bodyData(Data)
    case bodyParameters([String: Any])
    case bodyEncodable(Encodable, encoder: JSONEncoder?)
    
    case query(parameters: [String: Any])
    
    case uploadFile(URL)
    case uploadData(Data)
    case uploadMultipart(data: [FilePart], parameters: [String: Any]?)
}

public struct ProgressResponse {
    
    public let progress: Progress?
    public let response: URLResponse?
    public let data: Data?
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}
