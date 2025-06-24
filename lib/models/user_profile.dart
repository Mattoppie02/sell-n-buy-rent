class UserProfile {
  final String uid;
  final String email;
  final String name;
  String? photoUrl;
  String? phoneNumber;
  List<String> listings;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phoneNumber,
    List<String>? listings,
  }) : listings = listings ?? [];

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'listings': listings,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      listings: List<String>.from(map['listings'] ?? []),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? phoneNumber,
    List<String>? listings,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      listings: listings ?? this.listings,
    );
  }
}
