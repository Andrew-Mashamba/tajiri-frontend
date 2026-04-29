import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/business_transactions_page.dart';

class TransactionsModule extends StatelessWidget {
  final int userId;
  const TransactionsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          fId != null ? BusinessTransactionsPage(businessId: fId) : const SizedBox.shrink(),
    );
  }
}
