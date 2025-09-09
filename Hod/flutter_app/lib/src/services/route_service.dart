import 'dart:math';
import '../models/address.dart';
import 'location_service.dart';

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final LocationService _locationService = LocationService();

  /// Оптимизирует маршрут по алгоритму ближайшего соседа
  List<Address> optimizeRoute({
    required List<Address> addresses,
    double? startLatitude,
    double? startLongitude,
  }) async {
    if (addresses.isEmpty) return [];

    final unvisitedAddresses = addresses.where((a) => !a.isVisited).toList();
    if (unvisitedAddresses.isEmpty) return addresses;

    final optimizedRoute = <Address>[];
    final remaining = List<Address>.from(unvisitedAddresses);
    
    // Начальная точка
    double currentLat = startLatitude ?? 0.0;
    double currentLon = startLongitude ?? 0.0;
    
    // Если есть текущее местоположение, используем его
    final currentPosition = _locationService.currentPosition;
    if (currentPosition != null) {
      currentLat = currentPosition.latitude;
      currentLon = currentPosition.longitude;
    }

    while (remaining.isNotEmpty) {
      // Найти ближайший адрес
      Address? nearestAddress;
      double minDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < remaining.length; i++) {
        final address = remaining[i];
        if (address.hasCoordinates) {
          final distance = _locationService.calculateDistance(
            startLatitude: currentLat,
            startLongitude: currentLon,
            endLatitude: address.latitude!,
            endLongitude: address.longitude!,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestAddress = address;
            nearestIndex = i;
          }
        }
      }

      if (nearestAddress != null) {
        optimizedRoute.add(nearestAddress);
        remaining.removeAt(nearestIndex);
        
        // Обновить текущую позицию
        currentLat = nearestAddress.latitude!;
        currentLon = nearestAddress.longitude!;
      } else {
        // Если нет координат, добавить оставшиеся адреса
        optimizedRoute.addAll(remaining);
        break;
      }
    }

    return optimizedRoute;
  }

  /// Вычисляет общее расстояние маршрута
  double calculateRouteDistance(List<Address> addresses) {
    if (addresses.length < 2) return 0.0;

    double totalDistance = 0.0;
    
    for (int i = 0; i < addresses.length - 1; i++) {
      final current = addresses[i];
      final next = addresses[i + 1];
      
      if (current.hasCoordinates && next.hasCoordinates) {
        totalDistance += _locationService.calculateDistance(
          startLatitude: current.latitude!,
          startLongitude: current.longitude!,
          endLatitude: next.latitude!,
          endLongitude: next.longitude!,
        );
      }
    }

    return totalDistance;
  }

  /// Вычисляет примерное время пешего маршрута (скорость 5 км/ч)
  Duration calculateWalkingTime(List<Address> addresses) {
    final distance = calculateRouteDistance(addresses);
    const walkingSpeedKmh = 5.0; // км/ч
    final timeInHours = distance / 1000 / walkingSpeedKmh; // переводим метры в км
    return Duration(minutes: (timeInHours * 60).round());
  }

  /// Форматирует расстояние в читаемый вид
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} км';
    }
  }

  /// Форматирует время в читаемый вид
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}ч ${minutes}м';
    } else {
      return '${minutes}м';
    }
  }
}
