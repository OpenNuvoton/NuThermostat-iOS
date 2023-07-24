//
//  ViewController.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC WP on 2023/5/4.
//

import UIKit
import NetworkExtension
import Network
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ver_text: UILabel!
    
    var deviceList = [DeviceData]()
    var tempMap: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // 创建 TCPManagerPool 实例
        TCPManagerPool.shared.delegate = self
        // AlertTool().showLoading(from: self)
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            print("App Version: \(appVersion)")
            ver_text.text = "ver \(appVersion)"
        } else {
            print("Unable to retrieve app version.")
        }
        
        //NWBrowser
        let discoveryDelegate = ServiceNWBrowserDelegate()
        discoveryDelegate.setListener { ipv4 in
            
            // 使用 guard 和 let 来提取 IP 地址
            guard let ipAddress = ipv4.components(separatedBy: "%").first else {
                print("无效的 IP 地址")
                // 如果无法提取 IP 地址，可以在此处处理错误情况或返回
                return
            }
            
            //查找裝置內有無符合，有則不動
            var isHaveSameIP = false
            let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
            if let unwrappedDeviceDatas = loadedDeviceDatas {
                for deviceData in unwrappedDeviceDatas {
                    if(deviceData.ip == ipAddress){
                        isHaveSameIP = true
                        break
                    }
                }
            }
            
            if(isHaveSameIP ==  true){
                return
            }
            
            self.tempMap[ipAddress] = ipAddress
            
            TCPManagerPool.shared.addTCPManager(host: ipAddress, port: 520, identifier: ipAddress) { isSuccess, identifier in
                print("\(identifier)  Connect:\(isSuccess)")
                if(isSuccess){
                    TCPManagerPool.shared.send(data: Data(CMDManager().toGetUUID_BF()), toConnectionWithIdentifier: ipAddress) { isSuccess in
                        
                    }
                }
            }
        }
        
        discoveryDelegate.discoverServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 视图将要显示时的处理逻辑
        handlePageWillAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageWillAppear), name: NSNotification.Name("ViewControllerWillAppear"), object: nil)
        
    }
    
    @objc private func handlePageWillAppear() {
        // 在这里执行每次进入页面时需要调用的操作
        DeviceDataManager.shared.setAllIsConnectToDefault()
        let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
        if let unwrappedDeviceDatas = loadedDeviceDatas {
            for var deviceData in unwrappedDeviceDatas {
                // 在这里使用非可选的 deviceData
                print("Device: \(deviceData.ssid), ip: \(deviceData.ip)")
                
                // 添加 TCP 连接并连接到服务器
                TCPManagerPool.shared.addTCPManager(host: deviceData.ip, port: 520, identifier: deviceData.ssid) { isSuccess, identifier in
                    print("\(identifier)  Connect:\(isSuccess)")
                    deviceData.isConnect = isSuccess ? 1:0
                    DeviceDataManager.shared.updateDevice(device: deviceData)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()//更新
                    }
                }
                
            }
        } else {
            // 处理 loadedDeviceDatas 为 nil 的情况
            print("loadDeviceList nil")
        }
        
        
    }
    
    @IBAction func test(_ sender: UIButton) {
        print("sendtest")
        let bytes: [UInt8] = [0x41, 0x42, 0x43] // 示例字节数据
        let data = Data(bytes)
        TCPManagerPool.shared.send(data: data, toConnectionWithIdentifier: "第一台") { isSuccess in
            print("send:\(data) ,\(isSuccess)")
        }
        
    }
    
    
}

extension ViewController: TCPManagerPoolDelegate {
    func tcpManagerPoolDidDisconnect(identifier: String) {
        // 連線中斷
    }
    
    func tcpManagerPoolDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String) {
        // 处理接收到的数据
        
        
        
        if(tempMap[identifier] != nil){
            let display = CMDManager().toUUID_Ascii(hexData: data)
            
            
            let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
            if let unwrappedDeviceDatas = loadedDeviceDatas {
                for var deviceData in unwrappedDeviceDatas {
                    if(deviceData.ssid == display){
                        deviceData.ip = tempMap[identifier]!
                        DeviceDataManager.shared.updateDevice(device: deviceData)
                        handlePageWillAppear()
                        break
                    }
                }
            }
            
        }
        
    }
}

extension ViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 返回表格行数
        let list = DeviceDataManager.shared.loadDeviceList()
        var count = 0
        if(list != nil){
            count = list!.count
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceItemTableViewCell
        
        
        let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
        
        if(loadedDeviceDatas == nil){
            return cell
        }
        let dd = loadedDeviceDatas![indexPath.row]
        cell.deviceText.text = dd.ssid
        
        switch(dd.isConnect){
        case 0:
            cell.loadingView.isHidden = true
            cell.iconImage.isHidden = false
            cell.iconImage.image = UIImage(named: "icon_wifi_onnection_failed")
            cell.NextButton.isEnabled = false
            cell.ISPButton.isHidden =  true
            break
        case 1:
            cell.loadingView.isHidden = true
            cell.iconImage.isHidden = false
            cell.iconImage.image = UIImage(named: "icon_wifi_connected")
            cell.NextButton.isEnabled = true
            cell.ISPButton.isHidden =  false
            break
        default:
            cell.loadingView.isHidden = false
            cell.iconImage.isHidden = true
            cell.NextButton.isEnabled = false
            cell.ISPButton.isHidden =  true
            
        }
        
        // 为单元格按钮添加点击事件处理
        cell.NextButton.addTarget(self, action: #selector(handleNextButtonTap(_:)), for: .touchUpInside)
        cell.NextButton.tag = indexPath.row
        
        // 为单元格按钮添加点击事件处理
        cell.deleteButton.addTarget(self, action: #selector(handleDeleteButtonTap(_:)), for: .touchUpInside)
        cell.deleteButton.tag = indexPath.row
        
        // 为单元格按钮添加点击事件处理
        cell.ISPButton.addTarget(self, action: #selector(handleISPButtonTap(_:)), for: .touchUpInside)
        cell.ISPButton.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @objc func handleISPButtonTap(_ sender: UIButton) {
        let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
        let rowIndex = sender.tag
        print("ISPButton   \(rowIndex)")
        SettingViewController.Controller_Identifier_SSID = loadedDeviceDatas![rowIndex].ssid
        //        if(loadedDeviceDatas![rowIndex].isConnect != 1){
        //            AlertTool().showInfo(from: self, message: "The device is not connected.", hasOk: true, hasNo: false) { isOk in
        //            }
        //            return
        //        }
        //
        //        AlertTool().showInfo(from: self, message: "Are you sure you want to delete this device?", hasOk: true, hasNo: true) { isOk in
        //            if(isOk){
        //                SettingViewController.Controller_Identifier_SSID = loadedDeviceDatas![rowIndex].ssid
        //            }
        //        }
    }
    @objc func handleNextButtonTap(_ sender: UIButton) {
        
        let rowIndex = sender.tag
        // 根据 rowIndex 获取相关数据或执行相应的操作
        print("NextButton   \(rowIndex)")
        let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
        SettingViewController.Controller_Identifier_SSID = loadedDeviceDatas![rowIndex].ssid
    }
    @objc func handleDeleteButtonTap(_ sender: UIButton) {
        let rowIndex = sender.tag
        // 根据 rowIndex 获取相关数据或执行相应的操作
        
        AlertTool().showInfo(from: self, message: "Are you sure you want to delete this device?", hasOk: true, hasNo: true) { isOk in
            if(isOk == true){
                let loadedDeviceDatas = DeviceDataManager.shared.loadDeviceList()
                DeviceDataManager.shared.deleteDevice(with: loadedDeviceDatas![rowIndex].ssid)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()//更新
                }
            }
        }
    }
}


