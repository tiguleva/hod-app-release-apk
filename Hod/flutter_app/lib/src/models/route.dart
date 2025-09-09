import 'package:uuid/uuid.dart';
import 'address.dart';

class Route {
  final String id;
  String name;
  DateTime createdAt;
  DateTime? completedAt;
  List<Address> addresses;

  Route({
    required this.id,
    required this.name,
    required this.createdAt,
    this.completedAt,
    this.addresses = const [],
  });

  factory Route.create({
    required String name,
    List<Address> addresses = const [],
  }) {
    return Route(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      addresses: addresses,
    );
  }

  bool get isCompleted {
    if (addresses.isEmpty) return false;
    return addresses.every((address) => address.isVisited);
  }

  double get progressPercentage {
    if (addresses.isEmpty) return 0.0;
    final visitedCount = addresses.where((address) => address.isVisited).length;
    return visitedCount / addresses.length;
  }

  List<Address> get visitedAddresses {
    return addresses.where((address) => address.isVisited).toList();
  }

  List<Address> get unvisitedAddresses {
    return addresses.where((address) => !address.isVisited).toList();
  }

  void completeRoute() {
    completedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Route.fromMap(Map<String, dynamic> map, List<Address> addresses) {
    return Route(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      addresses: addresses,
    );
  }
}
