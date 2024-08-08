//
//  NetworkViewModel.swift
//  EventPass
//
//  Created by Andrew A on 08/08/2024.
//

import Foundation
import Network

enum ConnectionState {
    case connected
    case connecting
    case noConnection
}

class NetworkViewModel: ObservableObject {
    
    @Published var connectionState: ConnectionState = .connecting
    
    func checkInternetConnection() {
        

        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.connectionState = .connected
                } else {
                    self.connectionState = .noConnection
                }
            }
        }
        monitor.start(queue: queue)
    }
    
}
