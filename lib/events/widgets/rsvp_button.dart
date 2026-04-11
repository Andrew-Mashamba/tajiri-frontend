import 'package:flutter/material.dart';
import '../models/event_enums.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class RSVPButton extends StatelessWidget {
  final RSVPStatus status;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool compact;

  const RSVPButton({
    super.key,
    required this.status,
    this.isSelected = false,
    this.isLoading = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: compact ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kPrimary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSelected ? Colors.white : _kPrimary,
                ),
              )
            else ...[
              Icon(
                status.icon,
                size: 18,
                color: isSelected ? Colors.white : _kPrimary,
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _kPrimary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
