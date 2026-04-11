// lib/business/widgets/employee_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onRemoveTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
    this.onEditTap,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _kPrimary.withValues(alpha: 0.08),
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    employee.position ??
                        (sw ? 'Mfanyakazi' : 'Employee'),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${nf.format(employee.grossSalary)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  sw ? '/mwezi' : '/month',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
            if (onEditTap != null || onRemoveTap != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: _kSecondary),
                itemBuilder: (_) => [
                  if (onEditTap != null)
                    PopupMenuItem(
                        value: 'edit',
                        child: Text(sw ? 'Hariri' : 'Edit')),
                  if (onRemoveTap != null)
                    PopupMenuItem(
                        value: 'remove',
                        child: Text(sw ? 'Ondoa' : 'Remove',
                            style: const TextStyle(color: Colors.red))),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEditTap?.call();
                  if (v == 'remove') onRemoveTap?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
