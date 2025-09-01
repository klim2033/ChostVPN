import Flutter
import UIKit
import NetworkExtension
import os.log

public class FlutterV2rayPlugin: NSObject, FlutterPlugin {
    
    private let logger = OSLog(subsystem: "com.github.blueboytm.flutter_v2ray", category: "Plugin")
    private var vpnManager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_v2ray", binaryMessenger: registrar.messenger())
        let instance = FlutterV2rayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "initializeV2Ray":
            initializeV2Ray(call: call, result: result)
            
        case "requestPermission":
            requestVPNPermission(result: result)
            
        case "startV2Ray":
            startVPN(call: call, result: result)
            
        case "stopV2Ray":
            stopVPN(result: result)
            
        case "getServerDelay":
            getServerDelay(call: call, result: result)
            
        case "getConnectedServerDelay":
            getConnectedServerDelay(call: call, result: result)
            
        case "getCoreVersion":
            result("iOS-WireGuard-1.0.0")
            
        // WireGuard специфичные методы
        case "startWireGuard":
            startWireGuard(call: call, result: result)
            
        case "stopWireGuard":
            stopWireGuard(result: result)
            
        case "getWireGuardStatus":
            getWireGuardStatus(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - V2Ray Methods
    
    private func initializeV2Ray(call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log("Initializing V2Ray", log: logger, type: .info)
        
        // Настройка VPN менеджера
        setupVPNManager { [weak self] success in
            if success {
                os_log("V2Ray initialized successfully", log: self?.logger ?? OSLog.default, type: .info)
                result(nil)
            } else {
                os_log("Failed to initialize V2Ray", log: self?.logger ?? OSLog.default, type: .error)
                result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize V2Ray", details: nil))
            }
        }
    }
    
    private func requestVPNPermission(result: @escaping FlutterResult) {
        os_log("Requesting VPN permission", log: logger, type: .info)
        
        setupVPNManager { success in
            result(success)
        }
    }
    
    private func startVPN(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let config = args["config"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        os_log("Starting VPN with config", log: logger, type: .info)
        
        // Определяем тип конфигурации
        if isWireGuardConfig(config) {
            startWireGuardVPN(config: config, result: result)
        } else {
            // Для V2Ray конфигураций (пока не поддерживается)
            result(FlutterError(code: "UNSUPPORTED", message: "V2Ray configurations not yet supported on iOS", details: nil))
        }
    }
    
    private func stopVPN(result: @escaping FlutterResult) {
        os_log("Stopping VPN", log: logger, type: .info)
        
        vpnManager?.connection.stopVPNTunnel()
        result(nil)
    }
    
    private func getServerDelay(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Имитация проверки задержки
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let delay = Int.random(in: 50...150)
            result(delay)
        }
    }
    
    private func getConnectedServerDelay(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Имитация проверки задержки подключенного сервера
        if vpnManager?.connection.status == .connected {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                let delay = Int.random(in: 20...80)
                result(delay)
            }
        } else {
            result(-1)
        }
    }
    
    // MARK: - WireGuard Methods
    
    private func startWireGuard(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let config = args["config"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        startWireGuardVPN(config: config, result: result)
    }
    
    private func stopWireGuard(result: @escaping FlutterResult) {
        stopVPN(result: result)
    }
    
    private func getWireGuardStatus(result: @escaping FlutterResult) {
        guard let manager = vpnManager else {
            result(["connected": false])
            return
        }
        
        let status = [
            "connected": manager.connection.status == .connected,
            "connecting": manager.connection.status == .connecting,
            "disconnecting": manager.connection.status == .disconnecting,
            "status": statusToString(manager.connection.status)
        ]
        
        result(status)
    }
    
    // MARK: - Private Methods
    
    private func setupVPNManager(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                os_log("Failed to load VPN managers: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                completion(false)
                return
            }
            
            // Ищем существующий менеджер или создаем новый
            if let existingManager = managers?.first {
                self?.vpnManager = existingManager
                self?.setupStatusObserver()
                completion(true)
            } else {
                self?.createNewVPNManager(completion: completion)
            }
        }
    }
    
    private func createNewVPNManager(completion: @escaping (Bool) -> Void) {
        let manager = NETunnelProviderManager()
        
        // Настройка протокола
        let providerProtocol = NETunnelProviderProtocol()
        providerProtocol.providerBundleIdentifier = "com.github.blueboytm.flutter-v2ray.WireGuardExtension"
        providerProtocol.serverAddress = "WireGuard VPN"
        
        manager.protocolConfiguration = providerProtocol
        manager.localizedDescription = "Flutter V2Ray WireGuard"
        manager.isEnabled = true
        
        // Сохраняем конфигурацию
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                os_log("Failed to save VPN configuration: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                completion(false)
                return
            }
            
            self?.vpnManager = manager
            self?.setupStatusObserver()
            completion(true)
        }
    }
    
    private func setupStatusObserver() {
        guard let manager = vpnManager else { return }
        
        // Удаляем предыдущий наблюдатель
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Добавляем новый наблюдатель
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] _ in
            self?.handleVPNStatusChange()
        }
    }
    
    private func handleVPNStatusChange() {
        guard let manager = vpnManager else { return }
        
        let status = statusToString(manager.connection.status)
        os_log("VPN status changed to: %@", log: logger, type: .info, status)
        
        // Здесь можно отправить событие в Flutter
        // Например, через EventChannel
    }
    
    private func startWireGuardVPN(config: String, result: @escaping FlutterResult) {
        guard let manager = vpnManager,
              let providerProtocol = manager.protocolConfiguration as? NETunnelProviderProtocol else {
            result(FlutterError(code: "NO_MANAGER", message: "VPN manager not initialized", details: nil))
            return
        }
        
        // Передаем конфигурацию в Network Extension
        let configData = config.data(using: .utf8)
        providerProtocol.providerConfiguration = ["config": configData as Any]
        
        // Сохраняем обновленную конфигурацию
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                os_log("Failed to save VPN configuration: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                result(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
                return
            }
            
            // Запускаем VPN
            do {
                try manager.connection.startVPNTunnel(options: ["config": configData as Any])
                result(nil)
            } catch {
                os_log("Failed to start VPN tunnel: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func isWireGuardConfig(_ config: String) -> Bool {
        let lowercaseConfig = config.lowercased()
        return lowercaseConfig.contains("[interface]") &&
               lowercaseConfig.contains("privatekey") &&
               lowercaseConfig.contains("[peer]") &&
               lowercaseConfig.contains("publickey")
    }
    
    private func statusToString(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid:
            return "invalid"
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reasserting:
            return "reasserting"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "unknown"
        }
    }
}
