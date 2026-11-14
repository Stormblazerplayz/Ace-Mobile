import Foundation
import Network
import os
import UIKit

/// Reads what an iPad app is allowed to see about the iPad: battery, storage,
/// memory, heat, Low Power Mode, network and how long it has been on.
/// (iPadOS doesn't let apps see other apps or their notifications.)
@MainActor
final class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    struct Snapshot {
        var batteryLevel: Float?        // 0...1, nil if unknown
        var batteryState: UIDevice.BatteryState
        var lowPower: Bool
        var thermal: ProcessInfo.ThermalState
        var freeBytes: Int64?
        var totalBytes: Int64?
        var appMemoryBytes: UInt64
        var deviceMemoryBytes: UInt64
        var availableMemoryBytes: UInt64
        var uptime: TimeInterval
        var online: Bool
        var onWiFi: Bool
        var expensiveNetwork: Bool
    }

    @Published private(set) var online = true
    @Published private(set) var onWiFi = true
    @Published private(set) var expensive = false
    private let monitor = NWPathMonitor()

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        monitor.pathUpdateHandler = { path in
            let ok = path.status == .satisfied
            let wifi = path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)
            let exp = path.isExpensive
            Task { @MainActor in
                SystemMonitor.shared.online = ok
                SystemMonitor.shared.onWiFi = wifi
                SystemMonitor.shared.expensive = exp
            }
        }
        monitor.start(queue: DispatchQueue(label: "ace.network"))
    }

    func snapshot() -> Snapshot {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        var free: Int64?
        var total: Int64?
        let home = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) {
            free = values.volumeAvailableCapacityForImportantUsage
            if let t = values.volumeTotalCapacity { total = Int64(t) }
        }
        return Snapshot(
            batteryLevel: level < 0 ? nil : level,
            batteryState: device.batteryState,
            lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermal: ProcessInfo.processInfo.thermalState,
            freeBytes: free,
            totalBytes: total,
            appMemoryBytes: Self.appMemory(),
            deviceMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            availableMemoryBytes: UInt64(os_proc_available_memory()),
            uptime: ProcessInfo.processInfo.systemUptime,
            online: online,
            onWiFi: onWiFi,
            expensiveNetwork: expensive
        )
    }

    /// How much memory Ace itself is using.
    static func appMemory() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
    }

    static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    static func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: value), countStyle: .memory)
    }

    static func thermalText(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: return "cool"
        case .fair: return "a little warm"
        case .serious: return "hot"
        case .critical: return "very hot"
        @unknown default: return "normal"
        }
    }
}
