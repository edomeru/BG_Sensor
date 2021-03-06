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
    func didConnect_2()
    func didTrigger()
    func didStartSearch()
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
            startScan()
            
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
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        delegate?.didStartSearch()
    }
    
    func stopScan() {
        print("Stop scan")
        centralManager.stopScan()
        delegate?.didStopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral:
        CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral --  \(peripheral.identifier)")
        
        let deviceName = "BG Sensor A"
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        print("didDiscoverPeripheral \(nameOfDeviceFound)")
        
        
        //CHECK NUMBER OF BG SENSOR DEVICES, IF ZERO RECALL CBCentralManager
        if let localName = nameOfDeviceFound {
            
            if localName.contains(deviceName){
                self.numberofBGSensor += 1
            }
            
            print("NUMBER OF BG SENSOR! \(self.numberofBGSensor)")
            
            
            if(deviceName == localName as String ){
                print("didDiscoverPeripheral here \(peripheral.identifier)")
                if self.discoveredPeripheral == nil {
                    
                    self.discoveredPeripheral = peripheral
                    print("discoveredPeripheral AFTER \(self.discoveredPeripheral)")
                    print("peripheral ELSE \(peripheral)")
                    self.centralManager.connect(peripheral, options: nil)
                    
                }else{
                    
                    if (self.discoveredPeripheral?.identifier != peripheral.identifier) {
                        self.discoveredPeripheral = peripheral
                        print("discoveredPeripheral NEW ELSE  \(self.discoveredPeripheral)")
                    }
                    
                    
                    print("discoveredPeripheral ELSE  \(self.discoveredPeripheral)")
                    
                    print("peripheral ELSE \(peripheral)")
                    
                    if let discoverPeripheral = self.discoveredPeripheral{
                        self.centralManager.connect(discoverPeripheral, options: nil)
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
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        
        // look for the characteristics we want
        for service in peripheral.services! {
            print("SERVICES IN LOOP   \(service)")
            
            if service.uuid == CBUUID(string: "AA00"){
                peripheral.discoverCharacteristics(nil,
                                                   for: service)
            }
            
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
                peripheral.readValue(for: characteristic)
                print("SHAKE CHARAC  \(characteristic)")
                
            }
        }
    }
    
    //override
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueForCharacteristic")
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)               //DISCONNECT
            return
        }
        print("VALUE  \(characteristic.value)")
        
        let  characValue  =  convertToInt(characteristic)
        
        print("CHARAC VALUE  \(characValue)")
        
        if characValue == 0 {
            dispatchTimerA(peripheral)
            
        }else{
            print("SHAKE > ZERO")
            self.delegate?.didTrigger()
            dispatchTimerB(peripheral, characteristic: characteristic)
        }
        
        
    }
    
    
    func dispatchTimerA(_ peripheral: CBPeripheral){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
        
    }
    
    func dispatchTimerB(_ peripheral: CBPeripheral, characteristic: CBCharacteristic){
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(1500)) {
            print("TIMER B")
            self.timerB(peripheral,characteristic: characteristic)
        }
    }
    
    
    func timerB(_ peripheral: CBPeripheral, characteristic: CBCharacteristic){
        self.delegate?.didConnect_2()
        print("INSIDE TIMER B")
        writeZeroToShake(peripheral,characteristic: characteristic)
    }
    
    func  writeZeroToShake(_ peripheral: CBPeripheral, characteristic: CBCharacteristic){
        let data = Data(bytes: [0x00, 0x00])
        
        print("characteristic \(characteristic.value)")
        print("data \(data)")
        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let convertedValue =  convertToInt(characteristic)
        
        print("convertedValue \(convertedValue)")
        
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)               //DISCONNECT
            startScan()     //RECONNECT
            return
        }else{
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
                print("didWriteValueFor")
                peripheral.delegate = self
                peripheral.discoverServices(nil)
            }
            
            
        }
        
    }
    
    func convertToInt(_ characteristic: CBCharacteristic) -> Int {
        
        var wavelength: UInt16?
        
        if let data = characteristic.value {
            
            var bytes = Array(repeating: 0 as UInt8, count:data.count/MemoryLayout<UInt8>.size)
            
            
            data.copyBytes(to: &bytes, count:data.count)
            let data16 = bytes.map { UInt16($0) }
            wavelength = 256 * data16[1] + data16[0]
        }
        
        if let characValue = wavelength {
            print("didWriteValueFor TIMER B  \(characValue)")
            
            return Int(characValue)
        }
        
        return -1
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if (error != nil) {
            print("Encountered error DC: \(error!.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)               //DISCONNECT
            startScan()  //RECONNECT
            return
        }
    }
}


