import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';
import 'people_search_tab.dart';

// DESIGN.md: background #FAFAFA (match Messages)
const Color _kFriendsBg = Color(0xFFFAFAFA);

/// People (Watu): discover people via search. Navigation: Splash → Home → Bottom Nav [People] → FriendsScreen.
class FriendsScreen extends StatefulWidget {
  final int currentUserId;
  final bool isCurrentTab;

  const FriendsScreen({super.key, required this.currentUserId, this.isCurrentTab = false});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendService _friendService;
  late final MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _friendService = FriendService();
    _messageService = MessageService();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kFriendsBg,
      appBar: TajiriAppBar(
        title: s?.peopleTab ?? 'People',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: PeopleSearchTab(
          userId: widget.currentUserId,
          friendService: _friendService,
          messageService: _messageService,
          isCurrentTab: widget.isCurrentTab,
        ),
      ),
    );
  }
}
