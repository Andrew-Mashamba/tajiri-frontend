import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/tax_page.dart';

class TaxModule extends StatelessWidget {
  final int userId;
  const TaxModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          first != null ? TaxPage(businesses: all) : const SizedBox.shrink(),
    );
  }
}
