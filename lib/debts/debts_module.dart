import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/debts_overview_page.dart';

class DebtsModule extends StatelessWidget {
  final int userId;
  const DebtsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          DebtsOverviewPage(userId: uid, businesses: all),
    );
  }
}
