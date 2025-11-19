class Reading {
  final int? id;
  final int babyProfileId;
  final int heartRate;
  final int spO2;
  final int breathingRate;
  final DateTime timestamp;

  Reading({
    this.id,
    required this.babyProfileId,
    required this.heartRate,
    required this.spO2,
    required this.breathingRate,
    required this.timestamp,
  });

  // Convert Reading to JSON for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baby_profile_id': babyProfileId,
      'heart_rate': heartRate,
      'spo2': spO2,
      'breathing_rate': breathingRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create Reading from database map
  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'] as int?,
      babyProfileId: map['baby_profile_id'] as int,
      heartRate: map['heart_rate'] as int,
      spO2: map['spo2'] as int,
      breathingRate: map['breathing_rate'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  // Convenience methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyProfileId': babyProfileId,
      'heartRate': heartRate,
      'spO2': spO2,
      'breathingRate': breathingRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Reading(id: $id, babyProfileId: $babyProfileId, HR: $heartRate, SpO2: $spO2, BR: $breathingRate, timestamp: $timestamp)';
  }
}
