import 'event.dart';

/// Status of a check-in for professor validation.
enum CheckInStatus {
  pending, // Awaiting professor validation
  approved, // Approved by professor
  rejected, // Rejected by professor
}

/// Model representing a confirmed check-in record.
class CheckIn {
  final String id;
  final String eventId;
  final String eventName;
  final String eventLocation;
  final DateTime checkInTime;
  final double userLatitude;
  final double userLongitude;
  final double distanceToEvent;
  final CheckInStatus status;
  final String? validatedBy;
  final DateTime? validatedAt;

  CheckIn({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventLocation,
    required this.checkInTime,
    required this.userLatitude,
    required this.userLongitude,
    required this.distanceToEvent,
    this.status = CheckInStatus.pending,
    this.validatedBy,
    this.validatedAt,
  });

  /// Creates a CheckIn from an Event and user location data.
  factory CheckIn.fromEvent({
    required Event event,
    required double userLatitude,
    required double userLongitude,
    required double distance,
  }) {
    return CheckIn(
      id: '${event.id}_${DateTime.now().millisecondsSinceEpoch}',
      eventId: event.id,
      eventName: event.name,
      eventLocation: event.location,
      checkInTime: DateTime.now(),
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      distanceToEvent: distance,
      status: CheckInStatus.pending,
    );
  }

  /// Creates a CheckIn from a JSON map.
  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventLocation: json['eventLocation'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      userLatitude: (json['userLatitude'] as num).toDouble(),
      userLongitude: (json['userLongitude'] as num).toDouble(),
      distanceToEvent: (json['distanceToEvent'] as num).toDouble(),
      status: CheckInStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CheckInStatus.pending,
      ),
      validatedBy: json['validatedBy'] as String?,
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : null,
    );
  }

  /// Converts the CheckIn to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'eventLocation': eventLocation,
      'checkInTime': checkInTime.toIso8601String(),
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'distanceToEvent': distanceToEvent,
      'status': status.name,
      'validatedBy': validatedBy,
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }

  /// Returns a copy with updated status.
  CheckIn copyWith({
    CheckInStatus? status,
    String? validatedBy,
    DateTime? validatedAt,
  }) {
    return CheckIn(
      id: id,
      eventId: eventId,
      eventName: eventName,
      eventLocation: eventLocation,
      checkInTime: checkInTime,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      distanceToEvent: distanceToEvent,
      status: status ?? this.status,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  /// Returns status display name in Portuguese.
  String get statusDisplayName => switch (status) {
    CheckInStatus.pending => 'Pendente',
    CheckInStatus.approved => 'Aprovado',
    CheckInStatus.rejected => 'Rejeitado',
  };

  /// Returns status color.
  bool get isPending => status == CheckInStatus.pending;
  bool get isApproved => status == CheckInStatus.approved;
  bool get isRejected => status == CheckInStatus.rejected;

  /// Returns a formatted date string for display.
  String get formattedDate {
    return '${checkInTime.day.toString().padLeft(2, '0')}/'
        '${checkInTime.month.toString().padLeft(2, '0')}/'
        '${checkInTime.year}';
  }

  /// Returns a formatted time string for display.
  String get formattedTime {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:'
        '${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'CheckIn(id: $id, event: $eventName, time: $formattedDate $formattedTime)';
}
