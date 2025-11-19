// Model class for Baby Profile
class BabyProfile {
  final int? id;
  final String firstName;
  final String lastName;
  final int? gestationalAge; // in weeks
  final double? weight; // in kg
  final String? gender; // 'male', 'female', or 'other'
  final DateTime createdAt;

  BabyProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    this.gestationalAge,
    this.weight,
    this.gender,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert BabyProfile to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'gestational_age': gestationalAge,
      'weight': weight,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create BabyProfile from Map (from database)
  factory BabyProfile.fromMap(Map<String, dynamic> map) {
    return BabyProfile(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      gestationalAge: map['gestational_age'] as int?,
      weight: map['weight'] as double?,
      gender: map['gender'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Create a copy with updated fields
  BabyProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    int? gestationalAge,
    double? weight,
    String? gender,
    DateTime? createdAt,
  }) {
    return BabyProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gestationalAge: gestationalAge ?? this.gestationalAge,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get full name
  String get fullName => '$firstName $lastName';
}