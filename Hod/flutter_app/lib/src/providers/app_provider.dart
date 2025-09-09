import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../models/route.dart';
import '../data/database.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _database = DatabaseHelper();
  final GeocodingService _geocodingService = GeocodingService();
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();

  List<Address> _addresses = [];
  List<Route> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  List<Route> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Address> get unvisitedAddresses => 
      _addresses.where((a) => !a.isVisited).toList();
  
  List<Address> get visitedAddresses => 
      _addresses.where((a) => a.isVisited).toList();

  Future<void> loadAddresses() async {
    _setLoading(true);
    try {
      _addresses = await _database.getAllAddresses();
      _clearError();
    } catch (e) {
      _setError('Ошибка загрузки адресов: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRoutes() async {
    _setLoading(true);
    try {
      _routes = await _database.getAllRoutes();
      _clearError();
    } catch (e) {
      _setError('Ошибка загрузки маршрутов: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addAddress({
    required String street,
    required String houseNumber,
    String? apartment,
    String? plotNumber,
    String? comment,
  }) async {
    _setLoading(true);
    try {
      final address = Address.create(
        street: street,
        houseNumber: houseNumber,
        apartment: apartment,
        plotNumber: plotNumber,
        comment: comment,
      );

      // Геокодинг адреса
      final geocodingResult = await _geocodingService.geocodeAddress(
        street: street,
        houseNumber: houseNumber,
        apartment: apartment,
        plotNumber: plotNumber,
      );

      if (geocodingResult.success) {
        address.latitude = geocodingResult.latitude;
        address.longitude = geocodingResult.longitude;
      }

      await _database.insertAddress(address);
      await loadAddresses();
      _clearError();
      return true;
    } catch (e) {
      _setError('Ошибка добавления адреса: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAddress(Address address) async {
    _setLoading(true);
    try {
      await _database.updateAddress(address);
      await loadAddresses();
      _clearError();
      return true;
    } catch (e) {
      _setError('Ошибка обновления адреса: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    _setLoading(true);
    try {
      await _database.deleteAddress(addressId);
      await loadAddresses();
      _clearError();
      return true;
    } catch (e) {
      _setError('Ошибка удаления адреса: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleAddressVisited(Address address) async {
    if (address.isVisited) {
      address.markAsUnvisited();
    } else {
      address.markAsVisited();
    }
    return await updateAddress(address);
  }

  Future<bool> createRoute({
    required String name,
    required List<Address> selectedAddresses,
  }) async {
    _setLoading(true);
    try {
      final route = Route.create(
        name: name,
        addresses: selectedAddresses,
      );

      await _database.insertRoute(route);
      await loadRoutes();
      _clearError();
      return true;
    } catch (e) {
      _setError('Ошибка создания маршрута: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRoute(String routeId) async {
    _setLoading(true);
    try {
      await _database.deleteRoute(routeId);
      await loadRoutes();
      _clearError();
      return true;
    } catch (e) {
      _setError('Ошибка удаления маршрута: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Address>> getOptimizedRoute(List<Address> addresses) async {
    final currentPosition = await _locationService.getCurrentPosition();
    return await _routeService.optimizeRoute(
      addresses: addresses,
      startLatitude: currentPosition?.latitude,
      startLongitude: currentPosition?.longitude,
    );
  }

  Future<Position?> getCurrentLocation() async {
    return await _locationService.getCurrentPosition();
  }

  Future<bool> requestLocationPermission() async {
    return await _locationService.requestPermission();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
