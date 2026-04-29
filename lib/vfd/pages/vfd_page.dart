import 'package:flutter/material.dart';
import 'vfd_receipts_page.dart';

class VfdPage extends StatelessWidget {
  final int businessId;
  const VfdPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return VfdReceiptsPage(businessId: businessId);
  }
}
