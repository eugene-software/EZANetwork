//
//  URLSessionProgressTracker.swift
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

class URLSessionProgressTracker: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, @unchecked Sendable {
    
    private var progressSubject = PassthroughSubject<ProgressResponse, Error>()
    private var accumulatedData = Data()
    private let request: URLRequest
    private var response: URLResponse?
    private var progress: Progress = Progress(totalUnitCount: 0)
    
    init(request: URLRequest) {
        self.request = request
    }
    
    func start() -> AnyPublisher<ProgressResponse, Error> {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

        // Start the download task
        let downloadTask = session.dataTask(with: request)
        defer {
            downloadTask.resume()
        }
        return progressSubject.eraseToAnyPublisher()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            self.response = response
            if response.expectedContentLength > 0 {
                // Set the total unit count for progress tracking
                progress.totalUnitCount = response.expectedContentLength
                progressSubject.send(ProgressResponse(progress: progress, response: response, data: nil))
            }
            completionHandler(.allow)
        }
    
    // Delegate method for receiving data incrementally
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Accumulate the data received so far
        accumulatedData.append(data)
        progress.completedUnitCount = Int64(accumulatedData.count)
        progressSubject.send(ProgressResponse(progress: progress, response: response, data: nil))
    }

    // Handle completion of download
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? URLError {
            progressSubject.send(completion: .failure(error))
        } else {
            // Emit the final result with full data and progress 100%
            progress.completedUnitCount = progress.totalUnitCount
            progressSubject.send(ProgressResponse(progress: progress, response: response, data: accumulatedData))
            progressSubject.send(completion: .finished)
        }
    }
}
