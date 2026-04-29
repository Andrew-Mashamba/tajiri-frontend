import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/expenses_page.dart';

class ExpensesModule extends StatelessWidget {
  final int userId;
  const ExpensesModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          fId != null ? ExpensesPage(businessId: fId) : const SizedBox.shrink(),
    );
  }
}
