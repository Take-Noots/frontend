import 'package:flutter/material.dart';
import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';

class FanbaseDetailsUserAbout extends StatefulWidget {
  final Fanbase fanbase;

  const FanbaseDetailsUserAbout({super.key, required this.fanbase});

  @override
  State<FanbaseDetailsUserAbout> createState() =>
      _FanbaseDetailsUserAboutState();
}

class _FanbaseDetailsUserAboutState extends State<FanbaseDetailsUserAbout> {
  List<String> rules = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRules();
  }

  Future<void> fetchRules() async {
    setState(() => loading = true);
    try {
      final fetched = await FanbaseService.getRules(widget.fanbase.id, context);
      setState(() {
        rules = fetched;
        loading = false;
      });
    } catch (_) {
      setState(() {
        rules = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.fanbase.fanbaseName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.fanbase.fanbaseTopic,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('${widget.fanbase.joinedUserIds.length} members',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text('Created by ${widget.fanbase.createdBy.username}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
              'Created on ${widget.fanbase.createdAt.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator()
              : rules.isEmpty
                  ? const Text('No rules set for this fanbase.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fanbase Rules:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...rules.asMap().entries.map((e) => ListTile(
                              leading: Text('${e.key + 1}.'),
                              title: Text(e.value),
                            )),
                      ],
                    ),
        ],
      ),
    );
  }
}
