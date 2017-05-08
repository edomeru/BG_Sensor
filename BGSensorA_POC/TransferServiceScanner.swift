//
//  TransferServiceScanner.swift
//  BGSensorA_POC
//
//  Created by Edmer Alarte on 3/5/2017.
//  Copyright © 2017 com.tektos.ph. All rights reserved.
//

import Foundation
import CoreBluetooth


extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}


protocol TransferServiceScannerDelegate: NSObjectProtocol {
    func didStartScan()
    func didStopScan()
    func didConnect()
    func didNotConnect()
    func didTrigger()
    func didTransferData(data: NSData?)
}

class TransferServiceScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var numberofBGSensor:Int = 0
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var data: NSMutableData = NSMutableData()
    weak var delegate: TransferServiceScannerDelegate?
 
    
    
    init(delegate: TransferServiceScannerDelegate?) {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.delegate = delegate
        numberofBGSensor = 0
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager!) {
        switch (central.state) {
        case .poweredOn:
            print("Central Manager powered on.")
            break
        case .poweredOff:
            print("Central Manager powered off.")
            stopScan()
            break;
        default:
            print("Central Manager changed state \(central.state)")
            break
        }
    }
    
    func startScan() {
        print("Start scan")
        let services = [CBUUID(string: Const.UUID.kTransferServiceUUID)]
        print("startScan  \(Const.UUID.kTransferServiceUUID)")
        let options = Dictionary(dictionaryLiteral:
            (CBCentralManagerScanOptionAllowDuplicatesKey, false))
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        delegate?.didStartScan()
    }
    
    func stopScan() {
        print("Stop scan")
        centralManager.stopScan()
        delegate?.didStopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral:
        CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral \(peripheral.identifier)")
      
        let deviceName = "BG Sensor A"
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
         print("didDiscoverPeripheral \(nameOfDeviceFound)")
        // reject if above reasonable range, or too low
//        if (RSSI.intValue > -15) || (RSSI.intValue < -35) {
//            print("not in range, RSSI is \(RSSI.intValue)")
//            return;
//        }
        
        //if (UUID(uuidString: Const.UUID.kTransferServiceUUID) == peripheral.identifier) {
        
        
        
        
        
        //CHECK NUMBER OF BG SENSOR DEVICES, IF ZERO RECALL CBCentralManager
        if let localName = nameOfDeviceFound {
            
            if localName.contains(deviceName){

                self.numberofBGSensor += 1
               
                
            }
            
             print("NUMBER OF BG SENSOR! \(self.numberofBGSensor)")
            
//            if numberofBGSensor == 0 {
//                print("WALANG BG SENSOR! ")
//                centralManager = CBCentralManager(delegate: self, queue: nil)
//                
//            }
            
            
        if(deviceName == localName as String ){
            
            if discoveredPeripheral == nil {
                
                print("discoveredPeripheral NIL BA? \(discoveredPeripheral)")
                discoveredPeripheral = peripheral
                print("discoveredPeripheral AFTER \(discoveredPeripheral)")
                print("connecting to peripheral \(peripheral)")
                centralManager.connect(peripheral, options: nil)
                
                
                
            }else{
                
                if (discoveredPeripheral?.identifier != peripheral.identifier) {
                    discoveredPeripheral = peripheral
                }
                
                print("discoveredPeripheral ELSE NIL BA? \(discoveredPeripheral)")
             
                print("connecting to peripheral ELSE \(peripheral)")
                
                if let discoverPeripheral = discoveredPeripheral{
                centralManager.connect(discoverPeripheral, options: nil)
                    }
            }
            
           
           
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager!, didConnect peripheral:
        CBPeripheral!) {
        print("didConnectPeripheral")
       
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            
            print("Dispatch timerA event after 200ms")
            print("\(peripheral)")
            self.stopScan()
            self.delegate?.didConnect()
            self.data.length = 0
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            
        }
        
    
       
    }
    
    
    func centralManager(_ central: CBCentralManager!, didFailToConnectPeripheral peripheral:
        CBPeripheral!, error: NSError!) {
        print("didFailToConnectPeripheral")
        delegate?.didNotConnect()
        
       
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        print("didDiscoverServices  HOY  PERIPHERAL\(peripheral.services! )")
         //print("didDiscoverServices  HOY  \(peripheral.discoverServices([CBUUID(string: "AAOO")]))")
   
        
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        // look for the characteristics we want
        for service in peripheral.services! {
            print("SERVICES IN LOOP   \(service)")
         peripheral.discoverCharacteristics(nil,
                                               for: service)
            
            print(" SERVICE   \(service.uuid)")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsForService service:
        CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService")
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        // loop through and verify the characteristic is the correct one, then subscribe to it
        let cbuuid = CBUUID(string: "AA01")
        for characteristic in service.characteristics! {
            print("characteristic.UUID is \(characteristic.uuid)")
         
           
            if characteristic.uuid == cbuuid {
                //peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("SHAKE CHARAC  \(characteristic)")
            
            }
        }
    }
    
    //override
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueForCharacteristic")
         print("value \(characteristic.value!)")
        
//        let data = characteristic.value!
//        let dataString = String(data: data, encoding: String.Encoding.utf8)
//          print("dataString \(dataString)")
        
        
        var wavelength: UInt16?
        if let data = characteristic.value {
            var bytes = Array(repeating: 0 as UInt8, count:data.count/MemoryLayout<UInt8>.size)
            
            data.copyBytes(to: &bytes, count:data.count)
            let data16 = bytes.map { UInt16($0) }
            wavelength = 256 * data16[1] + data16[0]
        }
        if let characValue = wavelength{
        print("THE CHARAC VALUE IS \(characValue)")
            
            if characValue == 0 {
               dispatchTimerA(peripheral)
                
            }else{
                self.delegate?.didTrigger()
                dispatchTimerB(peripheral)
            }
        }
            
        }
        

    func dispatchTimerA(_ peripheral: CBPeripheral){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
        
    }
    
    func dispatchTimerB(_ peripheral: CBPeripheral){
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(1500)) {
            print("TIMER B")
        }
        
    }
    
    }

