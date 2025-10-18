import 'package:flutter/material.dart';
import 'package:Noot/presentation/widgets/fanbases/fanbase_card.dart';

class FanbaseSearchResults extends StatelessWidget {
  final List<dynamic> fanbases;
  final String query;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const FanbaseSearchResults({
    Key? key,
    required this.fanbases,
    required this.query,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fanbases.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'Start typing to search for fanbases...'
              : 'No fanbases found for "$query"',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: fanbases.length,
      itemBuilder: (context, index) {
        final fanbase = fanbases[index];
        return FanbaseCard(
          // fanbaseId: fanbase['id'],
          // fanbaseName: fanbase['name'] ?? 'Unknown Fanbase',
          // topic: fanbase['topic'] ?? 'No topic',
          // profileImageUrl: fanbase['fanbasePhotoUrl'] ?? 'assets/images/hehe.png',
          // numLikes: fanbase['numberOfLikes'] ?? 0,
          // numPosts: fanbase['numberOfPosts'] ?? 0,
          // isJoined: false, // TODO: Implement isJoined logic
          // onJoin: () {}, // TODO: Implement onJoin logic
          onJoinStateChanged: () {
            // TODO: Implement onJoinStateChanged logic
          },
          initialFanbase: fanbase,
        );
      },
    );
  }
}
