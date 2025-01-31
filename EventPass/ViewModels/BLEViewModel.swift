//
//  BLEManager.swift
//  EventPass
//
//  Created by Andrew A on 23/06/2024.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BLEViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    // view which handles majority of interactions in AttendeeHubView, including, of course, Bluetooth Low Energy transmission
    
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    @Published var discoveredUsers: [UserModel] = [UserModel(fromCard: Constants.testProfile3)]
    @Published var isTransmitting: Bool = false {
        didSet {
            if isTransmitting {
                startAdvertising()
                startScanning()
            } else {
                stopAdvertising()
            }
        }
    }
    @Published var savedCardsStack: [CardModel] = []
    @Published var cardRequestsStack: [CardModel] = []
    private var discoveredPeripherals: [CBPeripheral] = []
    private let serviceUUID = Constants.serviceUUID
    private let characteristicUUID = Constants.characteristicUUID
    private var transferCharacteristic: CBMutableCharacteristic?
    private var currentUser: UserModel
    
    let BLEByteLimit = 182
    

    init(userCard: CardModel) {
        self.currentUser = UserModel(fromCard: userCard)
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if isTransmitting == false {
            return
        }
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func startAdvertising() {
        
        if isTransmitting == false {
            return
        }
        guard let data = try? JSONEncoder().encode(currentUser) else {
            print("Error encoding UserModel for BLE transmission")
            return
        }
        // check if the data fits within the BLE limit
        if data.count > BLEByteLimit {
            print("Data size exceeds 512 bytes and needs to be reduced or chunked.")
            return
        }
        // characteristic is the data which is sent to the central
        transferCharacteristic = CBMutableCharacteristic(type: characteristicUUID,
                                                         properties: [.read],
                                                         value: data,
                                                         permissions: [.readable])
        
        // service is the container for the characteristic
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [transferCharacteristic!]
        peripheralManager.add(service)
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }
    
    // MARK: - DB Operations
    func retrieveCardAndSaveLocally(from user: UserModel) async {
        do  {
            let card = try await CardModel(fromUserId: user.id)
            addCardToLocalDB(card)
        } catch {
            print("Card retrieval for user \(user.displayName ?? "Unknown") failed.")
            return
        }

            
    }
    
    func addCardToLocalDB(_ card: CardModel) {
        var savedCards = UserDefaults.standard.array(forKey: "savedCardsFromOthers") as? [Data] ?? []
        
        let existingIDs = savedCards.compactMap { savedData in
               (try? JSONDecoder().decode(CardModel.self, from: savedData))?.id
           }
        
        // this is to check for duplicates
        var index: Int?
        if existingIDs.contains(card.id) {
            index = existingIDs.firstIndex(of: card.id)
        }
        
        if let encodedCard = try? JSONEncoder().encode(card) {
            if let index = index {
                // if card with same ID exists, replace it
                savedCards[index] = encodedCard
            } else {
                // otherwise append it to the array
                savedCards.append(encodedCard)
            }
                UserDefaults.standard.set(savedCards, forKey: "savedCardsFromOthers")
            }
    }
    
    static func clearSavedCards() {
        UserDefaults.standard.removeObject(forKey: "savedCardsFromOthers")
    }
    
    func updateSavedCards() {
        let savedCards = UserDefaults.standard.array(forKey: "savedCardsFromOthers") as? [Data] ?? []
        savedCardsStack = savedCards.compactMap { data in
            try? JSONDecoder().decode(CardModel.self, from: data)
        }
    }
     
    func sendCardRequest(to user: UserModel) {}
    
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // stores a strong reference of the discovered peripheral and connects to it
        discoveredPeripherals.append(peripheral)
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // sets the peripheral delegate as self, meaning it will be handled by CBPeripheralDelegate
        peripheral.delegate = self
        // specify the the unique service UUID which identifies this app's functionality
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // removes the peripheral from the discovered array
        if let index = discoveredPeripherals.firstIndex(of: peripheral) {
            discoveredPeripherals.remove(at: index)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // prevents failed peripheral connections from clogging up the discovered array
        if let index = discoveredPeripherals.firstIndex(of: peripheral) {
            discoveredPeripherals.remove(at: index)
        }
    }

    
    // MARK: - CBPeripheralManagerDelegate Methods
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        }
    }
    
    // MARK: - CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // called after peripheral.discoverServices
        guard error == nil else { return }
        peripheral.services?.forEach { service in
            // this will call didDiscoverCharacteristicsFor
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        service.characteristics?.forEach { characteristic in
            if characteristic.uuid == characteristicUUID {
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        if let receivedUser = try? JSONDecoder().decode(UserModel.self, from: data) {
            DispatchQueue.main.async { self.discoveredUsers.append(receivedUser) }
        }
    }

}
