import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vpn_key.dart';
import '../services/storage_service.dart';
import '../services/vpn_service.dart';
import 'vpn_control_screen.dart';
import '../widgets/menu_drawer.dart';
import '../widgets/key_input_dialog.dart';

class HomeScreen extends StatefulWidget {
  final bool showAddKeyDialog;
  final bool stayOnHomeScreen;
  
  const HomeScreen({super.key, this.showAddKeyDialog = false, this.stayOnHomeScreen = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VpnKey> _keys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState, showAddKeyDialog: ${widget.showAddKeyDialog}');
    _loadKeys();
    VpnService.init();
  }

  Future<void> _loadKeys() async {
    try {
      setState(() => _isLoading = true);
      final keys = await StorageService.getKeys();
      setState(() {
        _keys = keys;
        _isLoading = false;
      });
      
      // Показываем диалог добавления ключа если параметр установлен
      if (widget.showAddKeyDialog && mounted) {
        print('📱 Загрузка завершена, показываем диалог добавления ключа');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showAddKeyDialog();
          }
        });
        return; // Не переходим к активному ключу если нужно показать диалог
      }
      
      // Если есть активный ключ и не указано оставаться на домашнем экране, переходим на экран управления
      if (!widget.stayOnHomeScreen) {
        final activeKey = await StorageService.getActiveKey();
        if (activeKey != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VpnControlScreen(vpnKey: activeKey),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Ошибка загрузки ключей: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final text = clipboardData.text!.trim();
        if (text.isNotEmpty) {
          _showAddKeyDialog(initialKey: text);
        } else {
          _showErrorSnackBar('Буфер обмена пуст');
        }
      } else {
        _showErrorSnackBar('Буфер обмена пуст');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка чтения буфера обмена: $e');
    }
  }

  void _showAddKeyDialog({String? initialKey}) {
    print('🎯 _showAddKeyDialog вызван с initialKey: $initialKey');
    showDialog(
      context: context,
      builder: (context) => KeyInputDialog(
        initialKey: initialKey,
        onSave: (key, remark) async {
          try {
            // Проверяем, что ключ не пустой
            if (key.trim().isEmpty) {
              _showErrorSnackBar('Ключ не может быть пустым');
              return;
            }

            // Проверяем, что ремарка не пустая
            if (remark.trim().isEmpty) {
              _showErrorSnackBar('Название ключа не может быть пустым');
              return;
            }

            // Проверяем, что такой ключ еще не добавлен
            final existingKeys = await StorageService.getKeys();
            if (existingKeys.any((existingKey) => existingKey.key.trim() == key.trim())) {
              _showErrorSnackBar('Такой ключ уже добавлен');
              return;
            }

            final newKey = VpnKey(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              key: key.trim(),
              remark: remark.trim(),
              addedDate: DateTime.now(),
              isActive: _keys.isEmpty,
              protocol: VpnKey.detectProtocol(key),
            );
            
            await StorageService.addKey(newKey);
            await _loadKeys();
            
                           _showSuccessSnackBar('Ключ "$remark" успешно добавлен');
            
            if (_keys.length == 1 && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VpnControlScreen(vpnKey: newKey),
                ),
              );
            }
          } catch (e) {
            _showErrorSnackBar('Ошибка добавления ключа: $e');
          }
        },
      ),
    );
  }

  Future<void> _deleteKey(VpnKey key) async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить ключ "${key.remark}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.removeKey(key.id);
        await _loadKeys();
        _showSuccessSnackBar('Ключ "${key.remark}" удален');
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления ключа: $e');
      }
    }
  }

  Future<void> _selectKey(VpnKey key) async {
    try {
      await StorageService.setActiveKey(key.id);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VpnControlScreen(vpnKey: key),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора ключа: $e');
    }
  }

  void _showHowToGetKey() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Где взять ключ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Для получения ключа перейдите в наш магазин:'),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                Navigator.pop(context); // Закрываем диалог
                try {
                  final url = Uri.parse('https://t.me/GhostGramVPN_Bot');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    _showErrorSnackBar('Не удалось открыть Telegram');
                  }
                } catch (e) {
                  _showErrorSnackBar('Ошибка открытия Telegram: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.telegram,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '@GhostGramVPN_Bot',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(),
      appBar: AppBar(
        title: const Text('GhostGram'),
        actions: [
          TextButton.icon(
            onPressed: _showAddKeyDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить ключ'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'У вас пока нет VPN ключей',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте первый ключ для начала работы',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Вставить ключ'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 56),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showAddKeyDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Ввести ключ вручную'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 56),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _showHowToGetKey,
                          child: const Text('Где взять ключ?'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadKeys,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _keys.length,
                    itemBuilder: (context, index) {
                      final key = _keys[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            key.protocol == VpnProtocol.wireguard 
                                ? Icons.security 
                                : Icons.vpn_key,
                            color: key.isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            key.remark,
                            style: TextStyle(
                              fontWeight: key.isActive ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Протокол: ${key.protocol.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                'Добавлен: ${key.addedDate.day}.${key.addedDate.month}.${key.addedDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (key.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Активный',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteKey(key),
                                tooltip: 'Удалить ключ',
                              ),
                            ],
                          ),
                          onTap: () => _selectKey(key),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
