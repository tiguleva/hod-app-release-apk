import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  Future<GeocodingResult> geocodeAddress({
    required String street,
    required String houseNumber,
    String? apartment,
    String? plotNumber,
  }) async {
    try {
      final addressParts = <String>[street, houseNumber];
      if (apartment != null && apartment.isNotEmpty) {
        addressParts.add('кв. $apartment');
      }
      if (plotNumber != null && plotNumber.isNotEmpty) {
        addressParts.add('уч. $plotNumber');
      }
      
      final address = addressParts.join(', ');
      final encodedAddress = Uri.encodeComponent(address);
      
      final url = '$_baseUrl/search?q=$encodedAddress&format=json&limit=1&countrycodes=ru';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'HodApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final result = data.first;
          return GeocodingResult(
            latitude: double.parse(result['lat']),
            longitude: double.parse(result['lon']),
            displayName: result['display_name'],
            success: true,
          );
        } else {
          return GeocodingResult(
            success: false,
            error: 'Адрес не найден',
          );
        }
      } else {
        return GeocodingResult(
          success: false,
          error: 'Ошибка сервера: ${response.statusCode}',
        );
      }
    } catch (e) {
      return GeocodingResult(
        success: false,
        error: 'Ошибка геокодинга: $e',
      );
    }
  }
  
  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$_baseUrl/reverse?lat=$latitude&lon=$longitude&format=json';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'HodApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['display_name'] != null) {
          return GeocodingResult(
            latitude: latitude,
            longitude: longitude,
            displayName: data['display_name'],
            success: true,
          );
        } else {
          return GeocodingResult(
            success: false,
            error: 'Адрес не найден',
          );
        }
      } else {
        return GeocodingResult(
          success: false,
          error: 'Ошибка сервера: ${response.statusCode}',
        );
      }
    } catch (e) {
      return GeocodingResult(
        success: false,
        error: 'Ошибка обратного геокодинга: $e',
      );
    }
  }
}

class GeocodingResult {
  final double? latitude;
  final double? longitude;
  final String? displayName;
  final bool success;
  final String? error;

  GeocodingResult({
    this.latitude,
    this.longitude,
    this.displayName,
    required this.success,
    this.error,
  });
}
