//
//  BonjourDiscovery.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/15.
//

import Foundation

class BonjourDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate
{
    var browser: NetServiceBrowser
    var services = [NetService]()
    static let instance = BonjourDiscovery()
    
    override init()
    {
        browser = NetServiceBrowser()
        services = []
    }
    
    func startDiscovery()
    {
        browser = NetServiceBrowser()
        services = []
        browser.delegate = self
        browser.searchForServices(ofType: "_matter._tcp", inDomain: "")
    }
    
    func stopDiscovery()
    {
        browser.stop()
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print ("netServiceBrowserWillSearch")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool)
    {
        print ("Found:" + service.name)
        self.services.append(service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool)
    {
        print ("Removed:" + service.name)
        
        if let index = services.index(of: service)
        {
            services.remove(at: index)
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser){
        print("结束搜索")
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]){
        print("没有搜索到: error", errorDict)
    }
    
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool){
        print("搜索到 Domain：" + domainString + "-- morecoming:" ,moreComing)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool){
        print("删除 Domain：" + domainString + "-- morecoming:" ,moreComing)
    }
    
    
}
