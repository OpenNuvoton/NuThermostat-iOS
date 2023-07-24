//
//  AlertTool.swift
//  NuThermostat_iOS
//
//  Created by MS70MAC on 2023/5/23.
//

import UIKit

class AlertTool {
    static let shared = AlertTool()
    
    private static var alertController: UIAlertController?
    private static var progressView = UIProgressView(progressViewStyle: .default)
    
    func showInfo(from viewController: UIViewController,message text:String,hasOk:Bool,hasNo:Bool,callback:((_ isOk:Bool)->Void)?){
        
        
        AlertTool.alertController = UIAlertController(title: "", message: text, preferredStyle: .alert)
        if(hasOk){
            let okAction = UIAlertAction(title: "OK", style: .default, handler: {_ in
                callback?(true)
            })
            AlertTool.alertController!.addAction(okAction)
        }
        if(hasNo){
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                callback?(false)
            })
            AlertTool.alertController!.addAction(cancelAction)
        }
        
        DispatchQueue.main.async() {
            if let presentedViewController = viewController.presentedViewController {
                presentedViewController.dismiss(animated: true){
                    viewController.present(AlertTool.alertController!, animated: true, completion: nil)
                }
            } else {
                viewController.present(AlertTool.alertController!, animated: true, completion: nil)
            }
        }
    }
    
    func showLoading(from viewController: UIViewController) {
        
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Loading..."
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.startAnimating()
        
        containerView.addSubview(indicatorView)
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo:containerView.centerXAnchor,constant:-100),
            indicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0)
        ])
        
        alertController.view.addSubview(containerView)
        
        containerView.centerXAnchor.constraint(equalTo: alertController.view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: alertController.view.centerYAnchor).isActive = true
        
        AlertTool.alertController = alertController
        
        DispatchQueue.main.async() {
            if let presentedViewController = viewController.presentedViewController {
                presentedViewController.dismiss(animated: true){
                    viewController.present(AlertTool.alertController!, animated: true, completion: nil)
                }
            } else {
                viewController.present(AlertTool.alertController!, animated: true, completion: nil)
            }
        }
        
    }
    
    func dismissShow() {
        DispatchQueue.main.async() {
            if(AlertTool.alertController != nil){
                AlertTool.alertController?.dismiss(animated: true, completion: nil)
            }
//            AlertTool.alertController = nil
        }
    }
    
    func showProgressAlert(from self: UIViewController, title: String)  {
//        // 1. 創建一個 UIAlertController
//        AlertTool.alertController  = UIAlertController(title: title, message: nil, preferredStyle: .alert)
//
//        // 2. 創建一個 UIProgressView 並設置進度條的屬性
//        AlertTool.progressView.frame = CGRect(x: 10, y: 70, width: 250, height: 0) // 設置進度條視圖的位置和尺寸
//        AlertTool.progressView.setProgress(0, animated: false) // 初始進度為 0
//        AlertTool.progressView.tintColor = .blue // 設置進度條的顏色
//
//        // 3. 將進度條視圖加入 UIAlertController 的視圖層級結構中
//        AlertTool.alertController! .view.addSubview(AlertTool.progressView)
//
//        // 5. 顯示 UIAlertController
//        self.present(AlertTool.alertController!, animated: true, completion: nil)
//
//        // 6. 呼叫 updateProgress 更新進度條的值
//        AlertTool.progressView.setProgress(0, animated: true)
        
        //  Just create your alert as usual:
        AlertTool.alertController = UIAlertController(title: "Please wait", message: "Burning firmware into the device...", preferredStyle: .alert)
//        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        //  Show it to your users
        self.present(AlertTool.alertController!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 8.0
            let rect = CGRect(x: margin, y: 72.0, width: AlertTool.alertController!.view.frame.width - margin * 2.0 , height: 2.0)
            AlertTool.progressView = UIProgressView(frame: rect)
            AlertTool.progressView.progress = 0
            AlertTool.progressView.tintColor = UIColor(displayP3Red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            AlertTool.alertController!.view.addSubview(AlertTool.progressView)
        })
        
    }
    
    func updateProgressValue(progress: Float) {
        // 设置自定义的最小值和最大值
        let minValue: Float = 0.0
        let maxValue: Float = 100.0

        // 计算当前进度（假设进度为5）
        let currentValue: Float = progress
        let theProgress = (currentValue - minValue) / (maxValue - minValue)
        DispatchQueue.main.async() {
            AlertTool.progressView.setProgress(theProgress, animated: true)
        }

    }
    
    func showWiFi_input(from viewController: UIViewController, callback: @escaping (_ ssid: String, _ pwd: String) -> Void) {
        
        AlertTool.alertController = UIAlertController(title: "Setting", message: "Please enter the SSID and password for your home WiFi connection.", preferredStyle: .alert)
        AlertTool.alertController!.addTextField { textField in
            textField.placeholder = "SSID"
        }
        AlertTool.alertController!.addTextField { textField in
            textField.placeholder = "Password"
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak viewController] _ in
            guard viewController != nil else {
                return
            }
            let phone = AlertTool.alertController?.textFields?[0].text
            let password = AlertTool.alertController?.textFields?[1].text
            print(phone, password)
            callback(phone!,password!)
        }
        AlertTool.alertController!.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){ _ in
            callback("","")
        }
        AlertTool.alertController!.addAction(cancelAction)
        
        DispatchQueue.main.async() {
            if let presentedViewController = viewController.presentedViewController {
                presentedViewController.dismiss(animated: true){
                    viewController.present(AlertTool.alertController!, animated: true, completion: nil)
                }
            } else {
                viewController.present(AlertTool.alertController!, animated: true, completion: nil)
            }
        }
        
    }
}

