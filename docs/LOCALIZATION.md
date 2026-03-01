# TAJIRI App Localization (Spoken English & Spoken Swahili)

## Overview

The app supports two display languages:

- **English** (default) – Spoken/street English
- **Kiswahili** – Spoken/street Swahili (Kiswahili ya mtaani)

The user can switch language in **Profile → Settings → Language**. The choice is stored locally and applied app-wide.

## Implementation

### Infrastructure

- **`lib/l10n/app_strings.dart`** – All UI strings for both languages. Add new getters here when converting a screen.
- **`lib/l10n/app_strings_scope.dart`** – `InheritedWidget` that provides `AppStrings` to the tree. Use `AppStringsScope.of(context)` to get the current `AppStrings?`.
- **`lib/services/language_notifier.dart`** – Global notifier for current language (`'en'` or `'sw'`). Changing language here triggers a rebuild.
- **`lib/services/local_storage_service.dart`** – Persists language with `getLanguageCode()` / `saveLanguageCode('en'|'sw')`.

### How to use in a screen

1. In `build(BuildContext context)` get strings:
   ```dart
   final s = AppStringsScope.of(context);
   if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
   ```
2. Use `s.` getters for all user-facing text, e.g. `s.settings`, `s.profile`, `s.homeTab`.
3. For strings that don’t exist yet, add them to `lib/l10n/app_strings.dart` (English and Swahili), then use `s.newKey`.

### Already converted

- **Main & shell:** `main.dart` (locale + `AppStringsScope`), profile fallback route
- **Home:** `home_screen.dart` (bottom nav: Home, Friends, Messages, Photos, Me)
- **Splash:** `splash_screen.dart` (app name, tagline)
- **Login:** `login_screen.dart` (welcome, subtitle, Create account, Sign in)
- **Settings:** `settings_screen.dart` (all sections, language picker, logout/delete dialogs)
- **Registration:** `registration_screen.dart`, `steps/bio_step.dart`, `steps/phone_step.dart`, `steps/education_path_step.dart`, `phonestep_screen.dart`
- **Feed:** `feed_screen.dart`, `saved_posts_screen.dart`, `post_detail_screen.dart`, `edit_post_screen.dart`, `create_post_screen.dart` (tabs, FAB, saved/delete dialogs, empty states, edit post form & privacy; create post types, drafts, tips, scheduled)
- **Friends:** `friends_screen.dart` (tabs: Friends, Requests, Suggestions; search tooltip)
- **Messages:** `conversations_screen.dart` (title, new message/create group sheet, empty state, retry, message previews)
- **Profile:** `profile_screen.dart` (menu, dialogs, snackbars, stats, action buttons, story highlights, joined/mutual), `edit_profile_screen.dart` (form labels, save/retry, profile saved/failed)

### Remaining screens (to convert)

Use the same pattern: `final s = AppStringsScope.of(context);` and replace every hardcoded user-visible string with `s.someKey`. Add missing keys to `app_strings.dart`.

**Feed:** discover_feed_content, comment_bottom_sheet, post_card, share_post_sheet, schedule_post_widget  
**Profile:** (done)  
**Privacy:** privacy_settings_screen  
**Messages:** chat_screen  
**Photos:** photos_screen, album_detail_screen  
**Clips/Stories:** clips_screen, streams_screen (clips), streamviewer_screen, createstory_screen, story_highlights_screen, create_highlight_screen, add_to_highlight_screen, clip_player_screen, golive_screen, musicupload_screen, create_clip_screen, video_search_screen, livestreamsgrid_screen, livegallerywidget_screen, musicgallerywidget_screen, videogallerywidget_screen, etc.  
**Music:** music_screen, music_library_screen, artist_detail_screen, music_upload_screen  
**Streams:** streams_screen (streams), live_broadcast_screen, backstage_screen, standby_screen, go_live_screen  
**Wallet:** wallet_screen, send_tip_screen, subscribe_to_creator_screen, subscription_tiers_setup_screen  
**Campaigns:** create_campaign_screen, donate_to_campaign_screen, campaign_withdraw_screen, michango_gallery_widget  
**Groups:** groups_screen, group_detail_screen, create_group_screen, create_group_post_screen, createpoll_screen, createevent_screen  
**Events:** events_screen, event_detail_screen, event_attendees_screen, create_event_screen  
**Pages:** pages_screen, page_detail_screen, create_page_screen  
**Polls:** polls_screen, poll_detail_screen, create_poll_screen  
**Search:** search_screen, hashtag_screen, user_search_tab  
**Calls:** call_history_screen (messages), call_history_screen (calls), group_call_screen  
**Other:** username_settings_screen, profile_tabs_settings_screen, locationpicker_screen, registration steps (location, primary_school, secondary_school, alevel, postsecondary, university, employer)

## Adding new strings

1. Open `lib/l10n/app_strings.dart`.
2. Add a getter, e.g. `String get myNewLabel => isSwahili ? 'Kiswahili text' : 'English text';`
3. In the screen: `Text(s.myNewLabel)`.

Keep wording **spoken/street** in both languages (casual, clear, short where possible).
