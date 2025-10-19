class Advertisement {
  final String id;
  final String title;
  final String description;
  final String? image;
  final String? video;
  final String? contactDetails;
  final String? location;
  final String? genre;
  final String? hashtags;
  final String? keywords;
  final String userId;
  final int status;
  final int likesCount;
  final int commentsCount;
  final int payedViewsCount;
  final int remainViews;
  final int reqViews;
  final List<String> likedBy;
  final List<String> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.video,
    this.contactDetails,
    this.location,
    this.genre,
    this.hashtags,
    this.keywords,
    required this.userId,
    required this.status,
    required this.likesCount,
    required this.payedViewsCount,
    required this.remainViews,
    required this.reqViews,
    required this.commentsCount,
    required this.likedBy,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      video: json['video'],
      contactDetails: json['contactDetails'],
      location: json['location'],
      genre: json['genre'],
      hashtags: json['hashtags'],
      keywords: json['keywords'],
      userId: json['userId'],
      status: json['status'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      payedViewsCount: json['payedViewsCount'] ?? 0,
      remainViews: json['remainViews'] ?? 0,
      reqViews: json['reqViews'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'video': video,
      'contactDetails': contactDetails,
      'location': location,
      'genre': genre,
      'hashtags': hashtags,
      'keywords': keywords,
      'userId': userId,
      'status': status,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'payedViewsCount': payedViewsCount,
      'remainViews': remainViews,
      'reqViews': reqViews,
      'likedBy': likedBy,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
