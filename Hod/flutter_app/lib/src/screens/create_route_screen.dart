import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/address.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedAddressIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать маршрут'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading ? null : _createRoute,
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Название маршрута
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название маршрута *',
                  border: OutlineInputBorder(),
                  hintText: 'Например: Утренний обход',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название маршрута';
                  }
                  if (value.trim().length < 2) {
                    return 'Название слишком короткое';
                  }
                  return null;
                },
              ),
            ),
            // Список адресов
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.addresses.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Нет доступных адресов',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Сначала добавьте адреса в разделе "Адреса"',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.addresses.length,
                    itemBuilder: (context, index) {
                      final address = provider.addresses[index];
                      final isSelected = _selectedAddressIds.contains(address.id);
                      
                      return CheckboxListTile(
                        title: Text(address.fullAddress),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (address.comment != null && address.comment!.isNotEmpty)
                              Text(
                                address.comment!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  address.isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: address.isVisited ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  address.isVisited ? 'Посещен' : 'Не посещен',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: address.isVisited ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  address.hasCoordinates ? Icons.gps_fixed : Icons.gps_off,
                                  size: 16,
                                  color: address.hasCoordinates ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  address.hasCoordinates ? 'Координаты' : 'Нет координат',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: address.hasCoordinates ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedAddressIds.add(address.id);
                            } else {
                              _selectedAddressIds.remove(address.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Информация о выбранных адресах
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Выбрано адресов: ${_selectedAddressIds.length}'),
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      if (provider.error != null) {
                        return Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAddressIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один адрес'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final selectedAddresses = provider.addresses
        .where((address) => _selectedAddressIds.contains(address.id))
        .toList();

    final success = await provider.createRoute(
      name: _nameController.text.trim(),
      selectedAddresses: selectedAddresses,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Маршрут успешно создан'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
