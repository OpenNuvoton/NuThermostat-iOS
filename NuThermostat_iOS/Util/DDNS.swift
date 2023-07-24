//import Foundation
//import dnssd
//
//class DNSDiscovery {
//    var browseRef: DNSServiceRef?
//    // 定义一个全局变量来保存DNSDiscovery实例的引用
//        static var shared: DNSDiscovery?
//    // 创建一个C函数来作为回调函数
//      static func browseCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, serviceName: UnsafePointer<Int8>?, regtype: UnsafePointer<Int8>?, replyDomain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
//          // 通过shared实例来调用实例方法
//          shared?.handleBrowseCallback(sdRef: sdRef, flags: flags, interfaceIndex: interfaceIndex, errorCode: errorCode, serviceName: serviceName, regtype: regtype, replyDomain: replyDomain, context: context)
//      }
//    
//    func handleBrowseCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, serviceName: UnsafePointer<Int8>?, regtype: UnsafePointer<Int8>?, replyDomain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
//        if errorCode == kDNSServiceErr_NoError {
//            // Handle the discovered service here
//            let service = String(cString: serviceName!)
//            let type = String(cString: regtype!)
//            let domain = String(cString: replyDomain!)
//            
//            // Resolve the IP address and hostname for the discovered service
//            var resolverRef: DNSServiceRef?
//            let error = DNSServiceGetAddrInfo(&resolverRef, 0, interfaceIndex, DNSServiceProtocol(kDNSServiceProtocol_IPv4), service, { dNSServiceRef, dNSServiceFlags, interfaceIndex, errorCode, hostname, address, ttl, context in
//                print("主機名稱：\(hostname)")
//                print("IP 地址：\(address)")
//            }, nil)
////            let error = DNSServiceGetAddrInfo(&resolverRef, 0, interfaceIndex, service, type, domain, { (_, _, _, _, addressPtr, hostnamePtr, _) in
////                if let addressPtr = addressPtr, let hostnamePtr = hostnamePtr {
////                    let address = addressPtr.pointee
////                    let hostname = String(cString: hostnamePtr)
////                    let ipAddress = address.socketAddressString
////                    print("主機名稱：\(hostname)")
////                    print("IP 地址：\(ipAddress)")
////                }
////            }, nil)
//            
//            if error != kDNSServiceErr_NoError {
//                // Handle the resolution error
//                print("解析錯誤：\(error)")
//            }
//            
//            // Stop the resolver
//            if let resolverRef = resolverRef {
//                DNSServiceRefDeallocate(resolverRef)
//            }
//        } else {
//            // Handle the browse error
//            print("瀏覽錯誤：\(errorCode)")
//        }
//    }
//    
//    func startDiscovery() {
//        let flags: DNSServiceFlags = 0
//               let interfaceIndex: UInt32 = 0
//               let regtype = "_Nuvoton._tcp"
//               let domain = ""
//               
//               // 设置shared实例的引用
//               DNSDiscovery.shared = self
//               
//               let error = DNSServiceBrowse(&browseRef, flags, interfaceIndex, regtype, domain, DNSDiscovery.browseCallback, nil)
//               if error != kDNSServiceErr_NoError {
//                   // Handle the browse error
//                   print("瀏覽錯誤：\(error)")
//               }
//    }
//    
//    func stopDiscovery() {
//        if let browseRef = browseRef {
//            DNSServiceRefDeallocate(browseRef)
//            self.browseRef = nil
//        }
//    }
//}
//
////// 使用範例：
////let dnsDiscovery = DNSDiscovery()
////dnsDiscovery.startDiscovery()
////
////// 停止發現
////// dnsDiscovery.stopDiscovery()
