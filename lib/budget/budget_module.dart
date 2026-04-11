import 'package:flutter/material.dart';
import 'pages/budget_home_page.dart';

class BudgetModule extends StatelessWidget {
  final int userId;
  const BudgetModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BudgetHomePage(userId: userId);
  }
}
