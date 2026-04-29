import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/biz_services_page.dart';

class BizServicesModule extends StatelessWidget {
  final int userId;
  const BizServicesModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          first != null ? BizServicesPage(businessId: fId!, business: first, showAppBar: true) : const SizedBox.shrink(),
    );
  }
}
