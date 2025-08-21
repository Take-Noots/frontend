import 'package:flutter/material.dart';
import '../../../data/services/thoughts_service.dart';

class ThoughtsScreen extends StatefulWidget {
  const ThoughtsScreen({Key? key}) : super(key: key);

  @override
  State<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends State<ThoughtsScreen> {
  final TextEditingController _thoughtsController = TextEditingController();
  final ThoughtsService _thoughtsService = ThoughtsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _thoughtsController.dispose();
    super.dispose();
  }

  Future<void> _shareThoughts() async {
    final thoughtsText = _thoughtsController.text.trim();
    if (thoughtsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your thoughts before sharing'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _thoughtsService.createThoughts(
        text: thoughtsText,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Thoughts shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _thoughtsController.clear();
        // Optionally navigate back or refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to share thoughts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sharing thoughts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing thoughts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Thoughts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'What\'s on your mind?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your thoughts, ideas, or anything you\'d like to discuss with your followers.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Thoughts input area
            Expanded(
              child: TextField(
                controller: _thoughtsController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Share button
            ElevatedButton(
              onPressed: _isLoading ? null : _shareThoughts,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Share Thoughts',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
