import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String homeRegion;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.homeRegion = 'Muscat',
  });

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    String? homeRegion,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      homeRegion: homeRegion ?? this.homeRegion,
    );
  }
}

class AuthNotifier extends StateNotifier<UserProfile?> {
  AuthNotifier() : super(const UserProfile(
    id: 'user_dev_01',
    email: 'fisherman@bahhar.om',
    displayName: 'Said Al-Bahri',
    phoneNumber: '+968 9123 4567',
    homeRegion: 'Muscat',
  ));

  void signIn(String email, String password) {
    state = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@').first,
      homeRegion: 'Muscat',
    );
  }

  void updateHomeRegion(String newRegion) {
    if (state != null) {
      state = state!.copyWith(homeRegion: newRegion);
    }
  }

  void signOut() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile?>((ref) {
  return AuthNotifier();
});
