import 'package:uuid/uuid.dart';

class Address {
  final String id;
  String street;
  String houseNumber;
  String? apartment;
  String? plotNumber;
  double? latitude;
  double? longitude;
  bool isVisited;
  String? comment;
  DateTime createdAt;
  DateTime? visitedAt;

  Address({
    required this.id,
    required this.street,
    required this.houseNumber,
    this.apartment,
    this.plotNumber,
    this.latitude,
    this.longitude,
    this.isVisited = false,
    this.comment,
    required this.createdAt,
    this.visitedAt,
  });

  factory Address.create({
    required String street,
    required String houseNumber,
    String? apartment,
    String? plotNumber,
    String? comment,
  }) {
    return Address(
      id: const Uuid().v4(),
      street: street,
      houseNumber: houseNumber,
      apartment: apartment,
      plotNumber: plotNumber,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  String get fullAddress {
    final parts = <String>[street, 'д. $houseNumber'];
    if ((apartment ?? '').isNotEmpty) parts.add('кв. $apartment');
    if ((plotNumber ?? '').isNotEmpty) parts.add('уч. $plotNumber');
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'street': street,
      'houseNumber': houseNumber,
      'apartment': apartment,
      'plotNumber': plotNumber,
      'latitude': latitude,
      'longitude': longitude,
      'isVisited': isVisited ? 1 : 0,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'visitedAt': visitedAt?.millisecondsSinceEpoch,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'],
      street: map['street'],
      houseNumber: map['houseNumber'],
      apartment: map['apartment'],
      plotNumber: map['plotNumber'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isVisited: map['isVisited'] == 1,
      comment: map['comment'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      visitedAt: map['visitedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['visitedAt'])
          : null,
    );
  }

  void markAsVisited({String? comment}) {
    isVisited = true;
    visitedAt = DateTime.now();
    if (comment != null) {
      this.comment = comment;
    }
  }

  void markAsUnvisited() {
    isVisited = false;
    visitedAt = null;
  }
}
