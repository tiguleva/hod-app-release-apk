import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/route.dart';
import 'create_route_screen.dart';
import 'route_detail_screen.dart';

class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История маршрутов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateRoute(context),
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
                    onPressed: () => provider.loadRoutes(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.routes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет созданных маршрутов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы создать первый маршрут',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.routes.length,
            itemBuilder: (context, index) {
              final route = provider.routes[index];
              return RouteCard(
                route: route,
                onTap: () => _navigateToRouteDetail(context, route),
                onDelete: () => _deleteRoute(provider, route),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateRoute(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateRoute(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRouteScreen()),
    );
  }

  void _navigateToRouteDetail(BuildContext context, Route route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailScreen(route: route),
      ),
    );
  }

  void _deleteRoute(AppProvider provider, Route route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить маршрут'),
        content: Text('Вы уверены, что хотите удалить маршрут "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteRoute(route.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final Route route;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: route.isCompleted ? Colors.green : Colors.orange,
          child: Icon(
            route.isCompleted ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          route.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Создан: ${_formatDate(route.createdAt)}'),
            if (route.completedAt != null)
              Text('Завершен: ${_formatDate(route.completedAt!)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Адресов: ${route.addresses.length}'),
                const SizedBox(width: 16),
                Text('Посещено: ${route.visitedAddresses.length}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: route.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                route.isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(route.progressPercentage * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
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
            if (value == 'delete') {
              onDelete();
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
