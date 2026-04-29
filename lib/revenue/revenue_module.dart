import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/revenue_overview_page.dart';

class RevenueModule extends StatelessWidget {
  final int userId;
  const RevenueModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          RevenueOverviewPage(userId: uid, businesses: all),
    );
  }
}
