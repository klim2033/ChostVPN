# Настройка iOS для поддержки WireGuard VPN

Данное руководство описывает шаги, необходимые для настройки iOS приложения с поддержкой WireGuard VPN через NetworkExtension.

## Требования

- iOS 12.0 или выше
- Xcode 12.0 или выше
- Активная учетная запись Apple Developer
- Поддержка Network Extensions в вашем Apple Developer аккаунте

## 1. Настройка Apple Developer Account

### 1.1 Создание App ID
1. Войдите в [Apple Developer Console](https://developer.apple.com/account/)
2. Перейдите в **Certificates, Identifiers & Profiles** → **Identifiers**
3. Создайте новый App ID для основного приложения:
   - Bundle ID: `com.github.blueboytm.flutter-v2ray`
   - Включите capabilities:
     - **Network Extensions**
     - **App Groups**

### 1.2 Создание App ID для Network Extension
1. Создайте еще один App ID для Network Extension:
   - Bundle ID: `com.github.blueboytm.flutter-v2ray.WireGuardExtension`
   - Включите capabilities:
     - **Network Extensions**
     - **App Groups**

### 1.3 Настройка App Groups
1. Перейдите в **Identifiers** → **App Groups**
2. Создайте новую группу:
   - Identifier: `group.com.github.blueboytm.flutter-v2ray`
   - Description: `Flutter V2Ray App Group`

### 1.4 Создание Provisioning Profiles
Создайте два provisioning profile:
1. Для основного приложения
2. Для Network Extension

## 2. Настройка Xcode проекта

### 2.1 Добавление Network Extension Target
1. Откройте проект в Xcode
2. File → New → Target
3. Выберите **Network Extension**
4. Выберите **Packet Tunnel Provider**
5. Настройте:
   - Product Name: `WireGuardExtension`
   - Bundle Identifier: `com.github.blueboytm.flutter-v2ray.WireGuardExtension`

### 2.2 Настройка Capabilities для основного приложения
1. Выберите основной target
2. Перейдите на вкладку **Signing & Capabilities**
3. Добавьте capabilities:
   - **Network Extensions**
   - **App Groups** (выберите созданную группу)
   - **Personal VPN** (если требуется)

### 2.3 Настройка Capabilities для Network Extension
1. Выберите Network Extension target
2. Перейдите на вкладку **Signing & Capabilities**
3. Добавьте capabilities:
   - **Network Extensions**
   - **App Groups** (ту же группу)

### 2.4 Обновление Info.plist основного приложения
Добавьте в `Info.plist` основного приложения:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 3. Файловая структура

После настройки у вас должна быть следующая структура:

```
ios/
├── Classes/
│   ├── FlutterV2rayPlugin.swift          # Основной плагин
│   └── WireGuardNetworkExtension.swift   # Network Extension
├── WireGuardExtension/
│   ├── Info.plist                        # Конфигурация расширения
│   └── WireGuardExtension.entitlements   # Разрешения расширения
├── Runner/
│   ├── Runner.entitlements               # Разрешения основного приложения
│   └── Info.plist                        # Конфигурация приложения
└── flutter_v2ray.podspec                # Pod спецификация
```

## 4. Интеграция с WireGuard

### 4.1 Опция 1: Использование WireGuardKit (Рекомендуется)
Добавьте в `podspec`:
```ruby
s.dependency 'WireGuardKit', '~> 1.0'
```

### 4.2 Опция 2: Собственная реализация
Используйте созданные файлы `WireGuardNetworkExtension.swift` как основу.

## 5. Тестирование

### 5.1 Проверка в симуляторе
⚠️ **Важно**: Network Extensions не работают в симуляторе iOS. Тестирование возможно только на физическом устройстве.

### 5.2 Тестирование на устройстве
1. Подключите физическое iOS устройство
2. Убедитесь, что устройство добавлено в provisioning profile
3. Запустите приложение
4. Проверьте логи в Console.app для отладки

## 6. Отладка

### 6.1 Логирование
Используйте `os_log` для логирования:
```swift
import os.log

private let logger = OSLog(subsystem: "com.github.blueboytm.flutter_v2ray", category: "WireGuard")
os_log("Message", log: logger, type: .info)
```

### 6.2 Проверка статуса VPN
```swift
let manager = NETunnelProviderManager()
print("VPN Status: \(manager.connection.status)")
```

### 6.3 Общие проблемы

#### Проблема: "No VPN configuration found"
**Решение**: Убедитесь, что provisioning profiles настроены правильно и включают Network Extensions capability.

#### Проблема: "Failed to start tunnel"
**Решение**: 
1. Проверьте entitlements файлы
2. Убедитесь, что Bundle IDs совпадают с зарегистрированными в Apple Developer Console
3. Проверьте, что App Groups настроены одинаково для обеих targets

#### Проблема: Network Extension не запускается
**Решение**:
1. Проверьте, что NSExtensionPrincipalClass указывает на правильный класс
2. Убедитесь, что класс наследует от NEPacketTunnelProvider
3. Проверьте логи системы в Console.app

## 7. Развертывание

### 7.1 App Store Connect
1. Загрузите приложение через Xcode или Application Loader
2. Убедитесь, что оба targets (приложение и расширение) включены в архив
3. В App Store Connect укажите, что приложение использует VPN

### 7.2 Описание для App Store
Обязательно укажите в описании приложения:
- Что приложение использует VPN функциональность
- Для каких целей используется VPN
- Что данные пользователей обрабатываются в соответствии с политикой конфиденциальности

## 8. Дополнительные ресурсы

- [Apple Developer Documentation - Network Extensions](https://developer.apple.com/documentation/networkextension)
- [WireGuard iOS Implementation](https://git.zx2c4.com/wireguard-ios/)
- [WWDC Sessions on Network Extensions](https://developer.apple.com/videos/play/wwdc2015/717/)

## 9. Поддержка

Если у вас возникли проблемы:
1. Проверьте системные логи в Console.app
2. Убедитесь, что все certificates и provisioning profiles актуальны
3. Проверьте, что capabilities настроены правильно в Apple Developer Console

---

**Примечание**: Данная реализация предоставляет базовую функциональность WireGuard VPN. Для производственного использования рекомендуется интегрировать официальную библиотеку WireGuardKit и провести дополнительное тестирование безопасности. 