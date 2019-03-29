//
//  PTHttpServer.swift
//  VideoCache
//
//  Created by Chris on 2019/3/28.
//  Copyright © 2019 putao. All rights reserved.
//

import Foundation
import GCDWebServers

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

extension String {
    func subString(start:Int, length:Int = -1) -> String {
        var len = length
        if len == -1 {
            len = self.count - start
        }
        let st = self.index(startIndex, offsetBy:start)
        let en = self.index(st, offsetBy:len)
        return String(self[st ..< en])
    }
}

class PTHttpServer: NSObject {
    static let shared = PTHttpServer()
    let webServer = GCDWebServer()
        
    func statr() {
        
//        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, asyncProcessBlock: { (request, completionBlock) in
//
//            let filepath = Bundle.main.path(forResource: "v", ofType: "mp4")
//
//
//            var contentRange = request.headers["Range"]
//             print(contentRange!)
//
//            let response =  GCDWebServerFileResponse(file: filepath ?? "", byteRange: request.byteRange)
//            completionBlock(response)
//        })

         let filepath = Bundle.main.path(forResource: "v", ofType: "mp4")!
         let fileUrl = URL(string: filepath)!
         let readHandler = try! FileHandle(forReadingFrom:fileUrl)
        
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, asyncProcessBlock: { (request, completionBlock) in

            var contentRange = request.headers["Range"]
            print(contentRange!)
            contentRange = contentRange?.subString(start: 6, length: (contentRange?.count)! - 6)
            let strs = contentRange?.components(separatedBy: "-")
            let start = Int(strs?[0] ?? "0")!
            let end = Int(strs?[1] ?? "0")!

            readHandler.seek(toFileOffset: UInt64(start))
            let data = readHandler.readData(ofLength: end + 1)
            
            let response = GCDWebServerDataResponse(data: data, contentType: "video/mp4")
            
            response.statusCode = 206
            response.setValue("bytes \(contentRange!)/\(fileUrl.fileSize)", forAdditionalHeader: "Content-Range")
            completionBlock(response)
        })
        
        webServer.start(withPort: 3003, bonjourName: "HttpServer")
        
        print("Visit \(String(describing: webServer.serverURL)) in your web browser")
    }
}
