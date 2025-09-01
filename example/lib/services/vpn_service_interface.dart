import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_key.dart';

abstract class VpnServiceInterface {
  ValueNotifier<V2RayStatus> get statusNotifier;
  ValueNotifier<bool> get isConnecting;
  
  Future<void> init();
  Future<bool> connect(VpnKey vpnKey);
  Future<void> disconnect();
  bool get isConnected;
  Future<int> getServerDelay(String config);
}
