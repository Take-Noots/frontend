class Fanbase {
  final String id;
  final String fanbaseName;
  final String fanbaseTopic;
  final String fanbasePhotoUrl;
  final int numLikes;
  final int numPosts;

  Fanbase({
    required this.id,
    required this.fanbaseName,
    required this.fanbaseTopic,
    required this.fanbasePhotoUrl,
    required this.numLikes,
    required this.numPosts,
  });

  factory Fanbase.fromJson(Map<String, dynamic> json) {
    return Fanbase(
      id: json['_id'],
      fanbaseName: json['fanbaseName'],
      fanbaseTopic: json['topic'],
      fanbasePhotoUrl: json['fanbasePhotoUrl'] ?? 'assets/images/favicon.png',
      numLikes: json['numberOfLikes'] ?? 0,
      numPosts: json['numberOfComments'] ?? 0,
    );
  }
}
