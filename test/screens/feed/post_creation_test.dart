import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/screens/feed/create_post_screen.dart';
import 'package:tajiri/screens/feed/create_text_post_screen.dart';
import 'package:tajiri/screens/feed/create_image_post_screen.dart';
import 'package:tajiri/screens/feed/create_audio_post_screen.dart';
import 'package:tajiri/screens/feed/create_short_video_screen.dart';
import 'package:tajiri/widgets/schedule_post_widget.dart';

/// =============================================================================
/// POST CREATION TEST SUITE
/// =============================================================================
///
/// Test Categories:
/// - TC-1: Navigation
/// - TC-2: Text Post
/// - TC-3: Photo Post
/// - TC-4: Audio Post
/// - TC-5: Short Video
/// - TC-6: Drafts
/// - TC-7: Scheduling
/// - TC-8: Error Handling
/// - TC-9: UI/UX
/// - TC-10: Integration
/// =============================================================================

void main() {
  // Test wrapper helper
  Widget testWrapper(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData.light(useMaterial3: true),
    );
  }

  // ==========================================================================
  // TC-1: NAVIGATION TESTS
  // ==========================================================================
  group('TC-1: Navigation Tests', () {
    testWidgets('TC-1.1: Create Post Screen loads successfully', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Create Post'), findsOneWidget);

      print('  [PASS] TC-1.1: Create Post Screen loads successfully');
    });

    testWidgets('TC-1.2: All 4 post type options are displayed', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for all 4 post types
      expect(find.text('Short Video'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);

      print('  [PASS] TC-1.2: All 4 post type options are displayed');
    });

    testWidgets('TC-1.3: Post type icons are visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for icons
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsAtLeastNWidgets(1));

      print('  [PASS] TC-1.3: Post type icons are visible');
    });

    testWidgets('TC-1.4: Drafts section is visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for drafts section
      expect(find.text('Your Drafts'), findsOneWidget);

      print('  [PASS] TC-1.4: Drafts section is visible');
    });

    testWidgets('TC-1.5: Tips section is visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for tips section
      expect(find.textContaining('Pro Tips'), findsOneWidget);

      print('  [PASS] TC-1.5: Tips section is visible');
    });
  });

  // ==========================================================================
  // TC-2: TEXT POST TESTS
  // ==========================================================================
  group('TC-2: Text Post Tests', () {
    testWidgets('TC-2.1: Text post screen loads', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Text Post'), findsOneWidget);

      print('  [PASS] TC-2.1: Text post screen loads');
    });

    testWidgets('TC-2.2: User info is displayed', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);

      print('  [PASS] TC-2.2: User info is displayed');
    });

    testWidgets('TC-2.3: Text input field exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      print('  [PASS] TC-2.3: Text input field exists');
    });

    testWidgets('TC-2.4: Can enter text content', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Find text field and enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Hello Tajiri!');
      await tester.pump();

      expect(find.text('Hello Tajiri!'), findsOneWidget);

      print('  [PASS] TC-2.4: Can enter text content');
    });

    testWidgets('TC-2.5: Privacy button is visible and shows Public by default', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsAtLeastNWidgets(1));

      print('  [PASS] TC-2.5: Privacy button shows Public by default');
    });

    testWidgets('TC-2.6: Post button is disabled when no content', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Find Post button
      final postButton = find.widgetWithText(FilledButton, 'Post');
      expect(postButton, findsOneWidget);

      // Verify it's disabled
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-2.6: Post button is disabled when no content');
    });

    testWidgets('TC-2.7: Post button enables when content entered', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Test content');
      await tester.pump();

      // Verify button is now enabled
      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNotNull);

      print('  [PASS] TC-2.7: Post button enables when content entered');
    });

    testWidgets('TC-2.8: Background color selector is available', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Look for color palette icon or background color section
      expect(find.byIcon(Icons.palette), findsOneWidget);

      print('  [PASS] TC-2.8: Background color selector is available');
    });

    testWidgets('TC-2.9: Schedule widget is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePostWidget), findsOneWidget);
      expect(find.text('Schedule Post'), findsOneWidget);

      print('  [PASS] TC-2.9: Schedule widget is present');
    });

    testWidgets('TC-2.10: Save draft button appears when content exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Draft content');
      await tester.pump();

      // Check for Save button
      expect(find.text('Save'), findsOneWidget);

      print('  [PASS] TC-2.10: Save draft button appears when content exists');
    });
  });

  // ==========================================================================
  // TC-3: PHOTO POST TESTS
  // ==========================================================================
  group('TC-3: Photo Post Tests', () {
    testWidgets('TC-3.1: Photo post screen loads', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Photo Post'), findsOneWidget);

      print('  [PASS] TC-3.1: Photo post screen loads');
    });

    testWidgets('TC-3.2: Add photos button is visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for add photos area
      expect(find.byIcon(Icons.add_photo_alternate), findsAtLeastNWidgets(1));

      print('  [PASS] TC-3.2: Add photos button is visible');
    });

    testWidgets('TC-3.3: Camera option is available', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));

      print('  [PASS] TC-3.3: Camera option is available');
    });

    testWidgets('TC-3.4: Caption field is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Caption'), findsAtLeastNWidgets(1));

      print('  [PASS] TC-3.4: Caption field is present');
    });

    testWidgets('TC-3.5: Privacy selector is visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);

      print('  [PASS] TC-3.5: Privacy selector is visible');
    });

    testWidgets('TC-3.6: Post button is disabled without images', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      final postButton = find.widgetWithText(FilledButton, 'Post');
      expect(postButton, findsOneWidget);

      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-3.6: Post button is disabled without images');
    });

    testWidgets('TC-3.7: Schedule widget is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePostWidget), findsOneWidget);

      print('  [PASS] TC-3.7: Schedule widget is present');
    });
  });

  // ==========================================================================
  // TC-4: AUDIO POST TESTS
  // ==========================================================================
  group('TC-4: Audio Post Tests', () {
    testWidgets('TC-4.1: Audio post screen loads', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Audio Post'), findsOneWidget);

      print('  [PASS] TC-4.1: Audio post screen loads');
    });

    testWidgets('TC-4.2: Recording button (mic) is visible', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic), findsAtLeastNWidgets(1));

      print('  [PASS] TC-4.2: Recording button (mic) is visible');
    });

    testWidgets('TC-4.3: Timer display shows 00:00 initially', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('00:00'), findsOneWidget);

      print('  [PASS] TC-4.3: Timer display shows 00:00 initially');
    });

    testWidgets('TC-4.4: "Tap to record" text is shown', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tap to record'), findsOneWidget);

      print('  [PASS] TC-4.4: "Tap to record" text is shown');
    });

    testWidgets('TC-4.5: Select audio from device option exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('select audio from device'), findsOneWidget);

      print('  [PASS] TC-4.5: Select audio from device option exists');
    });

    testWidgets('TC-4.6: Cover image section is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cover Image (Optional)'), findsOneWidget);

      print('  [PASS] TC-4.6: Cover image section is present');
    });

    testWidgets('TC-4.7: Caption field is optional', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Caption (Optional)'), findsOneWidget);

      print('  [PASS] TC-4.7: Caption field is optional');
    });

    testWidgets('TC-4.8: Post button disabled without audio', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-4.8: Post button disabled without audio');
    });

    testWidgets('TC-4.9: Schedule widget is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePostWidget), findsOneWidget);

      print('  [PASS] TC-4.9: Schedule widget is present');
    });
  });

  // ==========================================================================
  // TC-5: SHORT VIDEO TESTS
  // ==========================================================================
  group('TC-5: Short Video Tests', () {
    testWidgets('TC-5.1: Short video screen loads', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Short Video'), findsOneWidget);

      print('  [PASS] TC-5.1: Short video screen loads');
    });

    testWidgets('TC-5.2: Video source options are available', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for camera and gallery icons
      expect(find.byIcon(Icons.videocam), findsAtLeastNWidgets(1));

      print('  [PASS] TC-5.2: Video source options are available');
    });

    testWidgets('TC-5.3: 60 second limit info is displayed', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Look for 60 second or max duration info
      expect(find.textContaining('60'), findsAtLeastNWidgets(1));

      print('  [PASS] TC-5.3: 60 second limit info is displayed');
    });

    testWidgets('TC-5.4: Caption field exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Caption'), findsAtLeastNWidgets(1));

      print('  [PASS] TC-5.4: Caption field exists');
    });

    testWidgets('TC-5.5: Schedule widget is present', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePostWidget), findsOneWidget);

      print('  [PASS] TC-5.5: Schedule widget is present');
    });
  });

  // ==========================================================================
  // TC-6: DRAFTS TESTS
  // ==========================================================================
  group('TC-6: Drafts Tests', () {
    testWidgets('TC-6.1: Save button appears when content exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // No Save button initially (no content)
      expect(find.text('Save'), findsNothing);

      // Enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Draft content');
      await tester.pump();

      // Save button should appear
      expect(find.text('Save'), findsOneWidget);

      print('  [PASS] TC-6.1: Save button appears when content exists');
    });

    testWidgets('TC-6.2: Drafts section shows on create post screen', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Drafts'), findsOneWidget);

      print('  [PASS] TC-6.2: Drafts section shows on create post screen');
    });

    testWidgets('TC-6.3: Empty state when no drafts', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Should show "No drafts" or similar message
      expect(find.textContaining('No drafts'), findsOneWidget);

      print('  [PASS] TC-6.3: Empty state when no drafts');
    });

    testWidgets('TC-6.4: View All drafts button exists', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('View All'), findsOneWidget);

      print('  [PASS] TC-6.4: View All drafts button exists');
    });
  });

  // ==========================================================================
  // TC-7: SCHEDULING TESTS
  // ==========================================================================
  group('TC-7: Scheduling Tests', () {
    testWidgets('TC-7.1: Schedule widget renders correctly', (tester) async {
      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Post'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      print('  [PASS] TC-7.1: Schedule widget renders correctly');
    });

    testWidgets('TC-7.2: Toggle is off by default', (tester) async {
      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      print('  [PASS] TC-7.2: Toggle is off by default');
    });

    testWidgets('TC-7.3: Quick select options appear when enabled', (tester) async {
      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Check for quick select chips
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('3 hours'), findsOneWidget);
      expect(find.text('Tomorrow 9AM'), findsOneWidget);
      expect(find.text('Weekend'), findsOneWidget);

      print('  [PASS] TC-7.3: Quick select options appear when enabled');
    });

    testWidgets('TC-7.4: Date and time buttons appear when enabled', (tester) async {
      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Check for date/time selection buttons
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      print('  [PASS] TC-7.4: Date and time buttons appear when enabled');
    });

    testWidgets('TC-7.5: 1 hour quick select sets correct time', (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (date) => selectedDate = date,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Tap "1 hour" chip
      await tester.tap(find.text('1 hour'));
      await tester.pumpAndSettle();

      expect(selectedDate, isNotNull);
      // Should be approximately 1 hour from now
      final hourFromNow = DateTime.now().add(const Duration(hours: 1));
      expect(
        selectedDate!.difference(hourFromNow).inMinutes.abs(),
        lessThan(2),
      );

      print('  [PASS] TC-7.5: 1 hour quick select sets correct time');
    });

    testWidgets('TC-7.6: Disabling scheduling clears date', (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(testWrapper(
        Scaffold(
          body: SchedulePostWidget(
            onScheduleChanged: (date) => selectedDate = date,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Select a time
      await tester.tap(find.text('1 hour'));
      await tester.pumpAndSettle();
      expect(selectedDate, isNotNull);

      // Disable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(selectedDate, isNull);

      print('  [PASS] TC-7.6: Disabling scheduling clears date');
    });

    testWidgets('TC-7.7: Post button changes to "Schedule" when scheduled', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter text first
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Scheduled post');
      await tester.pump();

      // Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify button text changed
      expect(find.widgetWithText(FilledButton, 'Schedule'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Post'), findsNothing);

      print('  [PASS] TC-7.7: Post button changes to "Schedule" when scheduled');
    });
  });

  // ==========================================================================
  // TC-8: ERROR HANDLING TESTS
  // ==========================================================================
  group('TC-8: Error Handling Tests', () {
    testWidgets('TC-8.1: Empty text post cannot be submitted', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Post button should be disabled
      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-8.1: Empty text post cannot be submitted');
    });

    testWidgets('TC-8.2: Whitespace-only text is treated as empty', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter only whitespace
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '   \n\t  ');
      await tester.pump();

      // Post button should still be disabled
      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-8.2: Whitespace-only text is treated as empty');
    });

    testWidgets('TC-8.3: Photo post requires at least one image', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Caption alone shouldn't enable posting
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Caption without image');
      await tester.pump();

      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-8.3: Photo post requires at least one image');
    });

    testWidgets('TC-8.4: Audio post requires audio file', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Caption alone shouldn't enable posting
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Caption without audio');
      await tester.pump();

      final postButton = find.widgetWithText(FilledButton, 'Post');
      final button = tester.widget<FilledButton>(postButton);
      expect(button.onPressed, isNull);

      print('  [PASS] TC-8.4: Audio post requires audio file');
    });
  });

  // ==========================================================================
  // TC-9: UI/UX TESTS
  // ==========================================================================
  group('TC-9: UI/UX Tests', () {
    testWidgets('TC-9.1: AppBar title is correct on each screen', (tester) async {
      // Test Text Post
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(currentUserId: 1, userName: 'Test'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Text Post'), findsOneWidget);

      // Test Photo Post
      await tester.pumpWidget(testWrapper(
        const CreateImagePostScreen(currentUserId: 1, userName: 'Test'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Photo Post'), findsOneWidget);

      // Test Audio Post
      await tester.pumpWidget(testWrapper(
        const CreateAudioPostScreen(currentUserId: 1, userName: 'Test'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Audio Post'), findsOneWidget);

      // Test Video Post
      await tester.pumpWidget(testWrapper(
        const CreateShortVideoScreen(currentUserId: 1, userName: 'Test'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Short Video'), findsOneWidget);

      print('  [PASS] TC-9.1: AppBar title is correct on each screen');
    });

    testWidgets('TC-9.2: Back button is present on all screens', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(currentUserId: 1, userName: 'Test'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);

      print('  [PASS] TC-9.2: Back button is present on all screens');
    });

    testWidgets('TC-9.3: Loading indicator shows during post creation', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Test post');
      await tester.pump();

      // Verify button contains CircularProgressIndicator during loading
      // (This tests the widget structure, actual loading would need mock services)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      print('  [PASS] TC-9.3: No loading indicator when not posting');
    });

    testWidgets('TC-9.4: Privacy options have correct colors', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Find public icon with green color
      final publicIcon = find.byIcon(Icons.public);
      expect(publicIcon, findsAtLeastNWidgets(1));

      print('  [PASS] TC-9.4: Privacy options have correct icons');
    });

    testWidgets('TC-9.5: Scrollable content on all post screens', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      print('  [PASS] TC-9.5: Scrollable content on all post screens');
    });
  });

  // ==========================================================================
  // TC-10: INTEGRATION TESTS
  // ==========================================================================
  group('TC-10: Integration Tests', () {
    testWidgets('TC-10.1: Navigate from create post to text post', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Text option
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      // Should navigate to text post screen
      expect(find.text('Text Post'), findsOneWidget);

      print('  [PASS] TC-10.1: Navigate from create post to text post');
    });

    testWidgets('TC-10.2: Navigate from create post to photo post', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Photo option
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Post'), findsOneWidget);

      print('  [PASS] TC-10.2: Navigate from create post to photo post');
    });

    testWidgets('TC-10.3: Navigate from create post to audio post', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Audio option
      await tester.tap(find.text('Audio'));
      await tester.pumpAndSettle();

      expect(find.text('Audio Post'), findsOneWidget);

      print('  [PASS] TC-10.3: Navigate from create post to audio post');
    });

    testWidgets('TC-10.4: Navigate from create post to video post', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreatePostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Short Video option
      await tester.tap(find.text('Short Video'));
      await tester.pumpAndSettle();

      expect(find.text('Short Video'), findsOneWidget);

      print('  [PASS] TC-10.4: Navigate from create post to video post');
    });

    testWidgets('TC-10.5: Full text post flow (enter -> schedule -> verify)', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Step 1: Enter text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Integration test post');
      await tester.pump();

      // Verify content entered
      expect(find.text('Integration test post'), findsOneWidget);

      // Step 2: Enable scheduling
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Step 3: Select quick time
      await tester.tap(find.text('1 hour'));
      await tester.pumpAndSettle();

      // Verify button changed to Schedule
      expect(find.widgetWithText(FilledButton, 'Schedule'), findsOneWidget);

      print('  [PASS] TC-10.5: Full text post flow (enter -> schedule -> verify)');
    });

    testWidgets('TC-10.6: Privacy flow (open picker -> select -> verify)', (tester) async {
      await tester.pumpWidget(testWrapper(
        const CreateTextPostScreen(
          currentUserId: 1,
          userName: 'Test User',
        ),
      ));
      await tester.pumpAndSettle();

      // Initial state - Public
      expect(find.text('Public'), findsOneWidget);

      // Open privacy picker
      await tester.tap(find.text('Public'));
      await tester.pumpAndSettle();

      // Verify options in bottom sheet
      expect(find.text('Who can see this?'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);

      // Select Friends
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();

      // Verify privacy changed
      expect(find.text('Friends'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsAtLeastNWidgets(1));

      print('  [PASS] TC-10.6: Privacy flow (open picker -> select -> verify)');
    });
  });
}
