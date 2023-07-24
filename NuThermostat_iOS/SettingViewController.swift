//
//  SettingViewController.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/6/7.
//

import UIKit

struct InfoData {
    var isPowerOn: Bool
    var isHot: Bool
    var temperature: Int
    var localTemperature: Float
    var isDefog: Bool
    var isLock: Bool
    init() {
        isPowerOn = false
        isHot = false
        temperature = 16
        localTemperature = 16.0
        isDefog = false
        isLock = false
    }
}

class SettingViewController: UIViewController {
    
    @IBOutlet weak var powerImage: UIImageView!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var hot_cool_imaage: UIImageView!
    
    @IBOutlet weak var TargetT_Slider: UISlider!
    @IBOutlet weak var currentT_text: UILabel!
    @IBOutlet weak var uiSlider: UISlider!{
        didSet{
            // 调整滑块
            let thumbImage = UIImage(named: "icon_thumb.png")
            uiSlider.setThumbImage(thumbImage, for: .normal)

            uiSlider.minimumTrackTintColor = UIColor(hexString: "#88f1b4")
            uiSlider.maximumTrackTintColor = UIColor(hexString: "#444f6d")


        }
    }
    @IBOutlet weak var antifrostSwitch: UISwitch!{
        didSet {
            antifrostSwitch.isOn = false
            antifrostSwitch.tintColor = UIColor(hexString: "#444f6d") //off
            antifrostSwitch.onTintColor = UIColor(hexString: "#444f6d") //on
            antifrostSwitch.thumbTintColor = UIColor(hexString: "#88f1b4")
        }
    }
    @IBOutlet weak var lockSwitch: UISwitch!{
        didSet {
            lockSwitch.isOn = false
            lockSwitch.tintColor = UIColor(hexString: "#444f6d") //off
            lockSwitch.onTintColor = UIColor(hexString: "#444f6d") //on
            lockSwitch.thumbTintColor = UIColor(hexString: "#88f1b4")
        }
    }
    @IBOutlet weak var targetT_text: UILabel!
    static var Controller_Identifier_SSID: String  = ""
    
    var infoData:InfoData = InfoData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 TCPManagerPool 实例
        TCPManagerPool.shared.delegate = self
        
        let getInfo_BF = CMDManager().toGetInfo_BF()
        TCPManagerPool.shared.send(data: Data(getInfo_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("getInfo_BF:\(isSuccess)")
        }
        
        //防止底下元件被觸摸
        self.powerImage.isUserInteractionEnabled = true
        // 添加滑动值变更事件
        self.TargetT_Slider.minimumValue = 16 // 设置最小值
        self.TargetT_Slider.maximumValue = 30 // 设置最大值
        self.TargetT_Slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        // 添加滑动结束事件
        self.TargetT_Slider.addTarget(self, action: #selector(sliderDidEnd(_:)), for: .touchUpInside)
        self.antifrostSwitch.onImage = UIImage(named: "icon_uiswitch_on.png")
        self.antifrostSwitch.offImage = UIImage(named: "icon_uiswitch_off.png")
    }
    
    func updataUI(){
        DispatchQueue.main.async() {
            
            let power = self.infoData.isPowerOn
            let hot = self.infoData.isHot
            let localTemperature = self.infoData.localTemperature
            let setTemperature = self.infoData.temperature
            let defog = self.infoData.isDefog
            let lock = self.infoData.isLock
            
            let powerImage = power ? UIImage(named: "icon_power_on") : UIImage(named: "icon_power_off")
            self.powerButton.setImage(powerImage, for: .normal)
            self.powerImage.isHidden = power
            
            let hotImage = hot ? UIImage(named: "icon_home_hot") : UIImage(named: "icon_home_cool")
            self.hot_cool_imaage.image = hotImage
            
            self.currentT_text.text = "\(localTemperature)°C"
            self.TargetT_Slider.value = Float(setTemperature)// 设置当前值
            self.targetT_text.text = "\(setTemperature)"
            
            self.antifrostSwitch.isOn = defog
            self.lockSwitch.isOn = lock
        }
        
    }
    
    func setInfoData(power:Bool,hot:Bool,setTemperature:Int,localTemperature:Float,defog:Bool,lock:Bool){
        self.infoData.isPowerOn = power
        self.infoData.isHot = hot
        self.infoData.localTemperature = localTemperature
        self.infoData.temperature = setTemperature
        self.infoData.isDefog = defog
        self.infoData.isLock = lock
    }
    
    
    @IBAction func SetPowerButton(_ sender: UIButton) {
        print("SetPowerButton")
        
        let setPower_BF = CMDManager().toSetPower_BF(setON: !self.infoData.isPowerOn  )
        TCPManagerPool.shared.send(data: Data(setPower_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("setPower_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.isPowerOn = !self.infoData.isPowerOn
                self.updataUI()
            }
        }
        
    }
    
    @IBAction func SetCoolButton(_ sender: UIButton) {
        print("SetCoolButton")
        
        let set_BF = CMDManager().toSetHot_BF(setHot: false)
        TCPManagerPool.shared.send(data: Data(set_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("set_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.isHot = false
                self.updataUI()
            }
        }
        
    }
    
    @IBAction func SetHotButton(_ sender: UIButton) {
        print("SetHotButton")
        let set_BF = CMDManager().toSetHot_BF(setHot: true)
        TCPManagerPool.shared.send(data: Data(set_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("set_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.isHot = true
                self.updataUI()
            }
        }
        
    }
    
    @IBAction func SetAntifrostSwitch(_ sender: UISwitch) {
        print("SetAntifrostSwitch")
        let set_BF = CMDManager().toSetAntifrost_BF(setHot: !self.infoData.isDefog)
        TCPManagerPool.shared.send(data: Data(set_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("set_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.isDefog = !self.infoData.isDefog
                self.updataUI()
            }
        }
    }
    
    @IBAction func SetLockSwitch(_ sender: UISwitch) {
        print("SetLockSwitch")
        let set_BF = CMDManager().toSetLock_BF(setHot: !self.infoData.isLock)
        TCPManagerPool.shared.send(data: Data(set_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("set_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.isLock = !self.infoData.isLock
                self.updataUI()
            }
        }
    }
    
    
    // 滑动值变更事件处理函数
    @objc func sliderValueChanged(_ slider: UISlider) {
        let value = Int(slider.value)
        // 在这里可以执行相应的操作
        targetT_text.text = "\(value)"
    }
    
    // 滑动结束事件处理函数
    @objc func sliderDidEnd(_ slider: UISlider) {
        let value = Int(slider.value)
        print("滑动结束：\(value)")
        // 在这里可以执行相应的操作
        let set_BF = CMDManager().toSetTemperature_BF(temperature: value)
        TCPManagerPool.shared.send(data: Data(set_BF), toConnectionWithIdentifier: SettingViewController.Controller_Identifier_SSID) { isSuccess in
            print("set_BF:\(isSuccess)")
            if(isSuccess == true){
                self.infoData.temperature = value
                self.updataUI()
            }
        }
    }
    
}

extension SettingViewController: TCPManagerPoolDelegate {
    func tcpManagerPoolDidDisconnect(identifier: String) {
        // 連線中斷
    }
    
    func tcpManagerPoolDidReceiveData(data: Data, fromConnectionWithIdentifier identifier: String) {
        // 处理接收到的数据
        if identifier != SettingViewController.Controller_Identifier_SSID {
            return
        }
        
        print("response from \(identifier): \(data.toHexString())")
        
        if let firstByte = data.first {
            switch firstByte {
            case 0xa0: //getInfo
                let power = data[2] == 0x01
                let hot = data[3] == 0x01
                let sti = Int(data[4])
                let stf = Int(data[5])
                let setTemperature = Int("\(sti)") ?? 0
                let lti = Int(data[6])
                let ltf = Int(data[7])
                let localTemperature = Float("\(lti).\(ltf)") ?? 0.0
                let defog = data[8] == 0x01
                let lock = data[9] == 0x01
                self.setInfoData(power: power,hot: hot,setTemperature: setTemperature,localTemperature: localTemperature,defog: defog,lock: lock)
                self.updataUI()
                break
            case 0xb1:
                break
            case 0xb2:
                break
            default: break
                
            }
        }
    }
    
}
