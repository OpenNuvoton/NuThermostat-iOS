//
//  DataManager.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/8.
//

import Foundation

//class DataManager {
//    static let shared = DataManager()
//
//    private let userDefaults = UserDefaults.standard
//
//    private let dataDictKey = "DataDict"
//
//    var dataDict: [String: Any] {
//        get {
//            if let savedDataDict = userDefaults.dictionary(forKey: dataDictKey) {
//                return savedDataDict
//            }
//            return [:]
//        }
//        set {
//            userDefaults.set(newValue, forKey: dataDictKey)
//        }
//    }
//
//    private init() {}
//
//    func saveDataDict() {
//        dataDict = dataDict
//        userDefaults.synchronize()
//        print("DataDict saved successfully.")
//    }
//
//    func clearDataDict() {
//        dataDict = [:]
//        userDefaults.synchronize()
//        print("DataDict cleared successfully.")
//    }
//}

//// 使用示例
//DataManager.shared.dataDict["Key1"] = "Value1"
//DataManager.shared.dataDict["Key2"] = 123
//
//DataManager.shared.saveDataDict()
//
//let loadedDataDict = DataManager.shared.dataDict
//
//print(loadedDataDict)

struct DeviceData: Codable {
    let ssid: String
    var ip: String
    var isConnect: Int
}


class DeviceDataManager {
    static let shared = DeviceDataManager() // 单例模式，确保全局唯一的实例
    
    private let deviceListKey = "deviceListKey"
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private init() {}
    
    func saveDeviceList(_ deviceList: [DeviceData]) {
        do {
            let data = try jsonEncoder.encode(deviceList)
            UserDefaults.standard.set(data, forKey: deviceListKey)
            UserDefaults.standard.synchronize()
            print("deviceList 保存成功")
        } catch {
            print("deviceList 保存失败: \(error.localizedDescription)")
        }
    }
    
    func loadDeviceList() -> [DeviceData]? {
        if let data = UserDefaults.standard.object(forKey: deviceListKey) as? Data {
            do {
                var deviceList = try jsonDecoder.decode([DeviceData].self, from: data)
                print("deviceList 加载成功")
                return deviceList
            } catch {
                print("deviceList 加载失败: \(error.localizedDescription)")
            }
        }
        print("未找到存储的 deviceList 数据")
        return nil
    }
    
    func deleteDevice(with ssid: String) {
        var deviceList = loadDeviceList() ?? []
        
        if let index = deviceList.firstIndex(where: { $0.ssid == ssid }) {
            deviceList.remove(at: index)
            saveDeviceList(deviceList)
            print("设备删除成功")
        } else {
            print("未找到要删除的设备")
        }
    }
    
    func addDevice(_ device: DeviceData) {
        var deviceList = loadDeviceList() ?? []
        deviceList.append(device)
        saveDeviceList(deviceList)
        print("设备添加成功")
    }
    
    func updateDevice(device: DeviceData) {
        var deviceList = loadDeviceList() ?? []
        
        if let index = deviceList.firstIndex(where: { $0.ssid == device.ssid }) {
            deviceList[index] = device
            saveDeviceList(deviceList)
            print("设备数据更新成功")
        } else {
            print("未找到要更新的设备")
        }
    }

    func setAllIsConnectToDefault() {
            var deviceList = loadDeviceList() ?? []
            
            for index in 0..<deviceList.count {
                deviceList[index].isConnect = 2
            }
            
            saveDeviceList(deviceList)
            print("所有设备的 isConnect 已设置为 2")
        }

}
