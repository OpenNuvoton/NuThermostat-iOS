//
//  SocketManager.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC WPHU on 2023/5/10.
//

import Foundation

protocol TCPManagerDelegate: AnyObject {
    func tcpManagerDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String)
    func tcpManagerDidDisconnect(identifier: String)
}

protocol TCPManagerPoolDelegate: AnyObject {
    func tcpManagerPoolDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String)
    func tcpManagerPoolDidDisconnect(identifier: String)
}

class TCPManagerPool: TCPManagerDelegate {
    
    static let shared = TCPManagerPool()
    
    private var tcpManagers: [String: TCPManager] = [:]
//    private var ControllerTcpManager : TCPManager? = nil
    weak var delegate: TCPManagerPoolDelegate?
    // 私有化init方法，防止外部創建實例
    private init() {}
    
//    func setControllerTcpManager(fromConnectionWithIdentifier identifier: String){
//
//    }
    
    func addTCPManager(host: String, port: Int, identifier:String,callback: ((_ isSuccess: Bool,_ identifier:String) -> Void)?) {
        
        let tcpManager = TCPManager(identifier: identifier)
        tcpManager.delegate = self
        
        tcpManager.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            tcpManager.connectToServer(host: host, port: port) { isSuccess in
                if isSuccess {
                    // 成功連線到 TCP Server
                    self.tcpManagers[identifier] = tcpManager
                    callback?(true,identifier)
                } else {
                    callback?(false,identifier)
                    // 連線失敗
                }
            }
        }
    }
    
    func send(data: Data, toConnectionWithIdentifier identifier: String, callback: ((_ isSuccess: Bool) -> Void)?) {
        if let tcpManager = tcpManagers[identifier] {
            tcpManager.send(data: data, callback: callback)
        } else {
            callback?(false)
        }
    }
    
    func removeTCPManager(withIdentifier identifier: String) {
        tcpManagers.removeValue(forKey: identifier)
    }
    
    func tcpManagerDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String) {
        delegate?.tcpManagerPoolDidReceiveData(data: data, fromConnectionWithIdentifier: identifier)
    }
    
    func tcpManagerDidDisconnect(identifier: String) {
        delegate?.tcpManagerPoolDidDisconnect(identifier: identifier)
    }
    
}


class TCPManager: NSObject, StreamDelegate {
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private(set) var identifier: String// 增加標識符
    private var connectCallback: ((_ isSuccess: Bool) -> Void)? // 新增callback，用於儲存並連結回傳結果
    private var isStreamOpen = false // 新增狀態
    private var isErrorHandled = false
    weak var delegate: TCPManagerDelegate?
    
    init(identifier: String) {
        self.identifier = identifier
    }
    
    func connectToServer(host: String, port: Int, callback: @escaping (_ isSuccess: Bool) -> Void) {
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        
        guard let inputStream = inputStream, let outputStream = outputStream else {
            print("Failed to create streams")
            callback(false)
            return
        }
        
        self.connectCallback = callback // 監聽
        isStreamOpen = false // 初始化狀態
        isErrorHandled = false
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        let queue = DispatchQueue(label: "com.example.streamQueue")
        
        queue.async {
            inputStream.open()
            outputStream.open()
        }
    }
    
    func disconnect() {
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: .current, forMode: .common)
        outputStream?.remove(from: .current, forMode: .common)
        
        delegate?.tcpManagerDidDisconnect(identifier: identifier)
    }
    
    func send(data: Data,callback:((_ isSuccess:Bool)->Void)? = nil) {
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            if let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
                let length = buffer.count
                
                let bytesWritten = outputStream?.write(pointer, maxLength: length)
                if bytesWritten == length {
                    // 成功
                    print("(true)TCP Manager Send:\(data.map { String(format: "%02x", $0) })")
                    callback?(true)
                } else {
                    // 失败
                    print("(false)TCP Manager Send:\(data.map { String(format: "%02x", $0) })")
                    callback?(false)
                }
            }
        }
    }
    
    
    // MARK: - StreamDelegate
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if !isStreamOpen {
                isStreamOpen = true
                connectCallback?(true)
            }
        case .errorOccurred:
            if !isErrorHandled {
                // 处理错误发生的事件
                isErrorHandled = true
                connectCallback?(false)
            }
        case .hasBytesAvailable:
            guard let inputStream = aStream as? InputStream else { return }
            
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                let receivedData = Data(bytes: buffer, count: bytesRead)
                //                delegate?.tcpManagerDidReceiveData(data: receivedData)
                delegate?.tcpManagerDidReceiveData(data: receivedData, fromConnectionWithIdentifier: identifier)
            }
            
        case .endEncountered:
            disconnect()
            
        default:
            break
        }
    }
}
