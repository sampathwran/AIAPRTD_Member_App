import 'package:cloud_firestore/cloud_firestore.dart';

class EvCharger {
  final String id;
  final String? name; // Added custom name for the charger point
  final String type;
  final double powerKw;
  final String status; // Available, In Use, Broken, Unknown
  final double pricePerKwh; // Added price per charger

  EvCharger({
    required this.id,
    this.name,
    required this.type,
    required this.powerKw,
    required this.status,
    this.pricePerKwh = 0.0,
  });

  factory EvCharger.fromJson(Map<String, dynamic> json) {
    return EvCharger(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'],
      type: json['type'] ?? 'Unknown',
      powerKw: (json['powerKw'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Unknown',
      pricePerKwh: (json['pricePerKwh'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'powerKw': powerKw,
      'status': status,
      'pricePerKwh': pricePerKwh,
    };
  }
}

class EvStation {
  final String id;
  final String name;
  final String provider;
  final String address;
  final String? description;
  final String markerColor;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final List<EvCharger> chargers;
  
  // Legacy fields (kept for backward compatibility with existing data)
  final int legacyPowerKw;
  final double pricePerKwh;
  final String legacyStatus;
  final List<String> legacyChargerTypes;

  EvStation({
    required this.id,
    required this.name,
    required this.provider,
    required this.address,
    this.description,
    this.markerColor = '#4CAF50', // Default green
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.chargers,
    this.legacyPowerKw = 0,
    this.pricePerKwh = 0.0,
    this.legacyStatus = 'Unknown',
    this.legacyChargerTypes = const [],
  });

  factory EvStation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<EvCharger> parsedChargers = [];
    if (data['chargers'] != null) {
      parsedChargers = (data['chargers'] as List).map((c) => EvCharger.fromJson(c)).toList();
    } else {
      // Migrate old data on the fly if it doesn't have the new 'chargers' array
      final status = data['status'] ?? 'Unknown';
      final power = (data['powerKw'] ?? 0).toDouble();
      final price = (data['pricePerKwh'] ?? 0.0).toDouble();
      List<String> types = List<String>.from(data['chargerTypes'] ?? []);
      
      for (int i = 0; i < types.length; i++) {
        parsedChargers.add(EvCharger(
          id: '${doc.id}_$i',
          name: 'Port ${i + 1}',
          type: types[i],
          powerKw: power,
          status: status,
          pricePerKwh: price,
        ));
      }
    }
    
    return EvStation(
      id: doc.id,
      name: data['name'] ?? 'Unknown Station',
      provider: data['provider'] ?? 'Unknown',
      address: data['address'] ?? '',
      description: data['description'],
      markerColor: data['markerColor'] ?? '#4CAF50',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      chargers: parsedChargers,
      legacyPowerKw: (data['powerKw'] ?? 0).toInt(),
      pricePerKwh: (data['pricePerKwh'] ?? 0.0).toDouble(),
      legacyStatus: data['status'] ?? 'Unknown',
      legacyChargerTypes: List<String>.from(data['chargerTypes'] ?? []),
    );
  }
}
