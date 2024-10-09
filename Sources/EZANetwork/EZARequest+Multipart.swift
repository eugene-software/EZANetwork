//
//  EZARequest+Multipart.swift
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
import CoreServices

public struct FilePart {
    
    let name: String
    let fileName: String
    let mimeType: String
    let fileData: Data?
    let fileURL: URL?
    
    // Initializer for in-memory data (Data)
    public init(fileData: Data, name: String, fileName: String, mimeType: String) {
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileData = fileData
        self.fileURL = nil
    }
    
    // Initializer for file URL (Automatically get file name and MIME type)
    public init(fileURL: URL, name: String) {
        self.name = name
        self.fileURL = fileURL
        self.fileData = nil
        
        // Use FileManager to get the file name
        self.fileName = fileURL.lastPathComponent
        
        // Get file extension and determine the MIME type
        let fileExtension = fileURL.pathExtension
        self.mimeType = Self.mimeType(for: fileExtension)
    }
    
    private static func mimeType(for pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
           let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }
        return "application/octet-stream" // Default MIME type if not found
    }
}


extension EZARequest {

    private static var boundary: String {
        "EZARequest.Boundary-\(UUID().uuidString)"
    }
    
    func createMultipartDataRequest(url: URL, fileParts: [FilePart], parameters: [String: Any]?) throws -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        
        let boundary = Self.boundary
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        let parameters = parameters ?? [:]
        
        for (key, value) in parameters {
          httpBody.appendString(convertFormField(named: key, value: "\(value)", using: boundary))
        }
        
        for filePart in fileParts {
            
            let fileData: Data
            if let data = filePart.fileData {
                fileData = data
            } else if let url = filePart.fileURL {
                do {
                    fileData = try Data(contentsOf: url)
                } catch {
                    throw EZANetworkError(error)
                }
            } else {
                continue
            }
            httpBody.append(convertFileData(fieldName: filePart.name,
                                            fileName: filePart.fileName,
                                            mimeType: filePart.mimeType,
                                            fileData: fileData,
                                            using: boundary))
        }

        httpBody.appendString("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
    
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
      var fieldString = "--\(boundary)\r\n"
      fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
      fieldString += "\r\n"
      fieldString += "\(value)\r\n"

      return fieldString
    }
    
    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
      var data = Data()

      data.appendString("--\(boundary)\r\n")
      data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
      data.appendString("Content-Type: \(mimeType)\r\n\r\n")
      data.append(fileData)
      data.appendString("\r\n")

      return data as Data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}
