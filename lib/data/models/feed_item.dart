import 'post_model.dart' as data_model;
import 'thoughts_model.dart';

enum FeedItemType { song, thought }

class FeedItem {
  final FeedItemType type;
  final data_model.Post? songPost;
  final ThoughtsPost? thoughtsPost;
  final DateTime createdAt;

  FeedItem.song(data_model.Post post)
      : type = FeedItemType.song,
        songPost = post,
        thoughtsPost = null,
        createdAt = post.createdAt;

  FeedItem.thought(ThoughtsPost post)
      : type = FeedItemType.thought,
        songPost = null,
        thoughtsPost = post,
        createdAt = post.createdAt;
}
