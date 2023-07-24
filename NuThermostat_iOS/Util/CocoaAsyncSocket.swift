//
//  CocoaAsyncSocket.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/21.
//

import Foundation
import CocoaAsyncSocket

//protocol DNSDiscoveryDelegate: class {
//    func didDiscoverService(name: String, type: String, domain: String, ipAddress: String)
//}
//
//class DNSDiscoveryManager: NSObject, GCDAsyncUdpSocketDelegate {
//    weak var delegate: DNSDiscoveryDelegate?
//    var udpSocket: GCDAsyncUdpSocket?
//
//    func startDiscovery() {
//        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
//
//        do {
//            try udpSocket?.bind(toPort: 0)
//            try udpSocket?.enableBroadcast(true)
//            try udpSocket?.beginReceiving()
//
//            let queryData = buildDNSQuery()
//            udpSocket?.send(queryData, toHost: "224.0.0.251", port: 5353, withTimeout: -1, tag: 0)
//        } catch {
//            print("Error starting DNS discovery: \(error.localizedDescription)")
//        }
//    }
//
//    func stopDiscovery() {
//        udpSocket?.close()
//        udpSocket = nil
//    }
//
//    private func buildDNSQuery() -> Data {
//        // 构建 DNS-SD 查询数据
//        // ...
//        // 返回查询数据的字节流
//        let request = "_services._dns-sd._udp"
//        let requestBytes = [UInt8](request.utf8)
//        let requestData = Data(bytes: requestBytes, count: requestBytes.count)
////        let port: UInt16 = 5353
//        return requestData
//    }
//
//    // GCDAsyncUdpSocketDelegate 方法
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
//        // 处理接收到的数据
//           let responseString = String(data: data, encoding: .utf8)
//           print("Received response: \(responseString ?? "")")
//
//        // 解析 DNS-SD 响应数据
//        // 提取服务名、类型、域名和 IP 地址
//        // ...
//        // 通知代理对象
////        delegate?.didDiscoverService(name: serviceName, type: serviceType, domain: serviceDomain, ipAddress: ipAddress)
//    }
//}



class UDPPingManager: NSObject, GCDAsyncUdpSocketDelegate {
    private var udpSocket: GCDAsyncUdpSocket!
    private var pingCompletion: ((String?) -> Void)?
    
    func ping(domain: String, completion: @escaping (String?) -> Void) {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        pingCompletion = completion
        
        let packetData = "Ping".data(using: .utf8)!
        udpSocket.send(packetData, toHost: domain, port: 520, withTimeout: -1, tag: 0)
        
        do {
            try udpSocket.beginReceiving()
        } catch {
            print("Failed to start receiving: \(error.localizedDescription)")
            pingCompletion?(nil)
            udpSocket.close()
            udpSocket = nil
        }
    }
    
    // MARK: - GCDAsyncUdpSocketDelegate
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("UDP data sent successfully")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Failed to send UDP data: \(error?.localizedDescription ?? "")")
        pingCompletion?(nil)
        udpSocket.close()
        udpSocket = nil
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let response = String(data: data, encoding: .utf8) {
            print("Received UDP response: \(response)")
            let ipAddress = sock.connectedHost
            pingCompletion?(ipAddress())
        } else {
            print("Failed to parse UDP response")
            pingCompletion?(nil)
        }
        
        udpSocket.close()
        udpSocket = nil
    }
}
