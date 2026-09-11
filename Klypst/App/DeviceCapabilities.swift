import Foundation

enum DeviceCapabilities {
    /// Whether this iPhone has an Action Button. There is no API for it, so this reads the
    /// model identifier: iPhone 15 Pro and Pro Max (iPhone16,1 / 16,2), then every model
    /// from the iPhone 16 family (iPhone17,x) onward, including the 16e. Used only to pick
    /// which trigger to recommend; every trigger stays available.
    static let hasActionButton: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        var info = utsname()
        uname(&info)
        let identifier = withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        guard identifier.hasPrefix("iPhone") else { return false }
        let parts = identifier.dropFirst("iPhone".count).split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return false }
        if parts[0] >= 17 { return true }
        return parts[0] == 16 && (parts[1] == 1 || parts[1] == 2)
        #endif
    }()
}
