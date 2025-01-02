//
//  ConnectionViewModel.swift
//  EthernetStatus
//
//  Created by Dominik on 02.01.25.
//


import Foundation
import Network

class NetworkStatusViewModel: ObservableObject {
    @Published var isLANConnected: Bool = false
    @Published var ipv4Address: String = "Unknown"
    @Published var ipv6Address: String = "Unknown"
    @Published var routerAddress: String = "Unknown"
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    init() {
        startMonitoring()
        getNetworkAddresses()
        getRouterAddress()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isLANConnected = path.usesInterfaceType(.wiredEthernet)
                self?.getNetworkAddresses()
                self?.getRouterAddress()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getNetworkAddresses() {
        var ipv4 = "Unknown"
        var ipv6 = "Unknown"
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }
        
        var pointer = ifaddr
        while pointer != nil {
            guard let interface = pointer?.pointee else { break }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                if let name = String(cString: interface.ifa_name, encoding: .utf8),
                   name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        ipv4 = String(cString: hostname)
                    }
                }
            }
            
            if addrFamily == UInt8(AF_INET6) {
                if let name = String(cString: interface.ifa_name, encoding: .utf8),
                   name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        ipv6 = String(cString: hostname)
                    }
                }
            }
            
            pointer = pointer?.pointee.ifa_next
        }
        
        DispatchQueue.main.async {
            self.ipv4Address = ipv4
            self.ipv6Address = ipv6
        }
    }
    
    private func getRouterAddress() {
        queue.async { [weak self] in
            let task = Process()
            let pipe = Pipe()
            
            guard let netstatPath = "/usr/sbin/netstat" as NSString? else {
                DispatchQueue.main.async { self?.routerAddress = "Unknown" }
                return
            }
            
            do {
                task.executableURL = URL(fileURLWithPath: netstatPath as String)
                task.arguments = ["-nr"]
                task.standardOutput = pipe
                
                try task.run()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Split output into lines and find the default route
                    let lines = output.components(separatedBy: .newlines)
                    if let defaultRoute = lines.first(where: { $0.contains("default") }) {
                        // Split the line and get the gateway address (typically the third non-empty component)
                        let components = defaultRoute.components(separatedBy: .whitespaces)
                            .filter { !$0.isEmpty }
                        
                        if components.count >= 2 {
                            // Gateway address is typically the second non-empty component
                            let gateway = components[1]
                            DispatchQueue.main.async {
                                self?.routerAddress = gateway
                            }
                            return
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self?.routerAddress = "Unknown"
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.routerAddress = "Unknown"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.routerAddress = "Unknown"
                }
            }
        }
    }
}
