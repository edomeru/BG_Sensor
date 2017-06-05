//
//  ViewController.swift
//  BGSensorA_POC
//
//  Created by Edmer Alarte on 3/5/2017.
//  Copyright © 2017 com.tektos.ph. All rights reserved.
//

import UIKit
import CoreBluetooth

class HomeViewController: UIViewController, TransferServiceScannerDelegate {
    
    @IBOutlet weak var exclamationImage: UIImageView!
    @IBOutlet weak var connectingLabel: UILabel!
    @IBOutlet weak var garageDoorLabel: UILabel!
    @IBOutlet weak var secureTimer: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var timerTrigger: UILabel!
    @IBOutlet weak var sensorTriggered: UIImageView!
    @IBOutlet weak var secureImage: UIImageView!
    var isScanning: Bool = false
    var tktCoreLocation: TransferServiceScanner!
    var centralManager: CBCentralManager!
    @IBOutlet weak var timeLabel: UILabel!
    var dateString:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tktCoreLocation = TransferServiceScanner(delegate: self)
        showTime()
        applicationInfo()
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.showTimeForground(_:)), name: NSNotification.Name(rawValue: "showTime"), object: nil)
        
    }
    
    
    
    //    @IBAction func connectFunc(_ sender: Any) {
    //        tktCoreLocation.startScan()
    //    }
    //
    //
    //    @IBAction func dcFunc(_ sender: Any) {
    //        tktCoreLocation.stopScan()
    //    }
    
    
    func didStartScan() {
        connectingLabel.isHidden = false
        connectingLabel.text = "Connecting..."
        secureImage.isHidden = true
        sensorTriggered.isHidden = true
        exclamationImage.isHidden = true
        showTime()
    }
    func didStartSearch() {
        connectingLabel.isHidden = false
        connectingLabel.text = "Searching..."
        secureImage.isHidden = true
        sensorTriggered.isHidden = true
        exclamationImage.isHidden = true
        showTime()
    }
    
    func didStopScan() {
        connectingLabel.isHidden = true
        sensorTriggered.isHidden = true
        exclamationImage.isHidden = true
    }
    func didTransferData(data: NSData?) {
        
    }
    
    func didConnect() {
        didStartScan()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(800)) {
            self.connectingLabel.isHidden = true
            self.secureImage.isHidden = false
            //        secureImage.image =  UIImage(named: "secure")
            self.sensorTriggered.isHidden = true
            self.garageDoorLabel.isHidden = true
            self.timerTrigger.isHidden = true
            self.secureTimer.isHidden = false
            self.exclamationImage.isHidden = true
            self.showTime()
        
        }
    }
    
        func didConnect_2() {
                self.connectingLabel.isHidden = true
                self.secureImage.isHidden = false
                //        secureImage.image =  UIImage(named: "secure")
                self.sensorTriggered.isHidden = true
                self.garageDoorLabel.isHidden = true
                self.timerTrigger.isHidden = true
                self.secureTimer.isHidden = false
                self.exclamationImage.isHidden = true
                showTime()
    }
    
    func didNotConnect() {
        connectingLabel.text = "Searching..."
        secureImage.isHidden = true
        sensorTriggered.isHidden = true
        exclamationImage.isHidden = true
        showTime()
    }
    
    func didTrigger() {
        connectingLabel.isHidden = true
        //        secureImage.image =  UIImage(named: "sensor-triggered")
        secureImage.isHidden = true
        sensorTriggered.isHidden = false
        garageDoorLabel.isHidden = false
        timerTrigger.isHidden = false
        secureTimer.isHidden = true
        exclamationImage.isHidden = false
        showTime()
    }
    
    func showTime(){
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        dateString = formatter.string(from: Date())
        print("DATE \(dateString)")
        secureTimer.text = self.dateString
        timerTrigger.text = self.dateString
        
    }
    
    fileprivate func applicationInfo() {/// SET VERSION NUMBER AT THE BOTTOM
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "v\(version)"
        }
    }
    
    func showTimeForground(_ notification: Notification) {
        showTime()
        print("showTimeForground")
    }
    
    
}

