//
//  ISPViewController.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/29.
//

import UIKit
import UniformTypeIdentifiers

class ISPViewController: UIViewController, UIDocumentPickerDelegate {
    
    var _chipData : ChipData? = nil
    let _ispManager = ISPManager()
    var _apromSize = 0
    var _fileName = ""
    var _brunBin = Data()
    
    @IBOutlet weak var _fileTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _fileTextField.isEnabled = false
        _fileTextField.isUserInteractionEnabled = false
        
        FileManager.loadChipInfoFile()
        FileManager.loadChipPdidFile()
        
        _chipData = FileManager.getChipInfoByPDID(deviceID: "00F25841")
        _ispManager.initTcp(identifier: SettingViewController.Controller_Identifier_SSID)
        _apromSize = Int(FileManager.CHIP_DATA.chipInfo!.AP_size.split(separator: "*")[0]) ?? 0

        
        AlertTool().showLoading(from: self)
        
        DispatchQueue.global().async {
            
            self._ispManager.sendCMD_SET_ISP_MODE_ON { responData, isTimeOut in
                if(isTimeOut == true || responData == nil){
                    AlertTool().showInfo(from: self, message: "device is timeout.", hasOk: true, hasNo: false) { isOk in
                        self.navigationController?.popViewController(animated: true)
                    }
                    return
                }
                AlertTool().dismissShow()
            }
        }
    }
    
    
    @IBAction func SelectButton(_ sender: UIButton) {
        
        var documentPicker: UIDocumentPickerViewController!

        let supportedTypes: [UTType] = [UTType.item]
        documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
        
    }
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // 在這裡處理選擇的文件，可以使用 urls 參數來獲取所選文件的URL
        for url in urls {
            // 访问安全范围内的资源
            //            guard url.startAccessingSecurityScopedResource() else {
            //                // 处理访问失败的情况
            //                return
            //            }
                  
            do {
                let data = try Data(contentsOf: url)
                // 在这里可以使用选中文件的数据（data）
                print("选中的文件URL: \(data.toHexString())")
                _brunBin = data
                
                _fileName = url.lastPathComponent
                print("Bin name: \(_fileName)")
                _fileTextField.text = _fileName
                
            } catch {
                print(error.localizedDescription)
            }
            
            //            // 完成后释放资源的访问权限
            //            url.stopAccessingSecurityScopedResource()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 用户取消选择文件时的处理逻辑
        print("用户取消了文件选择")
    }
    
    @IBAction func BurnButton(_ sender: UIButton) {
        
        
        if(_brunBin.isEmpty || _brunBin.count <= 48 || _brunBin.count > _apromSize || _fileName.lowercased().hasSuffix(".bin")){
            AlertTool().showInfo(from: self, message: "APROM Bin is an error occurred.", hasOk: true, hasNo: false, callback: nil)
            return
        }
        
        DispatchQueue.main.async {
            AlertTool().showProgressAlert(from: self, title: "bruning")
        }
        
        DispatchQueue.global().async {
            self._ispManager.sendCMD_CONNECT { respBF, isChecksum, isTimeOut in
                if(isTimeOut == true){
                    DispatchQueue.main.async {
                        AlertTool().showInfo(from: self, message: "Device is timeOut.", hasOk: true, hasNo: false, callback: nil)
                    }
                    return
                }
                if(isChecksum != true){
                    DispatchQueue.main.async {
                        AlertTool().showInfo(from: self, message: "Device Checksum error.", hasOk: true, hasNo: false, callback: nil)
                    }
                    return
                }
                // 燒入開始
                self.brunAPROM()
            }
        }
        
    }
    
    
    func brunAPROM(){
        
        _ispManager.sendCMD_UPDATE_BIN(sendByteArray: _brunBin.toUint8Array, startAddress: 0x00000000) { respBf, progress in
            DispatchQueue.main.async {
                if(progress == -1){
                    AlertTool().dismissShow()
                    AlertTool().showInfo(from: self, message: "The file burning process failed. /nPlease try again.", hasOk: true, hasNo: false) { isOk in
                        
                    }
                }
                
                AlertTool().updateProgressValue(progress: Float(progress))
                
                if(progress >= 100){
                    AlertTool().dismissShow()
                    AlertTool().showInfo(from: self, message: "The hardware version has been successfully burned. It is now running and resetting. Please wait.", hasOk: true, hasNo: false) { isOk in
                        
                        self._ispManager.sendCMD_RUN_APROM { isTrue in
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                    }
                }
            }
        }
        
    }
}
