import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/address.dart';
import 'add_address_screen.dart';
import 'edit_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Адреса'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddAddress(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAddresses(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.addresses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет добавленных адресов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы добавить первый адрес',
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
              return AddressCard(
                address: address,
                onTap: () => _navigateToEditAddress(context, address),
                onToggleVisited: () => _toggleVisited(provider, address),
                onDelete: () => _deleteAddress(provider, address),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAddressScreen()),
    );
  }

  void _navigateToEditAddress(BuildContext context, Address address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(address: address),
      ),
    );
  }

  void _toggleVisited(AppProvider provider, Address address) {
    provider.toggleAddressVisited(address);
  }

  void _deleteAddress(AppProvider provider, Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить адрес'),
        content: Text('Вы уверены, что хотите удалить адрес "${address.fullAddress}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteAddress(address.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onTap;
  final VoidCallback onToggleVisited;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.onTap,
    required this.onToggleVisited,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: address.isVisited ? Colors.green : Colors.red,
          child: Icon(
            address.isVisited ? Icons.check : Icons.location_on,
            color: Colors.white,
          ),
        ),
        title: Text(
          address.fullAddress,
          style: TextStyle(
            decoration: address.isVisited ? TextDecoration.lineThrough : null,
            color: address.isVisited ? Colors.grey : null,
          ),
        ),
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
                  address.hasCoordinates ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: address.hasCoordinates ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  address.hasCoordinates ? 'Координаты найдены' : 'Координаты не найдены',
                  style: TextStyle(
                    fontSize: 12,
                    color: address.hasCoordinates ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(address.isVisited ? Icons.undo : Icons.check),
                  const SizedBox(width: 8),
                  Text(address.isVisited ? 'Отметить непосещенным' : 'Отметить посещенным'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Удалить', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'toggle':
                onToggleVisited();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
