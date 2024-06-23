//
//  BLEManager.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation
import CoreBluetooth


class BLEViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager
    // this stores detected devices
    private var peripherals: CBPeripheral
    
    // conversion of nearby peripherals to accessible profiles
    @Published var nearbyUsers: [Profile] = []
    
    
    init() {
        super.init()
    }
}


class BLEViewModel: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    var isBluetoothOn: Bool = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // Recieving transmissions
        
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true;
            startScanning()
        default:
            // add a "bluetooth off" flag
            break
        }
    }
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // Advertising transmissions
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            isBluetoothOn = true;
            startAdvertising()
        default:
            // add a "bluetooth off" flag
            isBluetoothOn = false;
            break
        }
    }
    
    func startAdvertising() {
        // Start advertising
        let advertisementData = [CBAdvertisementDataLocalNameKey: "MyDevice"]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    // Other delegate methods and BLE functionalities
}
