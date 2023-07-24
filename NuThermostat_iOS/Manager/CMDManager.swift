////
////  CMDManager.swift
////  NuThermostat_iOS
////
////  Created by MS70MAC WP on 2023/5/22.
////

import Foundation

enum Commands: UInt {
    // value 為 UInt
    case CMD_SET_SSID = 0xb0
    case CMD_SET_PASSWORD = 0xb1
    case CMD_GET_UUID = 0xb3

    case CMD_GET_INFO = 0xa0
    case CMD_SET_POWER = 0xa1
    case CMD_SET_HOT = 0xa2
    case CMD_SET_TEMPERATURE = 0xa3
    case CMD_SET_DEFOG = 0xa4
    case CMD_SET_LOCK = 0xa5
    case CMD_SET_DATE_TIME = 0xa6
}

class CMDManager {
    public func toSetSSID_BF(ssid:String) -> [UInt8]{
        let ssidBytes = ssid.data(using: .utf8)
        let CMD = Data([0xb0]) + Data([UInt8(ssidBytes!.count)]) + ssidBytes!
        var cmdBytes = [UInt8](CMD)
        // 计算 SUM(Byte0:Byte[Length+1])
        var sum: UInt8 = 0
        for byte in cmdBytes {
            sum = sum &+ byte
        }
        cmdBytes.append(sum)
        return cmdBytes
    }
    public func toSetPWD_BF(pwd:String) -> [UInt8]{
        let pwdBytes = pwd.data(using: .utf8)
        let CMD = Data([0xb1]) + Data([UInt8(pwdBytes!.count)]) + pwdBytes!
        var cmdBytes = [UInt8](CMD)
        // 计算 SUM(Byte0:Byte[Length+1])
        var sum: UInt8 = 0
        for byte in cmdBytes {
            sum = sum &+ byte
        }
        cmdBytes.append(sum)
        return cmdBytes
    }
    
    public func toGetInfo_BF() -> [UInt8]{
        let CMD = Data([0xa0])
        let cmdBytes = [UInt8](CMD)
        return cmdBytes
    }
    
    func toSetPower_BF(setON: Bool)-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_SET_POWER.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd, 0x01])
        
        if setON {
            sendBuffer.append(0x01)
        } else {
            sendBuffer.append(0x00)
        }
        return sendBuffer
    }

    func toSetHot_BF(setHot: Bool)-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_SET_HOT.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd, 0x01])
        
        if setHot {
            sendBuffer.append(0x01)
        } else {
            sendBuffer.append(0x00)
        }
        return sendBuffer
    }
    
    func toSetAntifrost_BF(setHot: Bool)-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_SET_DEFOG.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd, 0x01])
        
        if setHot {
            sendBuffer.append(0x01)
        } else {
            sendBuffer.append(0x00)
        }
        return sendBuffer
    }
    
    func toSetLock_BF(setHot: Bool)-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_SET_LOCK.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd, 0x01])
        
        if setHot {
            sendBuffer.append(0x01)
        } else {
            sendBuffer.append(0x00)
        }
        return sendBuffer
    }
    
    func toSetTemperature_BF(temperature:Int)-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_SET_TEMPERATURE.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd, 0x01])
        sendBuffer.append(UInt8(temperature))
        
        return sendBuffer
    }
    
    func toGetUUID_BF()-> [UInt8] {
        
        let cmd: UInt8 = UInt8(Commands.CMD_GET_UUID.rawValue)
        var sendBuffer = [UInt8]()
        sendBuffer.append(contentsOf: [cmd])
        
        return sendBuffer
    }
    
    func toUUID_Ascii(hexData: Data) -> String? {
        // Remove the first byte from the data
        var remainingHexData = hexData
        remainingHexData.removeFirst()
        remainingHexData.removeLast()
        
        var asciiString = ""
        
        for byte in remainingHexData {
            // Convert each byte to a Character and append to the ASCII string
            asciiString.append(Character(UnicodeScalar(byte)))
        }
        
        return asciiString
    }
    
}
//
//class CMDManager {
//    private var responseBuffer: [UInt8] = []
//    private var tempBuffer: [UInt8] = []
//    private var thesameIndex = 0
//    public var isOnlineListener: ((Bool) -> Void)? = nil
//    private var isStationModeSuccess: ((Bool, String) -> Void)? = nil
//    private var notifyDeviceInfoListener: ((Bool, Bool, Int, Float, Bool, Bool) -> Void)? = nil
//    private var mainTCPClient: Socket? = nil
//
//    public var logcatListener: ((String) -> Void)? = nil
//    func setLogcatListener(callbacks: @escaping (String) -> Void) {
//        logcatListener = callbacks
//    }
//
//    public func initMainTCPClient(tcpClient: Socket) {
//        mainTCPClient = tcpClient
//        DispatchQueue.global().async {
//            SocketManager.funTCPClientReceive(tcpClient, self.readListener)
//        }
//    }
//
//    public func setStationModeSuccessListener(callback: @escaping (Bool, String) -> Void) {
//        isStationModeSuccess = callback
//    }
//
//    public func setNotifyDeviceInfoListener(callback: @escaping (Bool, Bool, Int, Float, Bool, Bool) -> Void) {
//        notifyDeviceInfoListener = callback
//    }
//
//    public var readListener: ((Socket, [UInt8]?) -> Void) = { tcpClient, readBf in
//        let it = readBf
//
//        if let data = it {
//            if data.count < 64 {
//                print("read Value.size < 64  !!!")
//                responseBuffer += data
//            }
//            responseBuffer = data
//        }
//
//        if tempBuffer.elementsEqual(it!) {
//            thesameIndex += 1
//        } else {
//            thesameIndex = 0
//        }
//
//        tempBuffer = it!.map { $0 }
//
//        if thesameIndex > 5 {
//            // 斷線了
//            // SocketManager.funTCPClientClose(tcpClient)
//            // if isOnlineListener != nil {
//            //     isOnlineListener!(false)
//            // }
//        }
//
//        // todo 0xb2 Notify device station mode is success?
//        if let successCallback = isStationModeSuccess, it![0] == 0xb2 {
//            if it![1] == 0x01 {
//                let ipArray: [UInt8] = [it![2], it![4], it![6], it![8]]
//                let ip = HEXTool.hexToIp(HEXTool.toHexString(ipArray))
//                print("isStationModeSuccess 成功:", "ip:" + ip)
//                successCallback(true, ip)
//            }
//            // ...
//        }
//
//        // ...
//    }
//
//    // ...
//}
//
