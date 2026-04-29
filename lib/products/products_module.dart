import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/products_page.dart';

class ProductsModule extends StatelessWidget {
  final int userId;
  const ProductsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          first != null ? ProductsPage(businessId: fId!, business: first, isDefaultShop: false) : const SizedBox.shrink(),
    );
  }
}
