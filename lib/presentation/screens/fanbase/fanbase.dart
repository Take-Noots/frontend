import 'package:flutter/material.dart';
import 'package:frontend/data/models/fanbase/fanbase_model.dart';
import 'package:frontend/data/services/fanbase/fanbase_service.dart';
import 'package:frontend/presentation/widgets/fanbases/fanbase_card.dart';

class FanbasePage extends StatefulWidget {
  const FanbasePage({super.key});

  @override
  State<FanbasePage> createState() => _FanbasePageState();
}

class _FanbasePageState extends State<FanbasePage> {
  late Future<List<Fanbase>> futureFanbases;

  @override
  void initState() {
    super.initState();
    futureFanbases = FanbaseService.getAllFanbases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Fanbases')
      ),
      body: FutureBuilder<List<Fanbase>>(
        future: futureFanbases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No fanbases found.'));
          }

          final fanbases = snapshot.data!;
          return ListView.builder(
            itemCount: fanbases.length,
            itemBuilder: (context, index) {
              final fanbase = fanbases[index];
              return FanbaseCard(
                fanbaseId: fanbase.id,
                profileImageUrl: fanbase.fanbasePhotoUrl,
                fanbaseName: fanbase.fanbaseName,
                topic: fanbase.fanbaseTopic,
                numLikes: fanbase.numLikes,
                numPosts: fanbase.numPosts,
                isJoined: false,
                onJoin: () {}, // TODO: Add join logic
              );
            },
          );
        },
      ),
    );
  }
}
