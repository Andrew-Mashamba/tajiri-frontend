import 'package:flutter/material.dart';
import 'pages/incoming_customer_orders_page.dart';

class CustomerOrdersModule extends StatelessWidget {
  final int userId;
  const CustomerOrdersModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return IncomingCustomerOrdersPage(userId: userId);
  }
}
