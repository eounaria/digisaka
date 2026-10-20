class UserProfile {
  final String fullName;
  final String farmLocation;
  final String? email;
  final String? phone;

  const UserProfile({
    required this.fullName,
    required this.farmLocation,
    this.email,
    this.phone,
  });

  UserProfile copyWith({
    String? fullName,
    String? farmLocation,
    String? email,
    String? phone,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      farmLocation: farmLocation ?? this.farmLocation,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  /// Derives initials automatically (e.g., "Juan Dela Cruz" -> "JC", "Admin" -> "AD")
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}