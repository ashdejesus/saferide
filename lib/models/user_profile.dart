class UserProfile {
  final String? name;
  final String? phone;

  UserProfile({this.name, this.phone});

  Map<String, dynamic> toMap() => {
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
  };

  factory UserProfile.fromMap(Map<String, dynamic>? m) {
    if (m == null) return UserProfile();
    return UserProfile(
      name: m['name'] as String?,
      phone: m['phone'] as String?,
    );
  }
}
