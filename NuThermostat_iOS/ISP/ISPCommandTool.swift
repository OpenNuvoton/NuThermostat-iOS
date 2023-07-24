//
//  ISPCommandTool.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/7/6.
//

import Foundation

class ISPCommandTool {
    
    static func toCMD(CMD: ISPCommands, packetNumber: UInt32) -> Data {
        var cmdValue = CMD.rawValue.littleEndian
        var packetNumberValue = packetNumber.littleEndian
        
        let cmdData = Data(bytes: &cmdValue, count: MemoryLayout.size(ofValue: cmdValue))
        let packetNumberData = Data(bytes: &packetNumberValue, count: MemoryLayout.size(ofValue: packetNumberValue))
        let noneBytes = Data(repeating: 0x00, count: 56)
        
        var sendBytes = Data()
        sendBytes.append(cmdData)
        sendBytes.append(packetNumberData)
        sendBytes.append(noneBytes)
        
        return sendBytes
    }
    
    static func toUpdataBin_CMD(cmd: ISPCommands, packetNumber: UInt32, startAddress: UInt32, size: Int, data: [UInt8], isFirst: Bool) -> [UInt8] {
        
        
        if isFirst {
            var cmdValue = cmd.rawValue.littleEndian
            var packetNumberValue = packetNumber.littleEndian
            var addressValue = startAddress.littleEndian
            var totalSizeValue = UInt32(size).littleEndian
            
            // 第一次 CMD
            let cmdData = Data(bytes: &cmdValue, count: MemoryLayout.size(ofValue: cmdValue))
            let packetNumberData = Data(bytes: &packetNumberValue, count: MemoryLayout.size(ofValue: packetNumberValue))
            let address = Data(bytes: &addressValue, count: MemoryLayout.size(ofValue: addressValue))
            let totalSize = Data(bytes: &totalSizeValue, count: MemoryLayout.size(ofValue: totalSizeValue))
            
            var sendBytes = Data()
            sendBytes.append(cmdData)
            sendBytes.append(packetNumberData)
            sendBytes.append(address)
            sendBytes.append(totalSize)
            sendBytes.append(Data(data))
            
            return sendBytes.toUint8Array
        }
        
        // 剩下的 CMD
        
        var cmdValue = UInt32(0x00000000).littleEndian
        var packetNumberValue = packetNumber.littleEndian
        
        let cmdData = Data(bytes: &cmdValue, count: MemoryLayout.size(ofValue: cmdValue))
        let packetNumberData = Data(bytes: &packetNumberValue, count: MemoryLayout.size(ofValue: packetNumberValue))
        
        var sendBytes = Data()
        sendBytes.append(cmdData)
        sendBytes.append(packetNumberData)
        sendBytes.append(Data(data))
        
        return sendBytes.toUint8Array
    }
    
    
    static func toChecksumBySendBuffer(sendBuffer: Data) -> UInt32 {
        var bytes = [UInt8](sendBuffer)
        bytes[1] = 0x00 // 將不同interface所偷改的修正回來
        var uint: UInt32 = 0
        
        for byte in bytes {
            uint += UInt32(byte)
        }
        
        return UInt32(uint)
    }
    
    static func toChecksumByReadBuffer(readBuffer: Data) -> UInt32 {
        
        let bytes: [UInt8] = [readBuffer[0], readBuffer[1], readBuffer[2], readBuffer[3]]
        
        var result: UInt32 = 0
        var shift = 0
        for byte in bytes {
            result |= UInt32(byte) << shift
            shift += 8
        }
        return result
        
    }
    
    static func toPackNo(readBuffer: Data) -> UInt32 {
        let bytes: [UInt8] = [readBuffer[4], readBuffer[5], readBuffer[6], readBuffer[7]]
        
        var result: UInt32 = 0
        var shift = 0
        for byte in bytes {
            result |= UInt32(byte) << shift
            shift += 8
        }
        return result
        
    }
    
    
}
