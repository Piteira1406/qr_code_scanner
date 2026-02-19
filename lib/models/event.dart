/// Model representing an event or class that students can check into.
class Event {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  /// Creates an Event from a JSON map.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String,
    );
  }

  /// Converts the Event to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
    };
  }

  /// Creates an Event from QR Code data.
  ///
  /// DEMO MODE: Currently accepts any QR code and creates a demo event.
  /// The original format validation is preserved below for future use.
  ///
  /// Original QR Code format: eventId|eventName|description|latitude|longitude|startTime|endTime|location
  factory Event.fromQRCode(String qrData) {
    // ============================================================
    // DEMO MODE - Accept any QR code
    // ============================================================
    // For demonstration purposes, any scanned QR code will create
    // a valid event. The QR code content becomes the event name.

    final now = DateTime.now();
    return Event(
      id: 'demo_${now.millisecondsSinceEpoch}',
      name: qrData.length > 50 ? '${qrData.substring(0, 50)}...' : qrData,
      description: 'Evento criado a partir de QR Code scaneado',
      latitude: 0.0, // Will be overridden with user's actual location
      longitude: 0.0, // Will be overridden with user's actual location
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      location: 'Localização verificada por GPS',
    );

    // ============================================================
    // ORIGINAL FORMAT VALIDATION (stand-by para uso futuro)
    // ============================================================
    // Uncomment the code below to enable strict QR code format validation:
    //
    // final parts = qrData.split('|');
    // if (parts.length < 8) {
    //   throw FormatException('QR Code Inválido: formato incorreto');
    // }
    //
    // try {
    //   return Event(
    //     id: parts[0],
    //     name: parts[1],
    //     description: parts[2],
    //     latitude: double.parse(parts[3]),
    //     longitude: double.parse(parts[4]),
    //     startTime: DateTime.parse(parts[5]),
    //     endTime: DateTime.parse(parts[6]),
    //     location: parts[7],
    //   );
    // } catch (e) {
    //   throw FormatException('QR Code Inválido: dados corrompidos');
    // }
    // ============================================================
  }

  @override
  String toString() => 'Event(id: $id, name: $name, location: $location)';
}
