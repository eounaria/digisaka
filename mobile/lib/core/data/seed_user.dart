/// Simple user model + seed (sample) data for the mock demo.
/// Replace with real data from your backend/auth later.
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String password; // demo only - never store plain passwords in a real app
  final String farmName;
  final String sitio;
  final String municipality;
  final String province;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.password,
    required this.farmName,
    required this.sitio,
    required this.municipality,
    required this.province,
  });

  /// "Juan Dela Cruz"
  String get fullName => '$firstName $lastName';

  /// "JD"
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  /// "Sitio Malabo, Balayan, Batangas" (Home greeting card)
  String get shortLocation => '$sitio, $municipality, $province';

  /// "Sitio Malabo Banana Farm · Balayan, Batangas" (Profile)
  String get farmLocation => '$farmName · $municipality, $province';
}

/// The sample user.
/// Demo login:  juan.delacruz@example.com  (or 09171234567)  /  digisaka123
const UserModel seedUser = UserModel(
  id: 'user-001',
  firstName: 'Juan',
  lastName: 'Dela Cruz',
  email: 'juan.delacruz@example.com',
  mobile: '09171234567',
  password: 'digisaka123',
  farmName: 'Sitio Malabo Banana Farm',
  sitio: 'Sitio Malabo',
  municipality: 'Balayan',
  province: 'Batangas',
);

/// All users that are allowed to log in. Add more here if you want.
const List<UserModel> seedUsers = [seedUser];

/// Returns the matching user, or null if the email/mobile or password is wrong.
UserModel? authenticate(String emailOrMobile, String password) {
  final String id = emailOrMobile.trim().toLowerCase();

  for (final user in seedUsers) {
    final bool idMatches =
        user.email.toLowerCase() == id || user.mobile == id;
    if (idMatches && user.password == password) {
      return user;
    }
  }
  return null;
}