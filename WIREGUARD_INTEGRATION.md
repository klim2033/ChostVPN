# Интеграция WireGuard в Flutter V2Ray

Данный документ описывает интеграцию поддержки WireGuard VPN в Flutter V2Ray плагин.

## Обзор изменений

### 1. Dart/Flutter уровень
- ✅ **WireGuardVpnService**: Обновленный сервис для работы с WireGuard конфигурациями
- ✅ **VpnKey модель**: Добавлена поддержка автоматического определения протокола (V2Ray/WireGuard)
- ✅ **Тестирование**: Полный набор unit-тестов для WireGuard функциональности

### 2. iOS уровень (NetworkExtension)
- ✅ **WireGuardNetworkExtension**: Network Extension для обработки WireGuard туннелей
- ✅ **FlutterV2rayPlugin**: Обновленный iOS плагин с поддержкой VPN API
- ✅ **Entitlements**: Настроенные разрешения для VPN функциональности
- ✅ **Podspec**: Обновленная спецификация с NetworkExtension поддержкой

### 3. Конфигурация
- ✅ **Runner.entitlements**: VPN разрешения для основного приложения
- ✅ **WireGuardExtension.entitlements**: Разрешения для Network Extension
- ✅ **Info.plist**: Конфигурация Network Extension

## Архитектура

```
┌─────────────────────┐
│   Flutter App       │
│  (WireGuardVpnService) │
└─────────┬───────────┘
          │ Method Channel
          ▼
┌─────────────────────┐
│ FlutterV2rayPlugin  │
│     (iOS Swift)     │
└─────────┬───────────┘
          │ NetworkExtension API
          ▼
┌─────────────────────┐
│WireGuardNetworkExt  │
│  (Packet Tunnel)    │
└─────────────────────┘
```

## Использование

### 1. Создание WireGuard ключа
```dart
final vpnKey = VpnKey(
  id: 'wg-key-1',
  key: '''
[Interface]
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=
Address = 10.13.13.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjS4PdMpwrPdGUfGN0=
Endpoint = 188.114.97.3:51820
AllowedIPs = 0.0.0.0/0
''',
  remark: 'My WireGuard Server',
  addedDate: DateTime.now(),
  protocol: VpnProtocol.wireguard,
);
```

### 2. Инициализация и подключение
```dart
final wireGuardService = WireGuardVpnService();

// Инициализация
await wireGuardService.init();

// Подключение
final success = await wireGuardService.connect(vpnKey);
if (success) {
  print('WireGuard подключен успешно');
}

// Отслеживание статуса
wireGuardService.statusNotifier.addListener(() {
  final status = wireGuardService.statusNotifier.value;
  print('Статус: ${status.state}');
  print('Скорость загрузки: ${status.downloadSpeed} КБ/с');
});
```

### 3. Отключение
```dart
await wireGuardService.disconnect();
```

## Настройка iOS проекта

Для полной функциональности на iOS требуется:

1. **Apple Developer Account** с поддержкой Network Extensions
2. **Настройка App IDs** в Apple Developer Console
3. **Provisioning Profiles** для приложения и Network Extension
4. **Добавление Network Extension target** в Xcode

Подробные инструкции см. в [iOS_SETUP.md](iOS_SETUP.md)

## Тестирование

Запуск тестов:
```bash
cd example
flutter test test/wireguard_service_test.dart
```

Все тесты должны пройти успешно:
- ✅ Инициализация сервиса
- ✅ Валидация WireGuard конфигураций
- ✅ Парсинг конфигураций
- ✅ Подключение/отключение
- ✅ Проверка задержки сервера

## Ограничения

### Текущие ограничения
1. **iOS симулятор**: Network Extensions не работают в симуляторе
2. **Реальная криптография**: Требуется интеграция с WireGuardKit для полной функциональности
3. **Android**: Требуется аналогичная реализация с VpnService

### Рекомендации для production
1. Интегрировать официальную библиотеку WireGuardKit
2. Добавить реальную криптографию WireGuard
3. Реализовать статистику трафика из Network Extension
4. Добавить обработку ошибок подключения
5. Реализовать переподключение при сбоях

## Безопасность

- ✅ Используются App Groups для безопасного обмена данными
- ✅ Конфигурации могут храниться в Keychain
- ✅ Network Extension изолирован от основного приложения
- ⚠️ Требуется аудит безопасности перед production использованием

## Дальнейшее развитие

1. **Android поддержка**: Реализация аналогичной функциональности для Android
2. **WireGuardKit интеграция**: Использование официальной библиотеки
3. **Статистика**: Реальная статистика трафика и подключения
4. **Настройки**: Дополнительные настройки WireGuard (MTU, Keep-Alive и т.д.)
5. **Множественные peers**: Поддержка нескольких peer'ов в одной конфигурации

---

**Статус**: ✅ Базовая функциональность реализована  
**Тестирование**: ✅ Unit-тесты пройдены  
**iOS готовность**: ⚠️ Требуется настройка Apple Developer Account  
**Production готовность**: ⚠️ Требуется дополнительная работа по безопасности 