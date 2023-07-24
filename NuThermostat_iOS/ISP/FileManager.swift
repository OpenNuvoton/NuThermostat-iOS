//
//  FileManager.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/7/1.
//

import Foundation

class FileData {
    var uri: URL?
    var name: String?
    var path: String?
    var type: String?
    var fileURL: URL?
    var byteArray: [UInt8]?
}

class ChipData {
    var chipInfo: ChipInfoData?
    var chipPdid: ChipPdidData?
}

struct ChipInfoData: Codable {
    var AP_size: String
    var DF_size: String
    let RAM_size: String
    let DF_address: String
    let LD_size: String
    let PDID: String
    let name: String
    let note: String?
}

struct ChipPdidData: Codable {
    let name: String
    let PID: String
    let series: String
    let note: String?
    let jsonIndex: String?
}

class FileManager {
    private static var TAG = "FileManager"

    static var APROM_BIN: FileData? = nil
    static var DATAFLASH_BIN: FileData? = nil
    private static var _cid = [ChipInfoData]()
    private static var _cpd = [ChipPdidData]()
    static var CHIP_DATA: ChipData = ChipData()

    static func loadChipInfoFile()  {
        let filename = "chip_info"
        
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("無法找到 \(filename) JSON 文件")
           return
        }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            _cid = try decoder.decode([ChipInfoData].self, from: jsonData)
            print("loadChipInfoFile 完成")
        } catch {
            print("解析 JSON 文件時出錯：\(error)")
        }
    }

    static func loadChipPdidFile()  {
        
        let filename = "chip_pdid"
        
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("無法找到 \(filename) JSON 文件")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            _cpd = try decoder.decode([ChipPdidData].self, from: jsonData)
            print("loadChipPdidFile 完成")
        } catch {
            print("解析 JSON 文件時出錯：\(error)")
        }

    }


    static func getChipInfoByPDID(deviceID: String) -> ChipData? {
        let id = "0x" + deviceID
        var hasInfo = false
        var hasPdid = false

        CHIP_DATA = ChipData()
        for c in _cid {
            if c.PDID == id {
                CHIP_DATA.chipInfo = c
                hasInfo = true
            }
        }
        for c in _cpd {
            if c.PID == id {
                CHIP_DATA.chipPdid = c
                hasPdid = true
            }
        }

        if !hasInfo || !hasPdid {
            return nil
        }
        return CHIP_DATA
    }

//    static func getNameByUri(uri: URL?, context: Context) -> String {
//        guard let uri = uri else {
//            return "null"
//        }
//
//        var result: String = "N/A"
//        var temp: URL?
//
//        if uri.scheme == "content" {
//            let cursor = context.contentResolver.query(uri, nil, nil, nil, nil)
//            if let cursor = cursor {
//                if cursor.moveToFirst() {
//                    var index: Int = cursor.getColumnIndex("_data")
//                    if index == -1 {
//                        index = cursor.getColumnIndex("_display_name")
//                    }
//                    result = cursor.getString(index)
//                    temp = URL(string: result)
//                }
//                cursor.close()
//            }
//        }
//
//        if let temp = temp {
//            result = temp.path
//
//            let cut = result.lastIndex(of: "/")
//            if let cut = cut {
//                result = String(result[cut...].dropFirst())
//            }
//        }
//
//        return result
//    }
}
