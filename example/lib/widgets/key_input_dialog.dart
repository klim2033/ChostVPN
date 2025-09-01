import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

class KeyInputDialog extends StatefulWidget {
  final String? initialKey;
  final Function(String key, String remark) onSave;

  const KeyInputDialog({
    super.key,
    this.initialKey,
    required this.onSave,
  });

  @override
  State<KeyInputDialog> createState() => _KeyInputDialogState();
}

class _KeyInputDialogState extends State<KeyInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
      _validateAndExtractRemark();
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _validateAndExtractRemark() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(_keyController.text.trim());
      _remarkController.text = v2rayURL.remark;
      setState(() {
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Неверный формат ключа';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить VPN ключ'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'VPN ключ',
                hintText: 'vmess://, vless://, trojan://, ss://, socks://',
                errorText: _errorMessage,
                suffixIcon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите VPN ключ';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _validateAndExtractRemark();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: 'Название (опционально)',
                hintText: 'Мой VPN сервер',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _errorMessage == null
              ? () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(
                      _keyController.text.trim(),
                      _remarkController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                }
              : null,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
