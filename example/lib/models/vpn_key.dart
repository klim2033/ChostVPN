enum VpnProtocol { v2ray, wireguard }

class VpnKey {
  final String id;
  final String key;
  final String remark;
  final DateTime addedDate;
  final bool isActive;
  final VpnProtocol protocol;

  VpnKey({
    required this.id,
    required this.key,
    required this.remark,
    required this.addedDate,
    this.isActive = false,
    required this.protocol,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'remark': remark,
      'addedDate': addedDate.toIso8601String(),
      'isActive': isActive,
      'protocol': protocol.name,
    };
  }

  factory VpnKey.fromJson(Map<String, dynamic> json) {
    return VpnKey(
      id: json['id'],
      key: json['key'],
      remark: json['remark'],
      addedDate: DateTime.parse(json['addedDate']),
      isActive: json['isActive'] ?? false,
      protocol: VpnProtocol.values.firstWhere(
        (e) => e.name == json['protocol'],
        orElse: () => VpnProtocol.v2ray,
      ),
    );
  }

  VpnKey copyWith({
    String? id,
    String? key,
    String? remark,
    DateTime? addedDate,
    bool? isActive,
    VpnProtocol? protocol,
  }) {
    return VpnKey(
      id: id ?? this.id,
      key: key ?? this.key,
      remark: remark ?? this.remark,
      addedDate: addedDate ?? this.addedDate,
      isActive: isActive ?? this.isActive,
      protocol: protocol ?? this.protocol,
    );
  }

  // Определяем тип протокола по ключу
  static VpnProtocol detectProtocol(String key) {
    final lowerKey = key.toLowerCase().trim();
    
    // V2Ray протоколы
    if (lowerKey.startsWith('vmess://') || 
        lowerKey.startsWith('vless://') || 
        lowerKey.startsWith('trojan://') || 
        lowerKey.startsWith('ss://') || 
        lowerKey.startsWith('socks://')) {
      return VpnProtocol.v2ray;
    }
    
    // WireGuard конфигурация (обычно начинается с [Interface] или содержит PrivateKey)
    if (lowerKey.contains('[interface]') || 
        lowerKey.contains('privatekey') ||
        lowerKey.contains('publickey')) {
      return VpnProtocol.wireguard;
    }
    
    // По умолчанию считаем V2Ray
    return VpnProtocol.v2ray;
  }
}
