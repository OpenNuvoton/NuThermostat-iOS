//
//  NetServiceBrowser.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/19.
//

import Foundation
import Network


class ServiceNWBrowserDelegate: NSObject {
    
    private static var _discoveryNuvotonIPListener: ((_ ipv4:String) -> Void)?
    var services = [NWEndpoint]()
    
    func setListener(callback:@escaping (_ ipv4:String) -> Void){
        ServiceNWBrowserDelegate._discoveryNuvotonIPListener = callback
    }
    
    func discoverServices() {
        let parameters = NWParameters()
        let browser = NWBrowser(for: .bonjour(type: "_Nuvoton._tcp", domain: nil), using: parameters)
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Service browser is ready")
                break
            case .failed(let error):
                print("Service browser failed with error: \(error.localizedDescription)")
                break
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            for change in changes {
                switch change {
                case .added(let browseResult):
                    switch browseResult.endpoint {
                    case .hostPort(let host, let port):
                        print("added hostPort \(host) \(port)")
                        break
                    case .service(let name, let type, let domain, let interface):
                        print("added service name：\(name)")
                        print("added service type：\(type)")
                        print("added service domain：\(domain)")
                        print("added service interface：\(String(describing: interface))")
                        break
                    default:
                        print("fail")
                        break
                    }
                case .removed(let browseResult):
                    print("removed \(browseResult.endpoint)")
                case .changed(_, let browseResult, let flags):
                    if flags.contains(.interfaceAdded) {
                        print("\(browseResult.endpoint) added interfaces")
                        break
                    }
                    if flags.contains(.interfaceRemoved) {
                        print("\(browseResult.endpoint) removed interfaces")
                        break
                    }
                default:
                    print("no change")
                }
            }
            
            for result in results {
                
                self?.services.append(result.endpoint)
                //                self?.resolveEndpoint(result.endpoint)
                print("Found a result: \(result)")
                print("Found a debugDescription: \(result.endpoint.debugDescription as NSString?)")
                
                
                let connection = NWConnection(to: result.endpoint, using: .tcp)
                connection.stateUpdateHandler = { state in
                    print("state: \(state)")
                    switch state {
                    case .ready:
                        if let endpoint = connection.currentPath?.remoteEndpoint {
                            print("connection: \(connection.currentPath?.remoteEndpoint?.hashValue)")
                            print("endpoint: \(endpoint)")
                            switch endpoint {
                            case .hostPort(let host, _):
                                if case let NWEndpoint.Host.ipv4(ipv4Address) = host {
                                    let ipAddress = ipv4Address.debugDescription
                                    print("IPv4 host: \(host)")
                                    print("IPv4 address: \(ipAddress)")
//                                    // 将获取到的 IPv4 地址传递给 ViewController
//                                    DispatchQueue.main.async { [weak self] in
//                                        self?.handleIPv4Address(ipAddress)
//                                    }
                                    ServiceNWBrowserDelegate._discoveryNuvotonIPListener?(ipAddress)
                                }
                            default:
                                break
                            }
                        }
                        connection.cancel() // 只需要获取 IP 地址，无需建立连接
                    case .failed(let error):
                        print("Failed to resolve endpoint \(result.endpoint): \(error.localizedDescription)")
       
                    default:
                        break
                    }
                }
                connection.start(queue: .main)
                
                
            }
        }
        
        
        browser.start(queue: .main)
    }
    
    //    func resolveEndpoint(_ endpoint: NWEndpoint) {
    //        print("resolveEndpoint: \(endpoint)")
    //        switch endpoint {
    //        case .service(let name, _, let domain, let interface):
    //            let endpoint = NWEndpoint.service(name: name, type: "_matter._tcp", domain: domain, interface: interface)
    //
    //            let connection = NWConnection(to: endpoint, using: .tcp)
    //            connection.stateUpdateHandler = { state in
    //                switch state {
    //                case .ready:
    //                    connection.cancel() // 只需要获取 IP 地址，无需建立连接
    //                case .failed(let error):
    //                    print("Failed to resolve endpoint \(endpoint): \(error.localizedDescription)")
    //                default:
    //                    break
    //                }
    //            }
    //
    //            connection.start(queue: .main)
    //        default:
    //            break
    //        }
    //    }
    
}
