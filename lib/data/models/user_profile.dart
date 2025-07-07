class UserProfile {
  final String? id;
  final String? username;
  final String? email;
  final List<String>? albumArts;
  final List<String>? profileBio;
  final int? posts;
  final int? followers;
  final int? following;

  UserProfile({
    this.id,
    this.username,
    this.email,
    this.albumArts,
    this.profileBio,
    this.posts,
    this.followers,
    this.following,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      albumArts: json['albumArts'] != null
          ? List<String>.from(json['albumArts'])
          : [],
      profileBio: json['profileBio'] != null
          ? List<String>.from(json['profileBio'])
          : [],
      posts: json['posts'],
      followers: json['followers'],
      following: json['following'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'albumArts': albumArts,
      'profileBio': profileBio,
      'posts': posts,
      'followers': followers,
      'following': following,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    List<String>? albumArts,
    List<String>? profileBio,
    int? posts,
    int? followers,
    int? following,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      albumArts: albumArts ?? this.albumArts,
      profileBio: profileBio ?? this.profileBio,
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}
