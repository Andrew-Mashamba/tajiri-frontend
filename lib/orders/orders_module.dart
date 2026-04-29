import 'package:flutter/material.dart';
import 'pages/incoming_orders_page.dart';

class OrdersModule extends StatelessWidget {
  final int userId;
  const OrdersModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return IncomingOrdersPage(userId: userId);
  }
}
