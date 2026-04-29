import 'package:flutter/material.dart';
import '../business/biz_tab_wrapper.dart';
import 'pages/projects_page.dart';

class ProjectsModule extends StatelessWidget {
  final int userId;
  const ProjectsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BizTabWrapper(
      userId: userId,
      builder: (uid, all, first, fId) =>
          first != null ? ProjectsPage(businesses: all) : const SizedBox.shrink(),
    );
  }
}
