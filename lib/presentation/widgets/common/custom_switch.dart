import 'package:flutter/material.dart';
import '../../../core/styles/app_colors.dart';

/// Custom switch with outline for active state
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryPurple.withOpacity(0.2)
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppColors.primaryPurple : Colors.grey.shade500,
            width: 1.2, // Match thickness for both states
          ),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primaryPurple
                  : (isDark ? Colors.grey.shade800 : Colors.white),
              shape: BoxShape.circle,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
