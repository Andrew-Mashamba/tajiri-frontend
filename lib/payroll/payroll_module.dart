import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/payroll_home_page.dart';

class PayrollModule extends StatelessWidget {
  final int userId;
  const PayrollModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          fId != null ? PayrollHomePage(businessId: fId) : const SizedBox.shrink(),
    );
  }
}
