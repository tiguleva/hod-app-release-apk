import 'package:flutter/material.dart';
import '../models/route.dart';
import '../models/address.dart';

class RouteDetailScreen extends StatelessWidget {
  final Route route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
      ),
      body: Column(
        children: [
          // Информация о маршруте
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          route.isCompleted ? Icons.check_circle : Icons.schedule,
                          color: route.isCompleted ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          route.isCompleted ? 'Завершен' : 'В процессе',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: route.isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Создан',
                            _formatDate(route.createdAt),
                            Icons.calendar_today,
                          ),
                        ),
                        if (route.completedAt != null)
                          Expanded(
                            child: _buildInfoItem(
                              'Завершен',
                              _formatDate(route.completedAt!),
                              Icons.check_circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Всего адресов',
                            '${route.addresses.length}',
                            Icons.location_on,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Посещено',
                            '${route.visitedAddresses.length}',
                            Icons.check,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Прогресс: ${(route.progressPercentage * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: route.progressPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        route.isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Список адресов
          Expanded(
            child: ListView.builder(
              itemCount: route.addresses.length,
              itemBuilder: (context, index) {
                final address = route.addresses[index];
                return _buildAddressItem(address);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressItem(Address address) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: address.isVisited ? Colors.green : Colors.red,
          child: Icon(
            address.isVisited ? Icons.check : Icons.location_on,
            color: Colors.white,
            size: 20,
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
            if (address.comment != null && address.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address.comment!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
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
                if (address.visitedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Посещен ${_formatDate(address.visitedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: address.isVisited
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
