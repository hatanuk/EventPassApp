//
//  BLEManager.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation
import CoreBluetooth


class BLEViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    // this stores detected devices
    var peripherals: [CBPeripheral] = []
    
    // conversion of nearby peripherals to accessible profiles
    @Published var nearbyUsers: [UserProfile] = []
    
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
        
    }
    
}


extension BLEViewModel: CBCentralManagerDelegate {
    // RECIEVING TRANSMISSIONS
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        default:
            // add a "bluetooth off" flag
            break
        }
    }
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // the method which is called whenever a new peripheral is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals.append(peripheral)
    }
}


    
extension BLEViewModel: CBPeripheralManagerDelegate {
    // advertising transmissions
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            startAdvertising()
        default:
            // add a "bluetooth off" flag
            break
        }
    }
    
    func startAdvertising() {

        let advertisementData = [CBAdvertisementDataLocalNameKey: "MyDevice"]
        peripheralManager.startAdvertising(advertisementData)
    }
}


