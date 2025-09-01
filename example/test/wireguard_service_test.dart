import 'package:flutter_test/flutter_test.dart';
import '../lib/services/wireguard_vpn_service.dart';
import '../lib/models/vpn_key.dart';

void main() {
  group('WireGuardVpnService Tests', () {
    late WireGuardVpnService service;
    
    setUp(() {
      service = WireGuardVpnService();
    });
    
    tearDown(() {
      service.dispose();
    });
    
    test('должен инициализироваться корректно', () async {
      await service.init();
      
      expect(service.isConnected, false);
      expect(service.statusNotifier.value.state, "DISCONNECTED");
    });
    
    test('должен валидировать WireGuard конфигурацию', () {
      const validConfig = '''
[Interface]
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=
Address = 10.13.13.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=
Endpoint = 188.114.97.3:51820
AllowedIPs = 0.0.0.0/0
''';
      
      const invalidConfig = '''
[Interface]
Address = 10.13.13.2/32
DNS = 1.1.1.1
''';
      
      expect(service.isValidWireGuardConfig(validConfig), true);
      expect(service.isValidWireGuardConfig(invalidConfig), false);
    });
    
    test('должен парсить WireGuard конфигурацию', () {
      const config = '''
[Interface]
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=
Address = 10.13.13.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=
Endpoint = 188.114.97.3:51820
AllowedIPs = 0.0.0.0/0
''';
      
      final parsed = service.parseWireGuardConfig(config);
      
      expect(parsed['PrivateKey'], 'yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=');
      expect(parsed['Address'], '10.13.13.2/32');
      expect(parsed['DNS'], '1.1.1.1');
      expect(parsed['PublicKey'], 'xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=');
      expect(parsed['Endpoint'], '188.114.97.3:51820');
      expect(parsed['AllowedIPs'], '0.0.0.0/0');
    });
    
    test('должен подключаться с валидной конфигурацией', () async {
      await service.init();
      
      const validConfig = '''
[Interface]
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=
Address = 10.13.13.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=
Endpoint = 188.114.97.3:51820
AllowedIPs = 0.0.0.0/0
''';
      
      final vpnKey = VpnKey(
        id: 'test-1',
        key: validConfig,
        remark: 'Test WireGuard',
        addedDate: DateTime.now(),
        protocol: VpnProtocol.wireguard,
      );
      
      final connected = await service.connect(vpnKey);
      
      expect(connected, true);
      expect(service.isConnected, true);
      expect(service.statusNotifier.value.state, "CONNECTED");
      
      // Отключаемся
      await service.disconnect();
      expect(service.isConnected, false);
      expect(service.statusNotifier.value.state, "DISCONNECTED");
    });
    
    test('должен отклонять невалидную конфигурацию', () async {
      await service.init();
      
      const invalidConfig = '''
[Interface]
Address = 10.13.13.2/32
DNS = 1.1.1.1
''';
      
      final vpnKey = VpnKey(
        id: 'test-2',
        key: invalidConfig,
        remark: 'Invalid Config',
        addedDate: DateTime.now(),
        protocol: VpnProtocol.wireguard,
      );
      
      final connected = await service.connect(vpnKey);
      
      expect(connected, false);
      expect(service.isConnected, false);
    });
    
    test('должен возвращать задержку сервера', () async {
      const config = '''
[Interface]
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=
Address = 10.13.13.2/32

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=
Endpoint = 188.114.97.3:51820
AllowedIPs = 0.0.0.0/0
''';
      
      final delay = await service.getServerDelay(config);
      
      expect(delay, greaterThanOrEqualTo(50));
      expect(delay, lessThanOrEqualTo(150));
    });
  });
} 