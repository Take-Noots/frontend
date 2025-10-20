import 'package:flutter/material.dart';

// Consistent color constant
const Color kPrimaryPurple = Color(0xFF8E08EF);

// Common button style for consistency
ButtonStyle _getElevatedButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kPrimaryPurple,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    minimumSize: const Size(double.infinity, 56),
  );
}

ButtonStyle _getOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: kPrimaryPurple,
    side: const BorderSide(
      color: kPrimaryPurple,
      width: 2,
    ),
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    minimumSize: const Size(double.infinity, 56),
  );
}

// Style for tab buttons with active/inactive states
ButtonStyle _getTabButtonStyle(BuildContext context, bool isActive) {
  return ElevatedButton.styleFrom(
    backgroundColor: isActive ? Colors.white : kPrimaryPurple,
    foregroundColor: isActive ? kPrimaryPurple : Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: kPrimaryPurple,
        width: isActive ? 2 : 0,
      ),
    ),
    elevation: isActive ? 4 : 0,
    minimumSize: const Size(double.infinity, 56),
  );
}

// Navigation buttons for switching between post types
class CustomBottomBar extends StatelessWidget {
  final VoidCallback onSharePost;
  final VoidCallback onShareThoughts;
  final VoidCallback? onMakeAdvertisements;
  final bool isSongPostActive; 
  final bool isThoughtsPostActive;

  const CustomBottomBar({
    Key? key,
    required this.onSharePost,
    required this.onShareThoughts,
    this.onMakeAdvertisements,
    this.isSongPostActive = false,
    this.isThoughtsPostActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSongPostActive ? null : onSharePost, 
                  style: _getTabButtonStyle(context, isSongPostActive),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 18,
                        color: isSongPostActive ? kPrimaryPurple : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Song Post',
                        style: TextStyle(
                          color: isSongPostActive ? kPrimaryPurple : Colors.white,
                          fontWeight: isSongPostActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isThoughtsPostActive ? null : onShareThoughts, 
                  style: _getTabButtonStyle(context, isThoughtsPostActive),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: isThoughtsPostActive ? kPrimaryPurple : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thoughts Post',
                        style: TextStyle(
                          color: isThoughtsPostActive ? kPrimaryPurple : Colors.white,
                          fontWeight: isThoughtsPostActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (onMakeAdvertisements != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onMakeAdvertisements,
              style: _getOutlinedButtonStyle(),
              child: const Text('Make Advertisements'),
            ),
          ],
        ],
      ),
    );
  }
}

// Reusable Preview Button
class PreviewButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const PreviewButton({
    Key? key,
    required this.onPressed,
    this.text = 'Preview',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: _getOutlinedButtonStyle(),
      child: Text(text),
    );
  }
}

// Reusable Share Button with loading state
class ShareButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const ShareButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Share',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _getElevatedButtonStyle(),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(text),
    );
  }
}

// Combined Preview and Share button row
class PreviewShareButtonRow extends StatelessWidget {
  final VoidCallback onPreview;
  final VoidCallback? onShare;
  final bool isLoading;
  final String previewText;
  final String shareText;

  const PreviewShareButtonRow({
    Key? key,
    required this.onPreview,
    required this.onShare,
    this.isLoading = false,
    this.previewText = 'Preview',
    this.shareText = 'Share',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: PreviewButton(
              onPressed: onPreview,
              text: previewText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShareButton(
              onPressed: onShare,
              isLoading: isLoading,
              text: shareText,
            ),
          ),
        ],
      ),
    );
  }
}
