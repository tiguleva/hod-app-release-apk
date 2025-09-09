import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/app_provider.dart';
import '../models/address.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _buildRoute,
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(55.7558, 37.6176), // Moscow
                  initialZoom: 13.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.hod.app',
                  ),
                  // Маркеры адресов
                  MarkerLayer(
                    markers: _buildAddressMarkers(provider.addresses),
                  ),
                  // Маркер текущего местоположения
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  // Маршрут
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: Colors.blue,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                ],
              ),
              // Индикатор загрузки
              if (_isLoadingLocation)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Получение местоположения...'),
                        ],
                      ),
                    ),
                  ),
                ),
              // Кнопки управления
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'center',
                      onPressed: _centerOnAddresses,
                      child: const Icon(Icons.center_focus_strong),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'route',
                      onPressed: _buildRoute,
                      child: const Icon(Icons.directions_walk),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildAddressMarkers(List<Address> addresses) {
    return addresses.map((address) {
      if (!address.hasCoordinates) return null;
      
      return Marker(
        point: LatLng(address.latitude!, address.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showAddressInfo(address),
          child: Container(
            decoration: BoxDecoration(
              color: address.isVisited ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              address.isVisited ? Icons.check : Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).where((marker) => marker != null).cast<Marker>().toList();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final provider = context.read<AppProvider>();
      final position = await provider.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        _mapController.move(_currentLocation!, 15.0);
      } else {
        _showLocationError();
      }
    } catch (e) {
      _showLocationError();
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _centerOnAddresses() {
    final provider = context.read<AppProvider>();
    final addressesWithCoords = provider.addresses.where((a) => a.hasCoordinates).toList();
    
    if (addressesWithCoords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет адресов с координатами')),
      );
      return;
    }

    double minLat = addressesWithCoords.first.latitude!;
    double maxLat = addressesWithCoords.first.latitude!;
    double minLon = addressesWithCoords.first.longitude!;
    double maxLon = addressesWithCoords.first.longitude!;

    for (final address in addressesWithCoords) {
      minLat = minLat < address.latitude! ? minLat : address.latitude!;
      maxLat = maxLat > address.latitude! ? maxLat : address.latitude!;
      minLon = minLon < address.longitude! ? minLon : address.longitude!;
      maxLon = maxLon > address.longitude! ? maxLon : address.longitude!;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLon + maxLon) / 2,
    );

    final bounds = LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _buildRoute() async {
    final provider = context.read<AppProvider>();
    final unvisitedAddresses = provider.unvisitedAddresses.where((a) => a.hasCoordinates).toList();
    
    if (unvisitedAddresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет непосещенных адресов с координатами')),
      );
      return;
    }

    try {
      final optimizedRoute = await provider.getOptimizedRoute(unvisitedAddresses);
      
      setState(() {
        _routePoints = optimizedRoute
            .where((address) => address.hasCoordinates)
            .map((address) => LatLng(address.latitude!, address.longitude!))
            .toList();
      });

      if (_routePoints.isNotEmpty) {
        _centerOnAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Маршрут построен через ${_routePoints.length} точек'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка построения маршрута: $e')),
      );
    }
  }

  void _showAddressInfo(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address.fullAddress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.comment != null && address.comment!.isNotEmpty) ...[
              const Text('Комментарий:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(address.comment!),
              const SizedBox(height: 8),
            ],
            Text('Статус: ${address.isVisited ? "Посещен" : "Не посещен"}'),
            if (address.hasCoordinates) ...[
              const SizedBox(height: 8),
              Text('Координаты:'),
              Text('Широта: ${address.latitude!.toStringAsFixed(6)}'),
              Text('Долгота: ${address.longitude!.toStringAsFixed(6)}'),
            ],
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

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось получить местоположение'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
