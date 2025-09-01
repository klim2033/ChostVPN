import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_key.dart';

class VpnService {
  static FlutterV2ray? _flutterV2ray;
  static final ValueNotifier<V2RayStatus> statusNotifier = ValueNotifier(V2RayStatus());
  static final ValueNotifier<bool> isConnecting = ValueNotifier(false);
  
  static bool get isIOS => Platform.isIOS;
  
  static Future<void> init() async {
    // На iOS плагин не поддерживается, используем заглушку
    if (isIOS) {
      debugPrint('VPN не поддерживается на iOS');
      return;
    }
    
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
  
  static Future<bool> connect(VpnKey vpnKey) async {
    if (isIOS) {
      debugPrint('VPN не поддерживается на iOS');
      return false;
    }
    
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
      debugPrint('Ошибка подключения: $e');
      return false;
    }
  }
  
  static Future<void> disconnect() async {
    if (isIOS || _flutterV2ray == null) return;
    
    isConnecting.value = true;
    await _flutterV2ray!.stopV2Ray();
  }
  
  static bool get isConnected => statusNotifier.value.state == "CONNECTED";
  
  static Future<int> getServerDelay(String config) async {
    if (isIOS) return -1;
    
    if (_flutterV2ray == null) await init();
    
    try {
      return await _flutterV2ray!.getServerDelay(config: config);
    } catch (e) {
      return -1;
    }
  }
}
