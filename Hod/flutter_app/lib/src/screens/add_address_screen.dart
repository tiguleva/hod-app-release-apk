import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _plotNumberController = TextEditingController();
  final _commentController = TextEditingController();

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
        title: const Text('Добавить адрес'),
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
                hintText: 'Например: Ленина',
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
                hintText: 'Например: 10',
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
    final success = await provider.addAddress(
      street: _streetController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      apartment: _apartmentController.text.trim().isEmpty 
          ? null 
          : _apartmentController.text.trim(),
      plotNumber: _plotNumberController.text.trim().isEmpty 
          ? null 
          : _plotNumberController.text.trim(),
      comment: _commentController.text.trim().isEmpty 
          ? null 
          : _commentController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Адрес успешно добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
