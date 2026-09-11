/// BAHHAR user domain model, mirrored to the Firestore `users/{uid}` document.
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String homeRegion;
  final DateTime? createdAt;

  /// Locale preference persisted with the profile ('en' or 'ar').
  final String preferredLocale;

  /// True for the local "explore without signing in" session; guest profiles
  /// are never written to Firestore.
  final bool isGuest;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.homeRegion = 'Muscat',
    this.createdAt,
    this.preferredLocale = 'en',
    this.isGuest = false,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? homeRegion,
    DateTime? createdAt,
    String? preferredLocale,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      homeRegion: homeRegion ?? this.homeRegion,
      createdAt: createdAt ?? this.createdAt,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      phoneNumber: json['phone'] as String? ?? json['phoneNumber'] as String?,
      homeRegion: json['homeRegion'] as String? ?? 'Muscat',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (phoneNumber != null) 'phone': phoneNumber,
      'homeRegion': homeRegion,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'preferredLocale': preferredLocale,
      'isGuest': isGuest,
    };
  }
}
