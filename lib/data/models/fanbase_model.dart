class Creator {
  final String id;
  final String username;

  Creator({
    required this.id,
    required this.username,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
    };
  }
}

class Fanbase {
  final String id;
  final String fanbaseName;
  final String fanbaseTopic;
  final String? fanbasePhotoUrl;
  final int numLikes;
  final List<String> likedUserIds;
  final bool isLiked; 
  final int numPosts;
  final List<String> postIds;
  final List<String> joinedUserIds;
  final bool isJoined;
  final int numShares;
  final DateTime createdAt;
  final Creator createdBy;

  Fanbase({
    required this.id,
    required this.fanbaseName,
    required this.fanbaseTopic,
    this.fanbasePhotoUrl,
    required this.numLikes,
    required this.likedUserIds,
    required this.isLiked, 
    required this.numPosts,
    required this.postIds,
    required this.joinedUserIds,
    required this.isJoined, 
    required this.numShares,
    required this.createdAt,
    required this.createdBy,
  });

  // Convenience getters for backward compatibility
  String get userName => createdBy.username;
  String get userId => createdBy.id;

  factory Fanbase.fromJson(Map<String, dynamic> json) {
    return Fanbase(
      id: json['_id'] ?? '',
      fanbaseName: json['fanbaseName'] ?? '',
      fanbaseTopic: json['topic'] ?? '',
      fanbasePhotoUrl: json['fanbasePhotoUrl'],
      numLikes: json['numberOfLikes'] ?? 0,
      likedUserIds: List<String>.from(json['likedUserIds'] ?? []),
      isLiked: json['isJoined'] ?? false, 
      numPosts: json['numberOfPosts'] ?? 0,
      postIds: List<String>.from(json['postIds'] ?? []),
      joinedUserIds: List<String>.from(json['joinedUserIds'] ?? []),
      isJoined: json['isJoined'] ?? false, 
      numShares: json['numberOfShares'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      createdBy: json['createdBy'] != null
          ? Creator.fromJson(json['createdBy'])
          : Creator(id: 'unknown', username: 'Unknown User'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fanbaseName': fanbaseName,
      'topic': fanbaseTopic,
      if (fanbasePhotoUrl != null) 'fanbasePhotoUrl': fanbasePhotoUrl,
      'numberOfLikes': numLikes,
      'likedUserIds': likedUserIds,
      'isLiked': isJoined, 
      'numberOfPosts': numPosts,
      'postIds': postIds,
      'joinedUserIds': joinedUserIds,
      'isJoined': isJoined,
      'numberOfShares': numShares,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy.toJson(),
    };
  }
}
