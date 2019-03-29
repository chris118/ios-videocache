//
//  MediaDownloader.swift
//  VideoCache
//
//  Created by Chris on 2019/2/25.
//  Copyright © 2019 putao. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

struct VideoHeaderInfo {
    var acceptRange: Bool
    var contentRange: Int64
    var mimeType: String
    var contentType: String
    
    mutating func VideoHeaderInfo(_acceptRange: Bool, _contentRange: Int64,  _mimeType: String, _contentType: String){
        acceptRange = _acceptRange
        contentRange = _contentRange
        mimeType = _mimeType
        contentType = _contentType
    }
}

class MediaDownloader: NSObject {
    static let shared = MediaDownloader()
    
    private var _queue = OperationQueue()
    private lazy var session: URLSession = {
        _queue.name = "com.putao.block.task"
        let _session = URLSession.init(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        return _session
    }()
    
    private var loadingRequest: AVAssetResourceLoadingRequest?
    private var task: URLSessionDataTask?
    private var bytesOffset: Int64 = 0
    
    func requestHeaderInfo(url: URL, loadingRequest: AVAssetResourceLoadingRequest) {
        self.loadingRequest = loadingRequest;
        let dataRequest = loadingRequest.dataRequest
        
        var originalUrlString = url.absoluteString
        originalUrlString = originalUrlString.replacingOccurrences(of: "PUTAO://", with: "")
        let originalUrl = URL(string: originalUrlString)!
        
        let request = NSMutableURLRequest(url: originalUrl)
        if let _dataRequest = dataRequest {
            print("requestHeaderInfo ------- requestedOffset=\(_dataRequest.requestedOffset) currentOffset=\(_dataRequest.currentOffset) requestedLength=\(_dataRequest.requestedLength)")

            let start = _dataRequest.currentOffset
            let end = _dataRequest.currentOffset + Int64(_dataRequest.requestedLength) - 1
            
            request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
            self.task = self.session.dataTask(with: request as URLRequest)
                    
            task?.resume()
            
             bytesOffset = end
        }
    }
    
    private func fillContentInformation(response: URLResponse) -> VideoHeaderInfo? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        var contentRange = httpResponse.allHeaderFields["Content-Range"] as? String
        contentRange = contentRange?.components(separatedBy: "/")[1]
        let range = Int64(contentRange ?? "0") ?? 0
        
        let acceptRange = httpResponse.allHeaderFields["Accept-Ranges"] as? String
        let isBytesRange = (acceptRange ?? "") == "bytes"
        
        let mimeType = httpResponse.mimeType ?? ""
        let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        let contentType = type?.takeUnretainedValue() as String?
        
        let headerInfo = VideoHeaderInfo(acceptRange: isBytesRange, contentRange: range, mimeType: mimeType, contentType: contentType ?? "")
        self.loadingRequest?.contentInformationRequest?.contentType = headerInfo.contentType
        self.loadingRequest?.contentInformationRequest?.contentLength = headerInfo.contentRange
        self.loadingRequest?.contentInformationRequest?.isByteRangeAccessSupported = headerInfo.acceptRange
        
        return headerInfo
    }
    
    private func handleReceivedData(data: Data) {
        self.loadingRequest?.dataRequest?.respond(with: data)
    }
}

extension MediaDownloader: URLSessionDataDelegate{
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        let header = self.fillContentInformation(response: response)
        print("fillContentInformation ------- mimeType: \(String(describing: header?.mimeType)) contentType: \(String(describing: header?.contentType)) contentRange: \(String(describing: header?.contentRange))")
        
        let mimeType = header?.mimeType ?? ""
        
        if mimeType.contains("video/") || mimeType.contains("audio/") || mimeType.contains("application"){
            completionHandler(.allow)
        }else {
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
         print("didRecei ve data: \(data.count) btyes")
        self.loadingRequest?.dataRequest?.respond(with: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
       self.loadingRequest?.finishLoading()
    }
}
