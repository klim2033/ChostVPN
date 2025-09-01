import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_key.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const String _keysKey = 'vpn_keys';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<List<VpnKey>> getKeys() async {
    final String? keysJson = _prefs.getString(_keysKey);
    if (keysJson == null) return [];
    
    final List<dynamic> keysList = json.decode(keysJson);
    return keysList.map((json) => VpnKey.fromJson(json)).toList();
  }

  static Future<void> saveKeys(List<VpnKey> keys) async {
    final String keysJson = json.encode(keys.map((key) => key.toJson()).toList());
    await _prefs.setString(_keysKey, keysJson);
  }

  static Future<void> addKey(VpnKey key) async {
    final keys = await getKeys();
    keys.add(key);
    await saveKeys(keys);
  }

  static Future<void> removeKey(String id) async {
    final keys = await getKeys();
    keys.removeWhere((key) => key.id == id);
    await saveKeys(keys);
  }

  static Future<void> setActiveKey(String id) async {
    final keys = await getKeys();
    final updatedKeys = keys.map((key) {
      return key.copyWith(isActive: key.id == id);
    }).toList();
    await saveKeys(updatedKeys);
  }

  static Future<VpnKey?> getActiveKey() async {
    final keys = await getKeys();
    try {
      return keys.firstWhere((key) => key.isActive);
    } catch (e) {
      return null;
    }
  }
}
