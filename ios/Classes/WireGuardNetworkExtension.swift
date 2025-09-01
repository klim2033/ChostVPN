import NetworkExtension
import os.log

/// Network Extension для WireGuard VPN
/// Этот класс отвечает за установку и управление VPN-туннелем
class WireGuardNetworkExtension: NEPacketTunnelProvider {
    
    private let logger = OSLog(subsystem: "com.github.blueboytm.flutter_v2ray", category: "WireGuard")
    private var wireguardHandle: Int32 = -1
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("Starting WireGuard tunnel", log: logger, type: .info)
        
        guard let options = options,
              let configData = options["config"] as? Data else {
            os_log("No config data provided", log: logger, type: .error)
            completionHandler(WireGuardError.noConfiguration)
            return
        }
        
        do {
            // Парсим WireGuard конфигурацию
            let configString = String(data: configData, encoding: .utf8) ?? ""
            let config = try parseWireGuardConfig(configString)
            
            // Настраиваем сетевые параметры
            let tunnelNetworkSettings = createNetworkSettings(from: config)
            
            // Применяем настройки туннеля
            setTunnelNetworkSettings(tunnelNetworkSettings) { [weak self] error in
                if let error = error {
                    os_log("Failed to set tunnel network settings: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                    completionHandler(error)
                    return
                }
                
                // Запускаем WireGuard туннель
                self?.startWireGuardTunnel(config: config, completionHandler: completionHandler)
            }
            
        } catch {
            os_log("Failed to start tunnel: %@", log: logger, type: .error, error.localizedDescription)
            completionHandler(error)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("Stopping WireGuard tunnel with reason: %d", log: logger, type: .info, reason.rawValue)
        
        // Останавливаем WireGuard туннель
        if wireguardHandle >= 0 {
            // В реальной реализации здесь был бы вызов WireGuard API
            // wg_turn_off(wireguardHandle)
            wireguardHandle = -1
        }
        
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Обработка сообщений от основного приложения
        if let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
           let command = message["command"] as? String {
            
            switch command {
            case "getStatus":
                let status = getCurrentStatus()
                if let statusData = try? JSONSerialization.data(withJSONObject: status) {
                    completionHandler?(statusData)
                } else {
                    completionHandler?(nil)
                }
            default:
                completionHandler?(nil)
            }
        } else {
            completionHandler?(nil)
        }
    }
    
    // MARK: - Private Methods
    
    private func parseWireGuardConfig(_ configString: String) throws -> WireGuardConfig {
        let lines = configString.components(separatedBy: .newlines)
        var interfaceConfig = WireGuardInterface()
        var peerConfig = WireGuardPeer()
        var currentSection = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                currentSection = String(trimmedLine.dropFirst().dropLast()).lowercased()
                continue
            }
            
            let components = trimmedLine.components(separatedBy: "=")
            guard components.count == 2 else { continue }
            
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1].trimmingCharacters(in: .whitespaces)
            
            switch currentSection {
            case "interface":
                switch key.lowercased() {
                case "privatekey":
                    interfaceConfig.privateKey = value
                case "address":
                    interfaceConfig.address = value
                case "dns":
                    interfaceConfig.dns = value
                default:
                    break
                }
            case "peer":
                switch key.lowercased() {
                case "publickey":
                    peerConfig.publicKey = value
                case "endpoint":
                    peerConfig.endpoint = value
                case "allowedips":
                    peerConfig.allowedIPs = value
                case "persistentkeepalive":
                    peerConfig.persistentKeepalive = Int(value)
                default:
                    break
                }
            default:
                break
            }
        }
        
        guard !interfaceConfig.privateKey.isEmpty,
              !peerConfig.publicKey.isEmpty,
              !peerConfig.endpoint.isEmpty else {
            throw WireGuardError.invalidConfiguration
        }
        
        return WireGuardConfig(interface: interfaceConfig, peer: peerConfig)
    }
    
    private func createNetworkSettings(from config: WireGuardConfig) -> NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: extractHost(from: config.peer.endpoint))
        
        // Настройка IP адреса
        let ipv4Settings = NEIPv4Settings(addresses: [extractIPAddress(from: config.interface.address)],
                                          subnetMasks: [extractSubnetMask(from: config.interface.address)])
        networkSettings.ipv4Settings = ipv4Settings
        
        // Настройка DNS
        if !config.interface.dns.isEmpty {
            let dnsSettings = NEDNSSettings(servers: config.interface.dns.components(separatedBy: ","))
            networkSettings.dnsSettings = dnsSettings
        }
        
        // Настройка маршрутизации
        let allowedIPs = config.peer.allowedIPs.components(separatedBy: ",")
        var routes: [NEIPv4Route] = []
        
        for allowedIP in allowedIPs {
            let trimmed = allowedIP.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("/") {
                let components = trimmed.components(separatedBy: "/")
                if components.count == 2,
                   let prefixLength = Int(components[1]) {
                    let route = NEIPv4Route(destinationAddress: components[0],
                                          subnetMask: subnetMaskFromPrefixLength(prefixLength))
                    routes.append(route)
                }
            }
        }
        
        ipv4Settings.includedRoutes = routes
        
        return networkSettings
    }
    
    private func startWireGuardTunnel(config: WireGuardConfig, completionHandler: @escaping (Error?) -> Void) {
        // В реальной реализации здесь был бы вызов WireGuard библиотеки
        // Например, используя WireGuardKit или аналогичную библиотеку
        
        // Для демонстрации просто имитируем успешный запуск
        DispatchQueue.global().async { [weak self] in
            // Имитация инициализации WireGuard
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                self?.wireguardHandle = 1 // Имитация handle
                os_log("WireGuard tunnel started successfully", log: self?.logger ?? OSLog.default, type: .info)
                completionHandler(nil)
            }
        }
    }
    
    private func getCurrentStatus() -> [String: Any] {
        return [
            "connected": wireguardHandle >= 0,
            "bytesReceived": 0, // В реальной реализации получать из WireGuard
            "bytesSent": 0,
            "lastHandshake": Date().timeIntervalSince1970
        ]
    }
    
    // MARK: - Helper Methods
    
    private func extractHost(from endpoint: String) -> String {
        return endpoint.components(separatedBy: ":").first ?? "127.0.0.1"
    }
    
    private func extractIPAddress(from address: String) -> String {
        return address.components(separatedBy: "/").first ?? "10.0.0.1"
    }
    
    private func extractSubnetMask(from address: String) -> String {
        let components = address.components(separatedBy: "/")
        if components.count == 2, let prefixLength = Int(components[1]) {
            return subnetMaskFromPrefixLength(prefixLength)
        }
        return "255.255.255.0"
    }
    
    private func subnetMaskFromPrefixLength(_ prefixLength: Int) -> String {
        let mask = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF
        return String(format: "%d.%d.%d.%d",
                     (mask >> 24) & 0xFF,
                     (mask >> 16) & 0xFF,
                     (mask >> 8) & 0xFF,
                     mask & 0xFF)
    }
}

// MARK: - Data Structures

struct WireGuardConfig {
    let interface: WireGuardInterface
    let peer: WireGuardPeer
}

struct WireGuardInterface {
    var privateKey: String = ""
    var address: String = ""
    var dns: String = ""
}

struct WireGuardPeer {
    var publicKey: String = ""
    var endpoint: String = ""
    var allowedIPs: String = ""
    var persistentKeepalive: Int? = nil
}

// MARK: - Error Types

enum WireGuardError: Error, LocalizedError {
    case noConfiguration
    case invalidConfiguration
    case tunnelStartFailed
    
    var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "No WireGuard configuration provided"
        case .invalidConfiguration:
            return "Invalid WireGuard configuration"
        case .tunnelStartFailed:
            return "Failed to start WireGuard tunnel"
        }
    }
} 