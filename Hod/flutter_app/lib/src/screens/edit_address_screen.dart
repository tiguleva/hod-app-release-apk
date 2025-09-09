import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/address.dart';

class EditAddressScreen extends StatefulWidget {
  final Address address;

  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _streetController;
  late TextEditingController _houseNumberController;
  late TextEditingController _apartmentController;
  late TextEditingController _plotNumberController;
  late TextEditingController _commentController;
  late bool _isVisited;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.address.street);
    _houseNumberController = TextEditingController(text: widget.address.houseNumber);
    _apartmentController = TextEditingController(text: widget.address.apartment ?? '');
    _plotNumberController = TextEditingController(text: widget.address.plotNumber ?? '');
    _commentController = TextEditingController(text: widget.address.comment ?? '');
    _isVisited = widget.address.isVisited;
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _apartmentController.dispose();
    _plotNumberController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать адрес'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading ? null : _saveAddress,
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Адрес',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Улица *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название улицы';
                }
                if (value.trim().length < 2) {
                  return 'Название улицы слишком короткое';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _houseNumberController,
              decoration: const InputDecoration(
                labelText: 'Номер дома *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите номер дома';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apartmentController,
              decoration: const InputDecoration(
                labelText: 'Квартира',
                border: OutlineInputBorder(),
                hintText: 'Например: 5 (необязательно)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plotNumberController,
              decoration: const InputDecoration(
                labelText: 'Номер участка',
                border: OutlineInputBorder(),
                hintText: 'Например: 123 (необязательно)',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Статус',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Посещен'),
              subtitle: Text(_isVisited ? 'Адрес отмечен как посещенный' : 'Адрес не посещен'),
              value: _isVisited,
              onChanged: (value) {
                setState(() {
                  _isVisited = value;
                });
              },
              secondary: Icon(
                _isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _isVisited ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Комментарий',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация (необязательно)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (widget.address.hasCoordinates) ...[
              const Text(
                'Координаты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Широта: ${widget.address.latitude!.toStringAsFixed(6)}'),
                    const SizedBox(height: 4),
                    Text('Долгота: ${widget.address.longitude!.toStringAsFixed(6)}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (provider.error != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => provider.clearError(),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AppProvider>();
    
    // Обновляем адрес
    widget.address.street = _streetController.text.trim();
    widget.address.houseNumber = _houseNumberController.text.trim();
    widget.address.apartment = _apartmentController.text.trim().isEmpty 
        ? null 
        : _apartmentController.text.trim();
    widget.address.plotNumber = _plotNumberController.text.trim().isEmpty 
        ? null 
        : _plotNumberController.text.trim();
    widget.address.comment = _commentController.text.trim().isEmpty 
        ? null 
        : _commentController.text.trim();

    // Обновляем статус посещения
    if (_isVisited != widget.address.isVisited) {
      if (_isVisited) {
        widget.address.markAsVisited();
      } else {
        widget.address.markAsUnvisited();
      }
    }

    final success = await provider.updateAddress(widget.address);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Адрес успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
