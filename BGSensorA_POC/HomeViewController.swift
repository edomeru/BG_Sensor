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
    
    @IBOutlet weak var connectingLabel: UILabel!
    
    @IBOutlet weak var secureImage: UIImageView!
     var isScanning: Bool = false
    var tktCoreLocation: TransferServiceScanner!
    var centralManager: CBCentralManager!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
       tktCoreLocation = TransferServiceScanner(delegate: self)
      
       
    }

    
    
    @IBAction func connectFunc(_ sender: Any) {
        tktCoreLocation.startScan()
    }
    

    @IBAction func dcFunc(_ sender: Any) {
        tktCoreLocation.stopScan()
    }
    
    
    func didStartScan() {
        connectingLabel.isHidden = false
    }
    
    func didStopScan() {
        connectingLabel.isHidden = true
    }
    func didTransferData(data: NSData?) {
        
    }
    
    func didConnect() {
        connectingLabel.isHidden = true
        secureImage.isHidden = false
    }
    
    func didNotConnect() {
        connectingLabel.text = "Searching"
        secureImage.isHidden = true
    }
    
    func didTrigger() {
        connectingLabel.isHidden = true
        secureImage.image =  UIImage(named: "sensor-triggered")
    }
    
}

