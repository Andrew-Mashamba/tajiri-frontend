import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/crb_overview_page.dart';

class CrbModule extends StatelessWidget {
  final int userId;
  const CrbModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          CrbOverviewPage(userId: uid, businesses: all),
    );
  }
}
