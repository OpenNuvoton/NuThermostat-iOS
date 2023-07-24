//
//  WiFiTool.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/5/29.
//

import Foundation
import NetworkExtension
import Network

protocol DiscoveryManagerDelegate: AnyObject {
    func didDiscoverService(name: String, domain: String, ipAddress: String)
}

class DiscoveryManager: NSObject {
    private var browser: NetServiceBrowser!
    weak var delegate: DiscoveryManagerDelegate?

    override init() {
        super.init()
        browser = NetServiceBrowser()
        browser.delegate = self
    }

    func startDiscovery() {
        browser.searchForServices(ofType: "_services._dns-sd._udp", inDomain: "local.")
    }

    func stopDiscovery() {
        browser.stop()
    }
}

extension DiscoveryManager: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // 获取设备名称
        let name = service.name
        
        // 获取设备域名
        let domain = service.domain
        
        // 解析 IP 地址
        if let ipAddress = resolveIPAddress(service: service) {
            delegate?.didDiscoverService(name: name, domain: domain, ipAddress: ipAddress)
        }
    }
    
    private func resolveIPAddress(service: NetService) -> String? {
        guard let addresses = service.addresses, addresses.count > 0 else {
            return nil
        }
        
        var ipAddress: String?
        
        for addressData in addresses {
            var socketAddress = addressData.withUnsafeBytes { (ptr: UnsafePointer<sockaddr>) -> sockaddr in
                return ptr.pointee
            }
            
            if socketAddress.sa_family == UInt8(AF_INET) || socketAddress.sa_family == UInt8(AF_INET6) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                
                if getnameinfo(&socketAddress, socklen_t(socketAddress.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    ipAddress = String(cString: hostname)
                    break
                }
            }
        }
        
        return ipAddress
    }
}


