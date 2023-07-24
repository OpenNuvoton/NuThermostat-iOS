//
//  HexTool.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/7.
//

import Foundation
import UIKit

class HexTool{
    
    func hexToString(_ data: Data) -> String {
        let byteArray = [UInt8](data)
        return byteArray.map { String(format: "%02X", $0) }.joined()
    }
    
    func hexToString(_ byteArray: [UInt8]) -> String {
        return byteArray.map { String(format: "%02X", $0) }.joined()
    }

    func hexToIp(_ hexString: String) -> String {
        let bytes = stride(from: 0, to: hexString.count, by: 2).map {
            let startIndex = hexString.index(hexString.startIndex, offsetBy: $0)
            let endIndex = hexString.index(startIndex, offsetBy: 2)
            let subString = hexString[startIndex..<endIndex]
            return UInt8(subString, radix: 16)!
        }
        
        let ip = bytes.map { String($0) }.joined(separator: ".")
        return ip
    }
    
    func hexToAscii(hex: Data) -> String? {
        var asciiString = ""
        
        // Check if the data has an even number of bytes
        guard hex.count % 2 == 0 else {
            return nil
        }
        
        // Iterate through the data, taking 2 bytes at a time
        var index = hex.startIndex
        while index < hex.endIndex {
            // Get the next 2 bytes
            let nextIndex = hex.index(index, offsetBy: 2)
            let hexSlice = hex[index..<nextIndex]
            
            // Convert the 2-byte slice to a single UInt8 value
            var hexValue: UInt8 = 0
            hexSlice.forEach { byte in
                hexValue = hexValue << 4 + byte
            }
            
            // Convert the UInt8 value to a Character and append to the ASCII string
            asciiString.append(Character(UnicodeScalar(hexValue)))
            
            index = nextIndex
        }
        
        return asciiString
    }
    
}


extension UInt32 {
    func toByteArray() -> [UInt8] {
        return [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}


extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var toUint8Array: [UInt8] {
            return [UInt8](self)
        }
    
}

extension UIColor {
    convenience init?(hexString: String) {
        var formattedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if formattedString.hasPrefix("#") {
            formattedString.remove(at: formattedString.startIndex)
        }
        
        guard let hexValue = UInt32(formattedString, radix: 16) else {
            return nil
        }
        
        let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hexValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
