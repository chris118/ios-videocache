//
//  SocketServer.swift
//  VideoCache
//
//  Created by Chris on 2019/3/26.
//  Copyright © 2019 putao. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import MobileCoreServices

class SocketServer: NSObject {
    static let shared = SocketServer()
    
    var serverSocket: GCDAsyncSocket?
    var clientSocket: GCDAsyncSocket?
    
    private var _queue = OperationQueue()
     private var task: URLSessionDataTask?
    private lazy var session: URLSession = {
        _queue.name = "com.putao.block.task"
        let _session = URLSession.init(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        return _session
    }()
    
    func statr() {
        let queue = DispatchQueue(label: "socket server")

        serverSocket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
        
        do {
            try serverSocket?.accept(onPort: 3003)
            print("监听成功")
        }catch _ {
            print("监听失败")
        }
    }
    
    func sendData(data: Data) {
        clientSocket?.write(data, withTimeout: -1, tag: 0)
    }
    
    var request : NSMutableURLRequest?
    func downloadVideo(){
        let originalUrl = URL(string: "http://gedftnj8mkvfefuaefm.exp.bcevod.com/mda-hc2s2difdjz6c5y9/hd/mda-hc2s2difdjz6c5y9.mp4?playlist%3D%5B%22hd%22%5D&auth_key=1500559192-0-0-dcb501bf19beb0bd4e0f7ad30c380763&bcevod_channel=searchbox_feed&srchid=3ed366b1b0bf70e0&channel_id=2&d_t=2&b_v=9.1.0.0")!
        request = NSMutableURLRequest(url: originalUrl)
        
        let start = 0
        let end =  1
        
        print("bytes=\(start)-\(end)")
        request?.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
        
        self.task = self.session.dataTask(with: request! as URLRequest)
        task?.resume()
    }
    
//    func handleResponse(response: URLResponse) {
//        guard let httpResponse = response as? HTTPURLResponse else {
//            return
//        }
//        let contentRange = httpResponse.allHeaderFields["Content-Length"] as? String
//        let range = Int64(contentRange ?? "0") ?? 0
//
//        let start = 0
//        let end =  range
//
//        request?.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
//
//        self.task = self.session.dataTask(with: request as! URLRequest)
//        task?.resume()
//    }
}

extension SocketServer: URLSessionDataDelegate{
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
                print("response: \(response)")
        //        handleResponse(response: response)
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String
        print("response: \(String(describing: contentRange))")
        
         completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("didReceive data: \(data.count) btyes")
        
        clientSocket?.write(data, withTimeout: -1, tag: 0)
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: \(String(describing: error)) btyes")
    }
}

extension SocketServer: GCDAsyncSocketDelegate {
    
    //当接收到新的Socket连接时执行
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {

        print("连接成功")
        print("连接地址 \(newSocket.connectedHost ?? "")")
        print("端口号" + String(newSocket.connectedPort))
        clientSocket = newSocket
        
//        downloadVideo()
        
        //第一次开始读取Data
        clientSocket!.readData(withTimeout: -1, tag: 0)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let message = String(data: data, encoding: String.Encoding.utf8)
        print(message!)
        
         downloadVideo()
        
        //再次准备读取Data,以此来循环读取Data
        sock.readData(withTimeout: -1, tag: 0)
    }
}


