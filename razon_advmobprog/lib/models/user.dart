// Enhancement 3:
// User model for the logged-in DummyJSON user. Mirrors the
// fields user_service.dart already saves to/reads from
// SharedPreferences (id, username, email, firstName, lastName,
// gender, image, accessToken, refreshToken, token).
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
  });

  // full display name, e.g. "Emily Johnson"
  String get fullName => '$firstName $lastName'.trim();

  // two-letter initials for the avatar circle, e.g. "EJ"
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$first$last'.toUpperCase();
    return combined.isEmpty
        ? (username.isNotEmpty ? username[0].toUpperCase() : '?')
        : combined;
  }

  // converts API/SharedPreferences data into a User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      // 'token' covers the generic key user_service.dart falls
      // back to if the API response doesn't use accessToken.
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
