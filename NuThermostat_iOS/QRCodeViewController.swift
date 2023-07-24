//
//  QRCodeViewController.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC WP on 2023/5/15.
//

import Foundation
import AVFoundation
import UIKit
import NetworkExtension


class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var CameraUIView: UIView!
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    var _tempSSID:String = ""
    var _tempPWD:String = ""
    var _tempSetWifi:Bool = false
    var _tempDeviceSSID:String = ""
    // 初始化捕获设备（AVCaptureDevice）和输入（AVCaptureDeviceInput）
    var captureDevice: AVCaptureDevice?
    var input: AVCaptureDeviceInput?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                // 用户已授权使用相机，执行相应的操作
                // 初始化捕獲設備（AVCaptureDevice）和輸入（AVCaptureDeviceInput）
                self.captureDevice = AVCaptureDevice.default(for: .video)
                self.input = try! AVCaptureDeviceInput(device: self.captureDevice!)
                self.initCameraQR()
                // 进行后续操作
            } else {
                // 用户拒绝了相机访问权限，显示相应的提示或处理逻辑
                AlertTool.shared.showInfo(from: self, message: "Camera permissions not granted. Please ensure permissions are granted before proceeding.", hasOk: true, hasNo: false) { _ in
                    //重新掃描
                    self.dismiss(animated: true)
                    self.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: NSNotification.Name("AViewControllerWillAppear"), object: nil)
                }
                return
            }
        }
        

    }
    
    func initCameraQR(){
        DispatchQueue.main.async() {
            //        // 初始化捕獲設備（AVCaptureDevice）和輸入（AVCaptureDeviceInput）
            //        let captureDevice = AVCaptureDevice.default(for: .video)
            //        let input = try! AVCaptureDeviceInput(device: captureDevice!)
            
            // 初始化會話 (AVCaptureSession)，設置輸入和輸出
            self.captureSession = AVCaptureSession()
            self.captureSession.addInput(self.input!)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            self.captureSession.addOutput(captureMetadataOutput)
            
            // 設置代理和元資料類型
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            // 初始化預覽層 (AVCaptureVideoPreviewLayer)，設置預覽層大小和捕獲會話連接
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer.frame = self.CameraUIView.bounds // 預覽層尺寸
            
            // 创建圆角遮罩层
            let maskLayer = CALayer()
            maskLayer.frame = self.previewLayer.bounds
            maskLayer.cornerRadius = 10
            maskLayer.masksToBounds = true
            
            // 创建容器层，并将遮罩层添加到容器层中
            let containerLayer = CALayer()
            containerLayer.frame = self.previewLayer.bounds
            containerLayer.addSublayer(maskLayer)
            
            // 将容器层作为子层添加到预览层的父视图的层级结构中
            self.previewLayer.superlayer?.addSublayer(containerLayer)
            
            self.CameraUIView.layer.addSublayer(self.previewLayer) // 將預覽層放入CameraUIView
            self.CameraUIView.layer.borderColor = UIColor.black.cgColor
            self.CameraUIView?.layer.borderWidth = 2
            self.CameraUIView.layer.cornerRadius = 10
            self.CameraUIView.layer.masksToBounds = true
            
            // 初始化二維碼邊框視圖
            self.qrCodeFrameView = UIView()
            self.qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            self.qrCodeFrameView?.layer.borderWidth = 2
            self.CameraUIView.addSubview(self.qrCodeFrameView!)// 將邊框視圖放入CameraUIView
            self.CameraUIView.bringSubviewToFront(self.qrCodeFrameView!)
            
            // 開始捕獲
            DispatchQueue.global().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func reStarQR(){
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
        // 移除上次加载的二维码边框视图
        qrCodeFrameView?.removeFromSuperview()
        qrCodeFrameView = nil

    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // 取出第一個元資料（即掃描結果）
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // 如果掃描到 QR 碼，將掃描結果顯示在控制台中
            print(metadataObj.stringValue!)
            
            // 將二維碼邊框繪製在預覽層中
            let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            let qrText = metadataObj.stringValue!
            
            captureSession.stopRunning()
            
            //判斷是否為新唐QRCode
            if(qrText.contains("Nuvoton")){
                
                DispatchQueue.main.async() {
                    
                    AlertTool.shared.showLoading(from: self)//loading視窗
                    
                    let components = qrText.components(separatedBy: ",")
                    if(components.count>1){
                        let ssid = components[1]
                        self.doConnectM258WiFi(ssid: ssid)
                    }else{
                        AlertTool.shared.showInfo(from: self, message: "Incorrect QR code.", hasOk: true, hasNo: false) { _ in
                            //重新掃描
                            self.reStarQR()
                        }
                     
                    }
                }
            }else{
                
                AlertTool.shared.showInfo(from: self, message: "Not Nuvoton's QR code.", hasOk: true, hasNo: false, callback: { _ in
                    //重新掃描
                    self.reStarQR()
                })
            }
        }
    }
    
    func doConnectM258WiFi(ssid:String){
        
        let wiFiConfig = NEHotspotConfiguration(ssid: ssid)
        NEHotspotConfigurationManager.shared.apply(wiFiConfig) { error in
            if let error = error {
                print(error.localizedDescription)
                if(error.localizedDescription.contains("already") == true){
                    self._tempDeviceSSID = ssid
                    self.doConnectAndBinding()
                    return
                }
                DispatchQueue.main.async() {
                    AlertTool.shared.dismissShow()
                    self.reStarQR()
                }
            }
            else {
                self._tempDeviceSSID = ssid
                self.doConnectAndBinding()
            }
        }
        
    }
    
    func doConnectHomeWifi(){
        
        AlertTool.shared.dismissShow()
        AlertTool.shared.showLoading(from: self)
        
        let wiFiConfig = NEHotspotConfiguration(ssid: _tempSSID, passphrase: _tempPWD, isWEP: false)
        NEHotspotConfigurationManager.shared.apply(wiFiConfig) { error in
            if let error = error {
                print(error.localizedDescription)
                if(error.localizedDescription.contains("already") == true){
                 //已連回Home wifi
                    self.dismiss(animated: true)
                    self.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: NSNotification.Name("AViewControllerWillAppear"), object: nil)
                    return
                }
                DispatchQueue.main.async() {
                //失敗 要跳訊息
                    AlertTool.shared.showInfo(from: self, message: "Failed to reconnect to Home WiFi. Please manually connect to the Home WiFi.", hasOk: true, hasNo: false) { _ in
                        // 返回上一页面
                        self.dismiss(animated: true)
                        self.navigationController?.popViewController(animated: true)
                        NotificationCenter.default.post(name: NSNotification.Name("AViewControllerWillAppear"), object: nil)
                    }
                }
            }
            else {
                //成功連回Home wifi
                self.dismiss(animated: true)
                self.navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name("AViewControllerWillAppear"), object: nil)
                return
            }
        }
        
    }
    
    func doConnectAndBinding(){
        
        
        // 创建 TCPManagerPool 实例
        TCPManagerPool.shared.delegate = self
        
        // 添加 TCP 连接并连接到服务器
        TCPManagerPool.shared.addTCPManager(host: "192.168.4.1", port: 520, identifier: "QR") { isSuccess, identifier in
            print("QR TCP \(identifier)  Connect:\(isSuccess)")
            if(isSuccess){
                //TODO 下ＣＭＤ
                DispatchQueue.main.async() {
                    AlertTool.shared.showWiFi_input(from: self) { ssid, pwd in
                        if(ssid == "" || pwd == ""){
                            DispatchQueue.main.async() {
                                AlertTool.shared.showInfo(from: self, message: "Input error. Please check the entered home Wi-Fi data.", hasOk: true, hasNo: false) { _ in
                                    self.reStarQR()
                                }
                            }
                            return
                        }
                        
                        let getUUID_CMD = CMDManager().toGetUUID_BF()
                        TCPManagerPool.shared.send(data: Data(getUUID_CMD), toConnectionWithIdentifier: "QR") { isSuccess in
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self._tempSSID = ssid
                                self._tempPWD = pwd
                                self._tempSetWifi = false
                                AlertTool.shared.showLoading(from: self)
                                let setSSID_CMD = CMDManager().toSetSSID_BF(ssid: self._tempSSID)
                                TCPManagerPool.shared.send(data: Data(setSSID_CMD), toConnectionWithIdentifier: "QR", callback: nil)
                            }
                        }
                        
                        
                        // 开始超时计时
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            if (self._tempSetWifi != true) {
                                // 配置超时，中止操作
                                AlertTool.shared.showInfo(from: self, message: "TimeOut to set device Wi-Fi. Please try again.", hasOk: true, hasNo: false) { _ in
                                    self.reStarQR()
                                }
                            }
                        }
                        
                    }
                }
            }else{
                DispatchQueue.main.async() {
                    AlertTool.shared.showInfo(from: self, message: "Unable to connect to the device. Please check the device status before attempting again.", hasOk: true, hasNo: false) { _ in
                        self.reStarQR()
                    }
                }
                
            }
            
            //            AlertTool.shared.showInfo(message: "error", from: self)
            //            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            //                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            //            }
            
        }
        
        //執行配對流程
        //
        
    }
}


extension QRCodeViewController:TCPManagerPoolDelegate{
    func tcpManagerPoolDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String) {
        
        if(identifier != "QR"){
            return
        }
        
        let byteStrings = data.map { String(format: "%02x", $0) }
        print("QR read identifier:\(identifier),Data:\(byteStrings)")
        
        if let firstByte = data.first {
            switch firstByte {
            case 0xb0:
                // 匹配 0xb0 的逻辑 (ssid ack)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let setPWD_CMD = CMDManager().toSetPWD_BF(pwd: self._tempPWD)
                    TCPManagerPool.shared.send(data: Data(setPWD_CMD), toConnectionWithIdentifier: "QR", callback: nil)
                }
                break
            case 0xb1:
                // 匹配 0xb1 的逻辑 (pwd ack)
                break
            case 0xb2:
                // 匹配 0xb2 的逻辑 (Notify wifi connect id)
                if(data[1] != 0x01){
                    //失敗
                    AlertTool.shared.showInfo(from: self, message: "Failed to set device Wi-Fi. Please try again.", hasOk: true, hasNo: false) { isOk in
                        self.reStarQR()
                    }
                    return
                }
                
                let ipArray: [UInt8] = [data[2], data[4], data[6], data[8]]
                let ip = HexTool().hexToIp(HexTool().hexToString(ipArray))
                print("0xb2 isStationModeSuccess true:", "ip:" + ip)
                
                self._tempSetWifi = true
                //儲存資料
                
                let newDevice = DeviceData(ssid: self._tempDeviceSSID, ip: ip, isConnect: 2)
                DeviceDataManager.shared.addDevice(newDevice)
                
                self.doConnectHomeWifi()
                
                break
            case 0xb3:
                
                break
            default:
                // 默认情况的逻辑
                break
            }
        } else {
            // 数据为空的处理逻辑
        }
    }
    
    func tcpManagerPoolDidDisconnect(identifier: String) {
        
    }
    
    
    
}
