import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_key.dart';
import 'vpn_service_interface.dart';

class V2RayVpnService implements VpnServiceInterface {
  FlutterV2ray? _flutterV2ray;
  
  @override
  final ValueNotifier<V2RayStatus> statusNotifier = ValueNotifier(V2RayStatus());
  
  @override
  final ValueNotifier<bool> isConnecting = ValueNotifier(false);
  
  @override
  Future<void> init() async {
    _flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        statusNotifier.value = status;
        if (status.state == "CONNECTED" || status.state == "DISCONNECTED") {
          isConnecting.value = false;
        }
      },
    );
    
    await _flutterV2ray!.initializeV2Ray(
      notificationIconResourceType: "mipmap",
      notificationIconResourceName: "ic_launcher",
    );
  }
  
  @override
  Future<bool> connect(VpnKey vpnKey) async {
    if (_flutterV2ray == null) await init();
    
    try {
      isConnecting.value = true;
      
      // Парсим V2Ray URL
      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(vpnKey.key);
      
      // Запрашиваем разрешение
      if (!await _flutterV2ray!.requestPermission()) {
        isConnecting.value = false;
        return false;
      }
      
      // Запускаем VPN
      await _flutterV2ray!.startV2Ray(
        remark: vpnKey.remark,
        config: v2rayURL.getFullConfiguration(),
        proxyOnly: false,
        notificationDisconnectButtonName: "ОТКЛЮЧИТЬ",
      );
      
      return true;
    } catch (e) {
      isConnecting.value = false;
      debugPrint('Ошибка подключения V2Ray: $e');
      return false;
    }
  }
  
  @override
  Future<void> disconnect() async {
    if (_flutterV2ray == null) return;
    
    isConnecting.value = true;
    await _flutterV2ray!.stopV2Ray();
  }
  
  @override
  bool get isConnected => statusNotifier.value.state == "CONNECTED";
  
  @override
  Future<int> getServerDelay(String config) async {
    if (_flutterV2ray == null) await init();
    
    try {
      return await _flutterV2ray!.getServerDelay(config: config);
    } catch (e) {
      return -1;
    }
  }
}
