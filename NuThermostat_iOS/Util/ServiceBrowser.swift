import Foundation
import CoreFoundation
import dnssd
import Darwin


class ServiceBrowser {
    var shouldExitRunLoop = false
    var browser: DNSServiceRef?
    
    func discoverServices() {
        DispatchQueue.global().async {
            var browser: DNSServiceRef?
            let error = DNSServiceBrowse(&browser, 0, 0, "_Nuvoton._tcp", "local.", browseCallback, nil)
            
            if error != kDNSServiceErr_NoError {
                print("启动服务浏览出错: \(error)")
                return
            }
            
            // 5秒后关闭搜索
            let backgroundRunLoop = RunLoop.current
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.shouldExitRunLoop = true
            }
            
            while !self.shouldExitRunLoop {
                let result = DNSServiceProcessResult(browser)
                
                if result != kDNSServiceErr_NoError {
                    print("处理 DNS 服务结果出错: \(result)")
                    break
                }
                
                backgroundRunLoop.run(mode: .default, before: .distantFuture)
            }
            
            // 清理资源
            DNSServiceRefDeallocate(browser)
        }
    }
}

func browseCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, serviceName: UnsafePointer<Int8>?, regtype: UnsafePointer<Int8>?, domain: UnsafePointer<Int8>?, context: UnsafeMutableRawPointer?) {
    guard errorCode == kDNSServiceErr_NoError,
          let serviceName = serviceName,
          let regtype = regtype,
          let domain = domain
            
    else {
        print("错误: \(errorCode)")
        return
    }
    
    print("发现服务: \(String(cString: serviceName))")
    print("类型: \(String(cString: regtype))")
    print("域名: \(String(cString: domain))")
    
    var resolverRef: DNSServiceRef?
    let error = DNSServiceGetAddrInfo(&resolverRef, 0, interfaceIndex, DNSServiceProtocol(kDNSServiceProtocol_IPv4), serviceName, { dNSServiceRef, dNSServiceFlags, interfaceIndex, errorCode, hostname, address, ttl, context in
        print("主機名稱：\(hostname)")
        print("IP 地址：\(address)")
    }, nil)
    
    // 解析服务以获取其IP地址
    var resolveService: DNSServiceRef?
    let resolveError = DNSServiceResolve(&resolveService, 0, interfaceIndex, serviceName, regtype, domain, { sdRef, flags, interfaceIndex, errorCode, fullname, hosttarget, port, txtLen, txtRecord, context in
        guard errorCode == kDNSServiceErr_NoError,
              let fullname = fullname,
              let hosttarget = hosttarget
        else {
            print("解析回调错误: \(errorCode)")
            return
        }
        
        let host = String(cString: hosttarget)
        print("已解析的主机: \(host)")
        
    }, nil)
    
    if resolveError != kDNSServiceErr_NoError {
        print("解析服务出错: \(resolveError)")
    }
}

//func resolveCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, fullname: UnsafePointer<Int8>?, hosttarget: UnsafePointer<Int8>?, port: UInt16, txtLen: UInt16, txtRecord: UnsafeRawPointer?, context: UnsafeMutableRawPointer?) {
//    guard errorCode == kDNSServiceErr_NoError,
//          let hosttarget = hosttarget
//    else {
//        print("解析服务回调错误: \(errorCode)")
//        return
//    }
//
//    let host = String(cString: hosttarget)
//    print("已解析的主机: \(host)")
//
//    // 处理获取到的IP地址
//    if let ipAddress = String(cString: hosttarget, encoding: .utf8) {
//        print("已解析的IP地址: \(ipAddress)")
//        // 在这里可以将IP地址存储到适当的变量中，或执行其他需要的操作
//    }
//
//}

func resolveCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, fullname: UnsafePointer<Int8>?, hosttarget: UnsafePointer<Int8>?, port: UInt16, txtLen: UInt16, txtRecord: UnsafeRawPointer?, context: UnsafeMutableRawPointer?) {
    guard errorCode == kDNSServiceErr_NoError,
        let hosttarget = hosttarget
    else {
        print("解析服务出错: \(errorCode)")
        return
    }
    
    let flags = Int32(bitPattern: flags)
    let addAddress = flags & Int32(kDNSServiceFlagsAdd) != 0
    let ipAddress = String(cString: hosttarget)
    
    if addAddress {
        print("已解析的IP地址: \(ipAddress)")
    }
}




//let serviceBrowser = ServiceBrowser()
//serviceBrowser.discoverServices()
//
//// 在此添加适当的代码，以确保应用程序保持运行，例如启动主运行循环或等待用户输入。

