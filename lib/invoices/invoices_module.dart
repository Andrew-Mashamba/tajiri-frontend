import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/invoices_page.dart';

class InvoicesModule extends StatelessWidget {
  final int userId;
  const InvoicesModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          fId != null ? InvoicesPage(businessId: fId) : const SizedBox.shrink(),
    );
  }
}
