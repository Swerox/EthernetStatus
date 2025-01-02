//
//  EthernetStatusApp.swift
//  EthernetStatus
//
//  Created by Dominik on 01.01.25.
//

import SwiftUI
import SwiftData
import Cocoa
import LaunchAtLogin
import AppKit

@main
struct EthernetStatusApp: App {
    @StateObject private var viewModel = NetworkStatusViewModel()
    @State private var copiedMessage = ""
    @AppStorage("autoStartEnabled") private var autoStartEnabled: Bool = false
    
    init() {
        autoStartEnabled = LaunchAtLogin.isEnabled
    }
    
    var body: some Scene {
        MenuBarExtra("Utility App", image: viewModel.isLANConnected ? "connected" : "disconnected") {
            VStack {
                Text("Netzwerkstatus:")
                    .font(.headline)
                Text(viewModel.isLANConnected ? "Ethernet connected" : "Ethernet not connected")
                    .foregroundColor(viewModel.isLANConnected ? .green : .red)
                    .padding()
                
                Divider()
                
                Text("Network Adresses")
                    .foregroundColor(Color(.darkGray))
                    .font(.headline)
                
                HStack {
                    Text("IPv4 Address: ")
                        .foregroundColor(.gray)
                    Button(action: {
                        copyToClipboard(text: viewModel.ipv4Address)
                        showCopiedMessage("IPv4 copied successfully!")
                    }) {
                        Text(viewModel.ipv4Address)
                            .foregroundColor(viewModel.ipv4Address == "Unknown" ? .red : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.ipv4Address == "Unknown")
                }
                
                HStack {
                    Text("IPv6 Address: ")
                        .foregroundColor(.gray)
                    Button(action: {
                        copyToClipboard(text: viewModel.ipv6Address)
                        showCopiedMessage("IPv6 copied successfully!")
                    }) {
                        Text(viewModel.ipv6Address)
                            .foregroundColor(viewModel.ipv6Address == "Unknown" ? .red : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.ipv6Address == "Unknown")
                }
                
                HStack {
                    Text("Router Address: ")
                        .foregroundColor(.gray)
                    Button(action: {
                        copyToClipboard(text: viewModel.routerAddress)
                        showCopiedMessage("Router address copied successfully!")
                    }) {
                        Text(viewModel.routerAddress)
                            .foregroundColor(viewModel.ipv6Address == "Unknown" ? .red : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.ipv6Address == "Unknown")
                }
                
                if !copiedMessage.isEmpty {
                    Text(copiedMessage)
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.top, 5)
                }
                
                Divider()
                
                Text("Options")
                    .foregroundColor(Color(.darkGray))
                    .font(.headline)
                
                Button(action: {
                    toggleAutoStart()
                }) {
                    Text(autoStartEnabled ? "Launch at login is active ✅" : "Launch at login inactive ❌")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 5)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .padding(.top)
            }
            .frame(width: 250)
        }
    }
    
    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func showCopiedMessage(_ message: String) {
        copiedMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedMessage = ""
        }
    }
    func toggleAutoStart() {
        if LaunchAtLogin.isEnabled {
            LaunchAtLogin.isEnabled = false
            autoStartEnabled = LaunchAtLogin.isEnabled
            
        } else {
            LaunchAtLogin.isEnabled = true
            autoStartEnabled = LaunchAtLogin.isEnabled
        }
        
    }
}
