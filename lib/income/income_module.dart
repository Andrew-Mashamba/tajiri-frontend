import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/income_overview_page.dart';

class IncomeModule extends StatelessWidget {
  final int userId;
  const IncomeModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          IncomeOverviewPage(userId: uid, businesses: all),
    );
  }
}
