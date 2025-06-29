import 'package:flutter/material.dart';

class InstagramSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onBack;

  const InstagramSearchBar({
    Key? key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Back arrow on the left
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color?.withOpacity(0.7)),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            // Expanded TextField
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  // Remove prefixIcon, move magnifier to the right
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: theme.iconTheme.color?.withOpacity(0.7)),
                          onPressed: onClear ?? () => controller.clear(),
                        ),
                      Icon(Icons.search, color: theme.iconTheme.color?.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}