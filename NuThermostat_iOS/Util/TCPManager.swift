//
//  WebSocketManager.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/5/29.
//

import Foundation

protocol TCPManagerDelegate: AnyObject {
    func tcpManagerDidConnect()
    func tcpManagerDidReceiveData(data: Data)
    func tcpManagerDidDisconnect()
}

class TCPManager {
    weak var delegate: TCPManagerDelegate?

    private var client: TCPClient?

    func connectToServer(address: String, port: Int) {
        client = TCPClient(address: address, port: Int32(port))

        DispatchQueue.global(qos: .background).async {
            guard let client = self.client else { return }
            
            switch client.connect(timeout: 10) {
            case .success:
                DispatchQueue.main.async {
                    self.delegate?.tcpManagerDidConnect()
                }
                self.receiveData()
            case .failure(let error):
                print("连接失败：\(error.localizedDescription)")
            }
        }
    }

    func disconnect() {
        client?.close()
        delegate?.tcpManagerDidDisconnect()
    }

    func send(data: Data) {
        client?.send(data: data)
    }

    private func receiveData() {
        DispatchQueue.global(qos: .background).async {
            guard let client = self.client else { return }

            while true {
                guard let response = client.read(1024) else {
                    // 读取失败，可能是连接断开
                    break
                }

                DispatchQueue.main.async {
                    let data = Data(response)
                    self.delegate?.tcpManagerDidReceiveData(data: data)
                }

            }

            // 连接断开，执行相应处理
            DispatchQueue.main.async {
                self.delegate?.tcpManagerDidDisconnect()
            }
        }
    }


}
