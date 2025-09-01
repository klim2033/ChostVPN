# Настройка иконки приложения GhostGram

## Шаги для установки иконки:

### 1. Подготовка изображения
1. Скопируйте файл `@2025-08-31 12.23.04.jpg` в папку `assets/images/`
2. Переименуйте его в `app_icon.png` (конвертируйте в PNG если необходимо)

### 2. Автоматическая генерация иконок
Добавьте в `pubspec.yaml` в секцию `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

Затем добавьте конфигурацию иконки в `pubspec.yaml`:

```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#2D3A4B"
  adaptive_icon_foreground: "assets/images/app_icon.png"
```

### 3. Генерация иконок
Выполните команды:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### 4. Ручная настройка (альтернативный способ)

#### Android
Замените файлы в папках:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

#### iOS
Замените файлы в папке:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Размеры для iOS:
- Icon-App-20x20@1x.png (20x20)
- Icon-App-20x20@2x.png (40x40)
- Icon-App-20x20@3x.png (60x60)
- Icon-App-29x29@1x.png (29x29)
- Icon-App-29x29@2x.png (58x58)
- Icon-App-29x29@3x.png (87x87)
- Icon-App-40x40@1x.png (40x40)
- Icon-App-40x40@2x.png (80x80)
- Icon-App-40x40@3x.png (120x120)
- Icon-App-60x60@2x.png (120x120)
- Icon-App-60x60@3x.png (180x180)
- Icon-App-76x76@1x.png (76x76)
- Icon-App-76x76@2x.png (152x152)
- Icon-App-83.5x83.5@2x.png (167x167)
- Icon-App-1024x1024@1x.png (1024x1024)

## Рекомендации по дизайну иконки:

1. **Призрак должен быть узнаваемым** даже в маленьких размерах
2. **Контрастность** - используйте тёмный фон для лучшей видимости белого призрака
3. **Простота** - избегайте мелких деталей, которые не будут видны в маленьких размерах
4. **Края** - iOS автоматически закругляет углы, учитывайте это при дизайне

## Проверка результата:

После установки иконки:
1. Сделайте `flutter clean`
2. Выполните `flutter build apk` или `flutter build ios`
3. Установите приложение на устройство
4. Проверьте иконку в лаунчере 