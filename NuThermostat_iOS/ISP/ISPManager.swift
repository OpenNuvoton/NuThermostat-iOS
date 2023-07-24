//
//  ISP.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/7/1.
//

import Foundation

enum ISPCommands: UInt32 {
    // value 為 Int
    case CMD_REMAIN_PACKET = 0x00000000
    case CMD_UPDATE_APROM = 0x000000A0
    case CMD_UPDATE_CONFIG = 0x000000A1
    case CMD_READ_CONFIG = 0x000000A2
    case CMD_ERASE_ALL = 0x000000A3
    case CMD_SYNC_PACKNO = 0x000000A4
    case CMD_GET_FWVER = 0x000000A6
    case CMD_GET_DEVICEID = 0x000000B1
    case CMD_UPDATE_DATAFLASH = 0x000000C3
    case CMD_RUN_APROM = 0x000000AB
    case CMD_RUN_LDROM = 0x000000AC
    case CMD_RESET = 0x000000AD
    case CMD_CONNECT = 0x000000AE
    case CMD_RESEND_PACKET = 0x000000FF
    // Support SPI Flash
    case CMD_ERASE_SPIFLASH = 0x000000D0
    case CMD_UPDATE_SPIFLASH = 0x000000D1
}

enum DeviceCommands: UInt8 {
    // value 為 UInt
    case CMD_GET_ISP_MODE = 0xC0
    case CMD_SET_ISP_MODE = 0xC1
}


class ISPManager {
    
    private var read_endpoint_index = 0
    private var write_endpoint_index = 1
    private var connect_interface_index = 0
    private var byteSize = 64
    private let forceClaim = true
    private let timeOut = 100
    private let isSearchLoop = false
    private var identifier = ""
    
    public var _packetNumber: UInt32 = 0x00000005
    
    private var _readListener: (([UInt8]) -> Void)?
    private var _byteArrayResultListener: (([UInt8]) -> Void)?
    
    //----------------------------------------
    private var _responseBuffer: Data = Data()
    
    
    func sendCMD_SET_ISP_MODE_ON(callback: @escaping ((Data?, Bool) -> Void)) {
        let cmd: UInt8 = DeviceCommands.CMD_SET_ISP_MODE.rawValue
        let sendBuffer: [UInt8] = [cmd, 0x01, 0x01]
        
        print("write CMD:\(HexTool().hexToString(sendBuffer))")
        
        var timeOutIndex = 0
        var isTimeOut = false
        _responseBuffer = Data()// 清除 BF
        
        TCPManagerPool.shared.send(data:  Data(sendBuffer), toConnectionWithIdentifier: self.identifier, callback: nil)
        
        while _responseBuffer.isEmpty {
            Thread.sleep(forTimeInterval: 0.1)
            
            if timeOutIndex > 15 {
                callback(_responseBuffer, true)
                isTimeOut = true
                return
            }
            timeOutIndex += 1
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        callback(_responseBuffer, isTimeOut)
    }
    
    func sendCMD_CONNECT(callback: @escaping (Data?, _ isChecksum:Bool, _ isTimeOut:Bool) -> Void) {
        _packetNumber = UInt32(0x00000001)
        
        let cmd = ISPCommands.CMD_CONNECT
        let sendBuffer = ISPCommandTool.toCMD(CMD: cmd, packetNumber: _packetNumber)
        
        print("write   CMD:\(HexTool().hexToString(sendBuffer) )")
        var timeOutIndex = 0
        var isTimeOut = false
        _responseBuffer = Data()
        
        TCPManagerPool.shared.send(data: sendBuffer, toConnectionWithIdentifier: self.identifier, callback: nil)
        
        while (_responseBuffer.isEmpty) {
            Thread.sleep(forTimeInterval: 0.3)
            TCPManagerPool.shared.send(data: sendBuffer, toConnectionWithIdentifier: self.identifier, callback: nil)
            
            if (timeOutIndex > 60) {
                callback(_responseBuffer, false, true)
                isTimeOut = true
                return
            }
            timeOutIndex += 1
            print("timeOutIndex :\(timeOutIndex)   isTimeOut:\(isTimeOut)")
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        let isChecksum = isChecksum_PackNo(sendBuffer: sendBuffer.toUint8Array, readBuffer: _responseBuffer.toUint8Array)
        callback(_responseBuffer, isChecksum, isTimeOut)
    }
    
    
    func sendCMD_UPDATE_BIN(sendByteArray: [UInt8], startAddress: UInt32, callback: @escaping (([UInt8]?, Int) -> Void)) {
        
        let cmd = ISPCommands.CMD_UPDATE_APROM
        
        var firstData = [UInt8]() // 第一個 cmd 為 48 byte
        
        for i in 0..<48 {
            firstData.append(sendByteArray[i])
        }
        
        //        var remainDataList: [[data]] = [Data]()
        var remainDataList: [Array<UInt8>] = []
        let remainData = sendByteArray[48...] //取出４８後面元素
        var index = 0
        var dataArray = [UInt8]()
        
        for byte in remainData {
            dataArray.append(byte)
            index += 1
            
            if index == 56 {
                index = 0
                remainDataList.append(dataArray)
                dataArray.removeAll()
            }
            
        }
        if !dataArray.isEmpty {
            // 還有剩餘的數據
            for _ in dataArray.count+1...56 {
                dataArray.append(0x00)
            }
            
            if dataArray.count == 56 {
                remainDataList.append(dataArray)
            }
        }
        
        print("CMD_UPDATE   CMD:\(cmd)  startAddress:\(startAddress)  size:\(sendByteArray.count)  allPackNum:\(remainDataList.count+1)")
        
        let sendBuffer = ISPCommandTool.toUpdataBin_CMD(cmd: cmd, packetNumber: _packetNumber, startAddress: startAddress, size: sendByteArray.count, data: firstData, isFirst: true)
        
        let readBuffer = self.write(sendBuffer: Data(sendBuffer)).toUint8Array
        let isChecksum = isChecksum_PackNo(sendBuffer: sendBuffer, readBuffer: readBuffer)
        
        callback(readBuffer, 0) // 0% 起跳
        
        if !isChecksum {
            callback(readBuffer, -1)
            return
        }
        
        for i in 0..<remainDataList.count {
            let sendBuffer = ISPCommandTool.toUpdataBin_CMD(cmd: cmd, packetNumber: _packetNumber, startAddress: startAddress, size: sendByteArray.count, data: remainDataList[i], isFirst: false)
            let readBuffer = self.write(sendBuffer: Data(sendBuffer)).toUint8Array
            let isChecksum = isChecksum_PackNo(sendBuffer: sendBuffer, readBuffer: readBuffer)
            
            if !isChecksum {
                callback(readBuffer, -1)
                return
            }
            
            callback(readBuffer, Int(Double(i) / Double(remainDataList.count) * 100))
        }
        
        callback(readBuffer, 100)
        
        
    }
    
    func sendCMD_RUN_APROM(callback: @escaping (Bool) -> Void) {
        let cmd = ISPCommands.CMD_RUN_APROM
        let sendBuffer = ISPCommandTool.toCMD(CMD: cmd, packetNumber: _packetNumber)
        DispatchQueue.global().async {
            TCPManagerPool.shared.send(data:  Data(sendBuffer), toConnectionWithIdentifier: self.identifier, callback: nil)
        }
        
        callback(true)
    }

    
    func isChecksum_PackNo(sendBuffer: [UInt8], readBuffer: [UInt8]?) -> Bool {
        if readBuffer == nil {
            print("isChecksum_PackNo: readBuffer == nil")
            return false
        }
        
        // checksum
        let checksum = ISPCommandTool.toChecksumBySendBuffer(sendBuffer: Data(sendBuffer))
        let resultChecksum = ISPCommandTool.toChecksumByReadBuffer(readBuffer: Data(readBuffer!))
        
        if checksum != resultChecksum {
            print("isChecksum_PackNo: checksum \(checksum) != resultChecksum \(resultChecksum)")
            return false
        }
        
        // checkPackNo
        let packNo = _packetNumber + 0x00000001
        let resultPackNo = ISPCommandTool.toPackNo(readBuffer: Data(readBuffer!))
        
        if packNo != resultPackNo {
            print("isChecksum_PackNo: packNo \(packNo) != resultPackNo \(resultPackNo)")
            return false
        }
        _packetNumber = packNo + 0x00000001
        print("isChecksum_PackNo: packNo \(packNo) == resultPackNo \(resultPackNo), checksum \(checksum) == resultChecksum \(resultChecksum)")
        return true
    }
    
    func initTcp(identifier:String){
        TCPManagerPool.shared.delegate = self
        self.identifier = identifier
    }
    
    private func write(sendBuffer: Data) -> Data {
        self._responseBuffer = Data()//清除bf
        DispatchQueue.global().async {
            TCPManagerPool.shared.send(data: sendBuffer, toConnectionWithIdentifier: self.identifier, callback: nil)
        }
        print("write   CMD: \(sendBuffer.toHexString())")
        while self._responseBuffer.count < 64 {
            Thread.sleep(forTimeInterval: 0.01)
        }
        return self._responseBuffer
        
    }
    
    
    
}
extension ISPManager: TCPManagerPoolDelegate {
    func tcpManagerPoolDidDisconnect(identifier: String) {
        // 連線中斷
    }
    
    func tcpManagerPoolDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String) {
        // 处理接收到的数据
        if identifier != SettingViewController.Controller_Identifier_SSID {
            return
        }
        
        print("response from \(identifier): \(data.toHexString())")
        
        _responseBuffer = data
    }
    
}

