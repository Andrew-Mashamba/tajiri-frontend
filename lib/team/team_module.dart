import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/work_board_page.dart';

class TeamModule extends StatelessWidget {
  final int userId;
  const TeamModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          fId != null ? WorkBoardPage(businessId: fId, token: '') : const SizedBox.shrink(),
    );
  }
}
