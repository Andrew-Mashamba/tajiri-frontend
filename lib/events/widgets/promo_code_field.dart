import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final bool isLoading;
  final bool? isValid;
  final String? message;
  const PromoCodeField({super.key, required this.controller, required this.onApply, this.isLoading = false, this.isValid, this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Msimbo wa punguzo',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: isValid == true ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isLoading ? null : onApply,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              child: isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tumia', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(message!, style: TextStyle(fontSize: 12, color: isValid == true ? Colors.green : Colors.red)),
        ],
      ],
    );
  }
}
