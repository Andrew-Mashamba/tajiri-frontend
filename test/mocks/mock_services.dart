import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tajiri/models/post_models.dart';
import 'package:tajiri/models/draft_models.dart';

/// Mock PostService for testing
class MockPostService {
  bool shouldSucceed = true;
  String? errorMessage;
  List<Post> createdPosts = [];

  Future<PostResult> createPost({
    required int userId,
    String? content,
    String? privacy,
    String? postType,
    List<File>? mediaFiles,
    File? audioFile,
    File? coverImage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!shouldSucceed) {
      return PostResult(
        success: false,
        message: errorMessage ?? 'Mock error',
      );
    }

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      content: content,
      postType: PostType.values.firstWhere(
        (t) => t.value == postType,
        orElse: () => PostType.text,
      ),
      privacy: PostPrivacy.values.firstWhere(
        (p) => p.value == privacy,
        orElse: () => PostPrivacy.public,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    createdPosts.add(post);

    return PostResult(
      success: true,
      message: 'Post created successfully',
      post: post,
    );
  }

  void reset() {
    shouldSucceed = true;
    errorMessage = null;
    createdPosts.clear();
  }
}

/// Mock DraftService for testing
class MockDraftService {
  bool shouldSucceed = true;
  String? errorMessage;
  List<PostDraft> drafts = [];
  int _nextId = 1;

  Future<DraftResult> saveDraft({
    required int userId,
    int? draftId,
    required DraftPostType postType,
    String? content,
    String? privacy,
    DateTime? scheduledAt,
    List<File>? mediaFiles,
    File? audioFile,
    File? coverImage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!shouldSucceed) {
      return DraftResult(
        success: false,
        message: errorMessage ?? 'Mock draft error',
      );
    }

    final draft = PostDraft(
      id: draftId ?? _nextId++,
      userId: userId,
      postType: postType,
      content: content,
      privacy: privacy ?? 'public',
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Update existing or add new
    final existingIndex = drafts.indexWhere((d) => d.id == draft.id);
    if (existingIndex >= 0) {
      drafts[existingIndex] = draft;
    } else {
      drafts.add(draft);
    }

    return DraftResult(
      success: true,
      message: 'Draft saved',
      draft: draft,
    );
  }

  Future<DraftResult> deleteDraft(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    drafts.removeWhere((d) => d.id == id);
    return DraftResult(success: true, message: 'Draft deleted');
  }

  Future<DraftResult> publishDraft(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!shouldSucceed) {
      return DraftResult(success: false, message: 'Publish failed');
    }

    final draft = drafts.firstWhere((d) => d.id == id, orElse: () => throw Exception('Draft not found'));

    if (draft.scheduledAt != null) {
      return DraftResult(success: true, message: 'Post scheduled for ${draft.scheduledAt}');
    }

    drafts.removeWhere((d) => d.id == id);
    return DraftResult(success: true, message: 'Post published');
  }

  Future<List<PostDraft>> getDrafts(int userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return drafts.where((d) => d.userId == userId).toList();
  }

  Future<DraftCounts> getDraftCounts(int userId) async {
    final userDrafts = drafts.where((d) => d.userId == userId);
    return DraftCounts(
      total: userDrafts.length,
      byType: {
        'text': userDrafts.where((d) => d.postType == DraftPostType.text).length,
        'photo': userDrafts.where((d) => d.postType == DraftPostType.photo).length,
        'video': userDrafts.where((d) => d.postType == DraftPostType.video).length,
        'short_video': userDrafts.where((d) => d.postType == DraftPostType.shortVideo).length,
        'audio': userDrafts.where((d) => d.postType == DraftPostType.audio).length,
      },
      scheduled: userDrafts.where((d) => d.scheduledAt != null).length,
    );
  }

  void dispose() {}

  void reset() {
    shouldSucceed = true;
    errorMessage = null;
    drafts.clear();
    _nextId = 1;
  }
}

/// Mock result classes
class PostResult {
  final bool success;
  final String? message;
  final Post? post;

  PostResult({required this.success, this.message, this.post});
}

class DraftResult {
  final bool success;
  final String? message;
  final PostDraft? draft;

  DraftResult({required this.success, this.message, this.draft});
}

/// Test wrapper widget
class TestWrapper extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;

  const TestWrapper({
    super.key,
    required this.child,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
      theme: theme ?? ThemeData.light(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Test user data
class TestUser {
  static const int id = 1;
  static const String name = 'Test User';
  static const String? photoUrl = null;
}
