import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_key.dart';
import '../services/vpn_service.dart';
import '../services/storage_service.dart';
import '../widgets/menu_drawer.dart';
import 'home_screen.dart';

class VpnControlScreen extends StatefulWidget {
  final VpnKey vpnKey;

  const VpnControlScreen({super.key, required this.vpnKey});

  @override
  State<VpnControlScreen> createState() => _VpnControlScreenState();
}

class _VpnControlScreenState extends State<VpnControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(),
      appBar: AppBar(
        title: const Text('GhostGram'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
                         onSelected: (value) async {
               print('🔘 Выбрано действие в меню: $value');
               switch (value) {
                                 case 'manage_keys':
                  print('📋 Переход к управлению ключами');
                  print('📋 Context mounted: ${context.mounted}');
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        print('📋 Создаем HomeScreen из меню');
                        return const HomeScreen(stayOnHomeScreen: true);
                      }),
                    );
                  } catch (e) {
                    print('📋 Ошибка навигации из меню: $e');
                  }
                  break;
                 case 'delete_key':
                   print('🗑️ Показываем диалог удаления ключа');
                   _showDeleteKeyDialog();
                   break;
                                 case 'add_key':
                  print('➕ Переход к добавлению ключа');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen(showAddKeyDialog: true)),
                  );
                  break;
               }
             },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'manage_keys',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key),
                    SizedBox(width: 8),
                    Text('Управление ключами'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'add_key',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Добавить ключ'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete_key',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить текущий ключ', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Большая кнопка включения/выключения
              ValueListenableBuilder<bool>(
                valueListenable: VpnService.isConnecting,
                builder: (context, isConnecting, child) {
                  return ValueListenableBuilder<V2RayStatus>(
                    valueListenable: VpnService.statusNotifier,
                    builder: (context, status, child) {
                      final isConnected = status.state == "CONNECTED";
                      
                      return GestureDetector(
                        onTap: isConnecting
                            ? null
                            : () async {
                                if (isConnected) {
                                  await VpnService.disconnect();
                                } else {
                                  final success = await VpnService.connect(widget.vpnKey);
                                  if (!success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ошибка подключения'),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: isConnected
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [
                                      Colors.red.shade400,
                                      Colors.red.shade600,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isConnected
                                    ? Colors.green.withOpacity(0.4)
                                    : Colors.red.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isConnecting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Icon(
                                    Icons.power_settings_new,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 48),
              
              // Статус подключения
              ValueListenableBuilder<V2RayStatus>(
                valueListenable: VpnService.statusNotifier,
                builder: (context, status, child) {
                  return Column(
                    children: [
                      Text(
                        status.state == "CONNECTED"
                            ? 'Подключено'
                            : status.state == "CONNECTING"
                                ? 'Подключение...'
                                : 'Отключено',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (status.state == "CONNECTED") ...[
                        const SizedBox(height: 16),
                        Text(
                          'Время подключения: ${status.duration}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, size: 16),
                            Text(' ${_formatBytes(status.uploadSpeed)}/s'),
                            const SizedBox(width: 16),
                            Icon(Icons.arrow_downward, size: 16),
                            Text(' ${_formatBytes(status.downloadSpeed)}/s'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Трафик: ↑ ${_formatBytes(status.upload)} ↓ ${_formatBytes(status.download)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const Spacer(),
              
              // Информация о ключе
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Активный ключ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.vpnKey.remark,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Добавлен: ${widget.vpnKey.addedDate.day}.${widget.vpnKey.addedDate.month}.${widget.vpnKey.addedDate.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки быстрого доступа
              Row(
                children: [
                                     Expanded(
                     child: OutlinedButton.icon(
                                             onPressed: () async {
                        print('🏠 Кнопка "Все ключи" нажата');
                        print('🏠 Context mounted: ${context.mounted}');
                        try {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              print('🏠 Создаем HomeScreen');
                              return const HomeScreen(stayOnHomeScreen: true);
                            }),
                          );
                          print('🏠 Навигация завершена, результат: $result');
                        } catch (e) {
                          print('🏠 Ошибка навигации: $e');
                        }
                      },
                       icon: const Icon(Icons.vpn_key),
                       label: const Text('Все ключи'),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: ElevatedButton.icon(
                                             onPressed: () async {
                        print('➕ Кнопка "Добавить" нажата');
                        print('➕ Context mounted: ${context.mounted}');
                        try {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              print('➕ Создаем HomeScreen с диалогом');
                              return const HomeScreen(showAddKeyDialog: true, stayOnHomeScreen: true);
                            }),
                          );
                          print('➕ Навигация завершена, результат: $result');
                        } catch (e) {
                          print('➕ Ошибка навигации: $e');
                        }
                      },
                       icon: const Icon(Icons.add),
                       label: const Text('Добавить'),
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showDeleteKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить ключ'),
        content: Text('Вы уверены, что хотите удалить ключ "${widget.vpnKey.remark}"?\n\nПосле удаления вы вернетесь к экрану управления ключами.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Закрываем диалог
              
              try {
                // Отключаемся если подключены
                if (VpnService.isConnected) {
                  await VpnService.disconnect();
                }
                
                // Удаляем ключ
                await StorageService.removeKey(widget.vpnKey.id);
                
                // Возвращаемся на главный экран
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ключ "${widget.vpnKey.remark}" удален'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка удаления ключа: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
