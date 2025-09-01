#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_v2ray.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_v2ray'
  s.version          = '0.0.1'
  s.summary          = 'Flutter V2Ray plugin with WireGuard support for iOS and Android.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for V2Ray and WireGuard VPN protocols, providing
native VPN functionality on iOS using NetworkExtension framework and Android using VpnService.
                       DESC
  s.homepage         = 'https://github.com/blueboytm/flutter_v2ray'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BlueBoyTM' => 'blueboytm@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Поддержка NetworkExtension
  s.frameworks = ['NetworkExtension', 'SystemConfiguration']
  
  # Настройки для поддержки Network Extensions
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES'
  }
  
  s.swift_version = '5.0'
  
  # Поддержка WireGuard (опционально, если используется внешняя библиотека)
  # s.dependency 'WireGuardKit', '~> 1.0'
  
  # Минимальные требования для VPN функциональности
  s.requires_arc = true
  
  # Поддержка разных архитектур
  s.ios.deployment_target = '12.0'
  
  # Дополнительные настройки компилятора
  s.compiler_flags = '-DHAS_NETWORK_EXTENSION=1'
end
