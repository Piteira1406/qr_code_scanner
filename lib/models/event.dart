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
  /// QR Code format: ISTEC|eventId|eventName|description|latitude|longitude|startTime|endTime|location
  /// The ISTEC prefix ensures only valid ISTEC QR codes are accepted.
  factory Event.fromQRCode(String qrData) {
    final parts = qrData.split('|');

    // Validate format: must have ISTEC prefix and 9 parts
    if (parts.length < 9 || parts[0] != 'ISTEC') {
      throw FormatException('QR Code Inválido: formato incorreto');
    }

    try {
      return Event(
        id: parts[1],
        name: parts[2],
        description: parts[3],
        latitude: double.parse(parts[4]),
        longitude: double.parse(parts[5]),
        startTime: DateTime.parse(parts[6]),
        endTime: DateTime.parse(parts[7]),
        location: parts[8],
      );
    } catch (e) {
      throw FormatException('QR Code Inválido: dados corrompidos');
    }
  }

  /// Generates QR code data string for this event.
  /// Format: ISTEC|eventId|eventName|description|latitude|longitude|startTime|endTime|location
  String toQRCodeData() {
    return 'ISTEC|$id|$name|$description|$latitude|$longitude|${startTime.toIso8601String()}|${endTime.toIso8601String()}|$location';
  }

  @override
  String toString() => 'Event(id: $id, name: $name, location: $location)';
}
