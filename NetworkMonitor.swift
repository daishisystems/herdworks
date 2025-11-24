//
//  NetworkMonitor.swift
//  HerdWorks
//
//  Created by Code Review on 2025/11/24.
//  Purpose: Monitor network connectivity and provide user feedback per HIG
//

import Foundation
import Network
import SwiftUI
import Combine

/// Monitors network connectivity and publishes status changes
/// Usage: @EnvironmentObject var networkMonitor: NetworkMonitor
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.herdworks.networkmonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        case none
        
        var displayName: String {
            switch self {
            case .wifi: return "network.wifi".localized()
            case .cellular: return "network.cellular".localized()
            case .ethernet: return "network.ethernet".localized()
            case .unknown: return "network.unknown".localized()
            case .none: return "network.none".localized()
            }
        }
        
        var iconName: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            case .none: return "wifi.slash"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.status == .satisfied {
                    self.connectionType = .unknown
                } else {
                    self.connectionType = .none
                }
                
                #if DEBUG
                print("📡 Network status: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionType.displayName)")
                #endif
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds a network connectivity banner that appears when offline
    /// - Parameter monitor: NetworkMonitor instance (typically from @EnvironmentObject)
    /// - Returns: View with offline banner
    func networkBanner(_ monitor: NetworkMonitor) -> some View {
        self.safeAreaInset(edge: .top, spacing: 0) {
            if !monitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.callout)
                    
                    Text("network.offline_banner".localized())
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("network.offline_mode".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.9))
                .foregroundColor(.white)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: monitor.isConnected)
    }
    
    /// Shows a subtle offline indicator in toolbar
    /// - Parameter monitor: NetworkMonitor instance
    /// - Returns: Toolbar item showing connectivity
    func networkStatusToolbarItem(_ monitor: NetworkMonitor) -> some ToolbarContent {
        ToolbarItem(placement: .status) {
            if !monitor.isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("network.offline".localized())
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Error Handling Extension

extension Error {
    /// Determines if this error is due to network connectivity
    var isNetworkError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut)
    }
    
    /// Returns a user-friendly message considering network status
    func userMessage(isConnected: Bool) -> String {
        if !isConnected {
            return "error.check_connection".localized()
        } else if isNetworkError {
            return "error.network_timeout".localized()
        } else {
            return localizedDescription
        }
    }
}
