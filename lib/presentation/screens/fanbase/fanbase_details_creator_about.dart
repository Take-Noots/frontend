import 'package:flutter/material.dart';
import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';

class FanbaseDetailsCreatorAbout extends StatefulWidget {
  final Fanbase fanbase;

  const FanbaseDetailsCreatorAbout({super.key, required this.fanbase});

  @override
  State<FanbaseDetailsCreatorAbout> createState() =>
      _FanbaseDetailsCreatorAboutState();
}

class _FanbaseDetailsCreatorAboutState
    extends State<FanbaseDetailsCreatorAbout> {
  List<String> rules = [];
  bool loading = true;
  bool saving = false;

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

  Future<void> removeRuleAt(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black
          .withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary ,
        title: const Text('Remove Rule'),
        content: Text('Are you sure you want to remove rule ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FanbaseService.removeRule(widget.fanbase.id, index, context);
        await fetchRules(); // Refresh the rules list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rule removed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove rule: $e')),
          );
        }
      }
    }
  }

  void showEditDialog() async {
    final controllers = List.generate(
      rules.isEmpty ? 1 : rules.length,
      (i) => TextEditingController(text: i < rules.length ? rules[i] : ''),
    );
    await showDialog(
      context: context,
      barrierColor: Colors.black
          .withOpacity(0.7), // ADD THIS LINE - makes background darker
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Fanbase Rules'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                        controllers.length,
                        (i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controllers[i],
                                      maxLength: 300,
                                      decoration: InputDecoration(
                                        labelText: 'Rule ${i + 1}',
                                      ),
                                    ),
                                  ),
                                  if (controllers.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 15),
                                      onPressed: () {
                                        setDialogState(() {
                                          controllers.removeAt(i);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            )),
                    if (controllers.length < 15)
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Rule'),
                        onPressed: () {
                          setDialogState(() {
                            controllers.add(TextEditingController());
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final newRules = controllers
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (newRules.isEmpty || newRules.length > 15) return;
                        setDialogState(() => saving = true);
                        try {
                          await FanbaseService.updateRules(
                              widget.fanbase.id, newRules, context);
                          setState(() {
                            rules = newRules;
                          });
                          Navigator.pop(context);
                        } catch (_) {
                          setDialogState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
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
          Center(
            child: ElevatedButton.icon(
              onPressed: showEditDialog,
              icon: const Icon(Icons.edit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              label: const Text('Add/Edit Fanbase Guide'),
            ),
          ),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator()
              : rules.isEmpty
                  ? const Text('No rules set yet.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fanbase Rules:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...rules.asMap().entries.map((e) => ListTile(
                              leading: Text('${e.key + 1}.'),
                              title: Text(e.value),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 15),
                                onPressed: () => removeRuleAt(e.key),
                                tooltip: 'Remove rule',
                              ),
                            )),
                      ],
                    ),
        ],
      ),
    );
  }
}
