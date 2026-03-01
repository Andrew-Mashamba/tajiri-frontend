# Post Creation Test Script

**Feature:** Tengeneza Posti (Create Post)
**Version:** 1.0
**Date:** January 2026
**Tester:** _______________

---

## Test Environment Setup

### Prerequisites
- [ ] Flutter app is running on device/emulator
- [ ] Backend server is running and accessible
- [ ] User is logged in with valid account
- [ ] Device has camera, microphone, and storage permissions enabled
- [ ] Device has sample images, videos, and audio files for testing

### Test Device Information
| Field | Value |
|-------|-------|
| Device Model | |
| OS Version | |
| App Version | |
| Backend URL | |
| Test Date | |

---

## Test Case 1: Create Post Screen Navigation

### TC-1.1: Access Create Post Screen
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap the "+" or "Create Post" button from main feed | Create Post screen opens | |
| 2 | Verify screen title | Shows "Create Post" in app bar | |
| 3 | Verify 4 post type options are displayed | See: Short Video, Photo, Text, Audio | |
| 4 | Verify drafts section is visible | "Your Drafts" section shown (or empty state) | |

### TC-1.2: Post Type Grid Layout
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Verify Short Video tile | Shows video icon, "Short Video" label, description | |
| 2 | Verify Photo tile | Shows image icon, "Photo" label, description | |
| 3 | Verify Text tile | Shows text icon, "Text" label, description | |
| 4 | Verify Audio tile | Shows mic icon, "Audio" label, description | |
| 5 | Tap each tile | Navigates to respective creation screen | |

---

## Test Case 2: Text Post Creation

### TC-2.1: Basic Text Post
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap "Text" from create post screen | Text post creation screen opens | |
| 2 | Verify user avatar and name displayed | Shows current user info | |
| 3 | Verify privacy button is visible | Shows "Public" by default | |
| 4 | Enter text: "Test post from Tajiri app" | Text appears in input field | |
| 5 | Verify character count updates | Shows character count | |
| 6 | Verify "Post" button becomes enabled | Button is clickable | |
| 7 | Tap "Post" button | Post is created, returns to feed | |
| 8 | Verify success message | Shows "Post created successfully" | |
| 9 | Verify post appears in feed | New text post visible | |

### TC-2.2: Text Post with Background Color
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open text post creation | Screen opens | |
| 2 | Enter short text (under 200 chars) | Text entered | |
| 3 | Tap background color button | Color picker appears | |
| 4 | Select a color (e.g., blue) | Background changes to selected color | |
| 5 | Preview shows colored background | Text displayed on colored card | |
| 6 | Post the text | Post created with background color | |

### TC-2.3: Text Post Privacy Settings
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open text post creation | Screen opens | |
| 2 | Tap privacy button (shows "Public") | Privacy bottom sheet opens | |
| 3 | Verify 3 options shown | Public, Friends, Private visible | |
| 4 | Select "Friends" | Sheet closes, button shows "Friends" | |
| 5 | Select "Private" | Button shows "Private" with lock icon | |
| 6 | Post with Private setting | Post created (verify in feed visibility) | |

---

## Test Case 3: Photo Post Creation

### TC-3.1: Single Image Post
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap "Photo" from create post screen | Photo post creation screen opens | |
| 2 | Tap "Add Photos" or gallery button | Image picker opens | |
| 3 | Select one image from gallery | Image added, thumbnail shown | |
| 4 | Verify image preview | Selected image visible in preview area | |
| 5 | Add optional caption: "Beautiful sunset" | Caption text entered | |
| 6 | Tap "Post" button | Post created with image | |
| 7 | Verify in feed | Image post appears with caption | |

### TC-3.2: Multiple Images Post (Carousel)
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open photo post creation | Screen opens | |
| 2 | Tap add photos button | Image picker opens | |
| 3 | Select 3-5 images | Multiple images selected | |
| 4 | Verify all images shown in preview | Carousel/grid of selected images | |
| 5 | Verify image count indicator | Shows "3 photos" or similar | |
| 6 | Reorder images (drag and drop) | Order changes in preview | |
| 7 | Remove one image (tap X) | Image removed from selection | |
| 8 | Post the images | Multi-image post created | |

### TC-3.3: Camera Capture
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open photo post creation | Screen opens | |
| 2 | Tap camera icon | Camera opens | |
| 3 | Take a photo | Photo captured | |
| 4 | Confirm photo selection | Returns to post screen with photo | |
| 5 | Post the captured photo | Post created | |

### TC-3.4: Image Editing (if available)
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Select an image | Image in preview | |
| 2 | Tap edit/crop icon | Editor opens | |
| 3 | Crop image | Crop applied | |
| 4 | Apply filter (if available) | Filter applied | |
| 5 | Rotate image | Rotation applied | |
| 6 | Save edits | Returns with edited image | |

---

## Test Case 4: Audio Post Creation

### TC-4.1: Record Audio
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap "Audio" from create post screen | Audio post creation screen opens | |
| 2 | Verify recording UI | Large mic button, waveform area, timer | |
| 3 | Tap mic button to start recording | Recording starts, timer begins | |
| 4 | Verify waveform animates | Live waveform visualization | |
| 5 | Verify timer counts up | Shows 00:00, 00:01, 00:02... | |
| 6 | Record for 10 seconds | Timer shows ~00:10 | |
| 7 | Tap stop button | Recording stops | |
| 8 | Verify "Audio ready" message | Status changes to ready | |
| 9 | Verify playback button appears | Play button visible | |

### TC-4.2: Audio Playback
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | After recording, tap play button | Audio starts playing | |
| 2 | Verify playback progress | Waveform shows progress indicator | |
| 3 | Verify time display | Shows current position / total duration | |
| 4 | Tap pause during playback | Playback pauses | |
| 5 | Tap play again | Resumes from paused position | |
| 6 | Let audio play to end | Playback completes, resets to start | |

### TC-4.3: Delete Recording
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | After recording, tap delete button | Confirmation dialog appears | |
| 2 | Verify dialog text | "Delete Recording?" with warning | |
| 3 | Tap "Cancel" | Dialog closes, recording preserved | |
| 4 | Tap delete again, then "Delete" | Recording deleted, UI resets | |
| 5 | Verify mic button returns | Can record new audio | |

### TC-4.4: Select Audio from Device
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap "or select audio from device" | File picker opens | |
| 2 | Navigate to audio files | Shows audio files on device | |
| 3 | Select an audio file | File selected, returns to screen | |
| 4 | Verify file name shown | Shows selected file info | |
| 5 | Tap play to preview | Selected audio plays | |

### TC-4.5: Audio with Cover Image
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Record or select audio | Audio ready | |
| 2 | Tap "Add cover image" area | Image picker opens | |
| 3 | Select an image | Cover image shown in preview | |
| 4 | Tap X on cover image | Image removed | |
| 5 | Add cover image again | Image added | |
| 6 | Add caption text | Caption entered | |
| 7 | Post the audio | Post created with audio + cover + caption | |

### TC-4.6: Audio Permission Handling
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Deny microphone permission in settings | Permission denied | |
| 2 | Try to record audio | Error message shown | |
| 3 | Verify message | "Microphone permission is required" | |
| 4 | Grant permission in settings | Permission granted | |
| 5 | Try recording again | Recording works | |

---

## Test Case 5: Short Video Post Creation

### TC-5.1: Record Video
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap "Short Video" from create post | Video creation screen opens | |
| 2 | Verify camera preview | Live camera feed visible | |
| 3 | Verify recording controls | Record button, timer, camera flip | |
| 4 | Tap record button | Recording starts | |
| 5 | Verify timer | Shows recording duration | |
| 6 | Verify max duration (60s) | Timer counts toward 60 | |
| 7 | Tap stop before 60s | Recording stops | |
| 8 | Verify video preview | Recorded video shown | |

### TC-5.2: Camera Controls
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Before recording, tap flip camera | Switches front/back camera | |
| 2 | Tap flash toggle (if available) | Flash on/off/auto | |
| 3 | Verify countdown option | 3s/5s/10s countdown options | |
| 4 | Select 3s countdown, tap record | Countdown shows, then records | |

### TC-5.3: Select Video from Gallery
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap gallery/select button | Video picker opens | |
| 2 | Select a video file | Video selected | |
| 3 | If video > 60s, verify trim option | Trim interface shown | |
| 4 | Trim video to under 60s | Trimmed video ready | |

### TC-5.4: Video Post Completion
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | After recording/selecting video | Video preview shown | |
| 2 | Add caption (optional) | Caption entered | |
| 3 | Set privacy | Privacy selected | |
| 4 | Tap "Post" | Video uploads, post created | |
| 5 | Verify upload progress | Progress indicator shown | |
| 6 | Verify success | Post created message | |

---

## Test Case 6: Draft Functionality

### TC-6.1: Auto-Save Draft Prompt
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open any post creation screen | Screen opens | |
| 2 | Enter some content (text/select media) | Content added | |
| 3 | Tap back button without posting | Confirmation dialog appears | |
| 4 | Verify dialog options | "Discard", "Cancel", "Save Draft" | |
| 5 | Tap "Cancel" | Returns to post screen, content preserved | |

### TC-6.2: Save Draft Manually
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open text post, enter: "Draft test" | Content entered | |
| 2 | Verify "Save" button appears in app bar | Save button visible | |
| 3 | Tap "Save" button | Draft saved | |
| 4 | Verify success message | "Draft saved" snackbar | |
| 5 | Tap back (should not prompt again) | Returns without prompt (already saved) | |

### TC-6.3: Save Draft on Back
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open photo post, select an image | Image selected | |
| 2 | Add caption: "My draft photo" | Caption entered | |
| 3 | Tap back button | Save draft dialog appears | |
| 4 | Tap "Save Draft" | Draft saved, returns to previous screen | |
| 5 | Verify success message | Shows confirmation | |

### TC-6.4: Discard Changes
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open audio post, record short audio | Audio recorded | |
| 2 | Tap back button | Dialog appears | |
| 3 | Tap "Discard" | Returns without saving | |
| 4 | Verify no draft created | Check drafts section | |

### TC-6.5: View Drafts List
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create and save 2-3 drafts | Drafts saved | |
| 2 | Go to Create Post screen | Screen opens | |
| 3 | Verify "Your Drafts" section | Shows draft count | |
| 4 | Verify draft previews | Shows thumbnail/text preview | |
| 5 | Tap "View All" or expand | Full drafts list shown | |

### TC-6.6: Resume Draft
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Save a text draft with content | Draft saved | |
| 2 | Navigate to Create Post screen | Screen opens | |
| 3 | Tap on the saved draft | Opens post creation with draft content | |
| 4 | Verify content restored | Text content matches draft | |
| 5 | Verify privacy restored | Privacy setting matches | |
| 6 | Edit and post | Post created, draft deleted | |

### TC-6.7: Delete Draft
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Go to drafts list | Drafts shown | |
| 2 | Swipe or tap delete on a draft | Confirmation dialog | |
| 3 | Confirm deletion | Draft removed from list | |
| 4 | Verify draft count updates | Count decreases | |

### TC-6.8: Draft with Media
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create photo post, select 2 images | Images selected | |
| 2 | Add caption | Caption entered | |
| 3 | Save as draft | Draft saved | |
| 4 | Close and reopen draft | Draft loads | |
| 5 | Verify images restored | Both images shown | |
| 6 | Verify caption restored | Caption text present | |

---

## Test Case 7: Post Scheduling

### TC-7.1: Enable Scheduling
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open any post creation screen | Screen opens | |
| 2 | Scroll to "Schedule Post" section | Scheduling widget visible | |
| 3 | Verify toggle is off by default | Switch is off | |
| 4 | Tap toggle to enable | Switch turns on | |
| 5 | Verify date/time pickers appear | Date and time buttons visible | |
| 6 | Verify default time (1 hour from now) | Shows time ~1 hour ahead | |

### TC-7.2: Select Custom Date
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable scheduling | Scheduling enabled | |
| 2 | Tap date button | Date picker opens | |
| 3 | Verify cannot select past dates | Past dates disabled | |
| 4 | Select tomorrow's date | Date selected | |
| 5 | Verify date button updates | Shows selected date | |

### TC-7.3: Select Custom Time
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable scheduling | Scheduling enabled | |
| 2 | Tap time button | Time picker opens | |
| 3 | Select 9:00 AM | Time selected | |
| 4 | Verify time button updates | Shows "09:00" | |

### TC-7.4: Quick Select Options
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable scheduling | Options appear | |
| 2 | Tap "1 hour" chip | Time set to now + 1 hour | |
| 3 | Tap "3 hours" chip | Time set to now + 3 hours | |
| 4 | Tap "Tomorrow 9AM" chip | Date = tomorrow, time = 09:00 | |
| 5 | Tap "Weekend" chip | Date = next Saturday, time = 10:00 | |

### TC-7.5: Schedule a Post
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create text post with content | Content entered | |
| 2 | Enable scheduling | Scheduling on | |
| 3 | Select date/time (1 hour from now) | Schedule set | |
| 4 | Verify button text changes | Shows "Schedule" instead of "Post" | |
| 5 | Tap "Schedule" button | Post scheduled | |
| 6 | Verify success message | "Post scheduled" confirmation | |
| 7 | Verify post NOT in feed yet | Post not visible | |

### TC-7.6: View Scheduled Posts
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Schedule 1-2 posts | Posts scheduled | |
| 2 | Go to Create Post screen | Screen opens | |
| 3 | Look for scheduled posts indicator | Shows count or section | |
| 4 | Tap to view scheduled posts | List of scheduled posts | |
| 5 | Verify scheduled time shown | Each post shows schedule time | |

### TC-7.7: Disable Scheduling
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable scheduling and set a time | Schedule configured | |
| 2 | Toggle scheduling off | Switch turns off | |
| 3 | Verify date/time pickers hidden | Pickers disappear | |
| 4 | Verify button reverts to "Post" | No longer "Schedule" | |
| 5 | Post immediately | Post published now | |

### TC-7.8: Schedule with Draft
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create post with content | Content ready | |
| 2 | Enable scheduling | Schedule set | |
| 3 | Save as draft | Draft saved with schedule | |
| 4 | Reopen draft | Draft loads | |
| 5 | Verify schedule restored | Scheduling enabled with saved time | |

---

## Test Case 8: Error Handling

### TC-8.1: Network Error During Post
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable airplane mode | Network disabled | |
| 2 | Try to create a post | Attempt fails | |
| 3 | Verify error message | Shows network error | |
| 4 | Verify content not lost | Can retry or save draft | |
| 5 | Disable airplane mode | Network restored | |
| 6 | Retry posting | Post succeeds | |

### TC-8.2: Empty Post Prevention
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open text post screen | Screen opens | |
| 2 | Try to tap "Post" without content | Button is disabled | |
| 3 | Enter only whitespace | Button still disabled | |
| 4 | Enter valid text | Button becomes enabled | |

### TC-8.3: Media Selection Failure
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Deny photo library permission | Permission denied | |
| 2 | Try to select photos | Error message or settings prompt | |
| 3 | Grant permission | Permission granted | |
| 4 | Try again | Photo selection works | |

### TC-8.4: Large File Handling
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Select very large video (>100MB) | File selected | |
| 2 | Attempt to post | Compression/upload starts | |
| 3 | Verify progress indicator | Shows upload progress | |
| 4 | Verify completion or size error | Either succeeds or shows size limit message | |

---

## Test Case 9: UI/UX Validation

### TC-9.1: Loading States
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap Post button | Loading indicator on button | |
| 2 | Verify button is disabled during upload | Cannot tap again | |
| 3 | Verify screen doesn't close prematurely | Waits for completion | |

### TC-9.2: Keyboard Behavior
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap text field | Keyboard opens | |
| 2 | Verify content scrolls above keyboard | Text field visible | |
| 3 | Tap outside text field | Keyboard closes | |
| 4 | Verify content returns to normal | UI adjusts properly | |

### TC-9.3: Orientation Changes
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open post creation in portrait | Normal layout | |
| 2 | Rotate to landscape | Layout adapts | |
| 3 | Enter content | Content preserved | |
| 4 | Rotate back to portrait | Content still there | |

### TC-9.4: Dark Mode (if supported)
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Enable dark mode in system settings | Theme changes | |
| 2 | Open post creation screens | Colors appropriate for dark mode | |
| 3 | Verify all text is readable | Sufficient contrast | |
| 4 | Verify icons are visible | Icons properly themed | |

---

## Test Case 10: Integration Tests

### TC-10.1: Full Text Post Flow
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open Create Post | Screen loads | |
| 2 | Tap Text | Text screen opens | |
| 3 | Enter: "Integration test post #tajiri" | Text entered | |
| 4 | Set privacy to Friends | Privacy set | |
| 5 | Post | Post created | |
| 6 | Verify in feed | Post appears with correct content and privacy | |
| 7 | Verify hashtag is clickable | #tajiri is tappable | |

### TC-10.2: Full Photo Post Flow
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create Post > Photo | Photo screen | |
| 2 | Select 2 images | Images added | |
| 3 | Add caption with @mention | Caption with mention | |
| 4 | Post | Post created | |
| 5 | Verify carousel in feed | Can swipe between images | |
| 6 | Verify mention notification | Tagged user notified (if applicable) | |

### TC-10.3: Full Audio Post Flow
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create Post > Audio | Audio screen | |
| 2 | Record 15 seconds of audio | Audio recorded | |
| 3 | Add cover image | Image added | |
| 4 | Add caption | Caption entered | |
| 5 | Post | Post created | |
| 6 | Verify in feed | Audio post with play button | |
| 7 | Play audio from feed | Audio plays | |

### TC-10.4: Full Scheduled Post Flow
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create text post | Content ready | |
| 2 | Schedule for 2 minutes from now | Schedule set | |
| 3 | Tap Schedule | Post scheduled | |
| 4 | Verify not in feed | Post not visible yet | |
| 5 | Wait 2+ minutes | Time passes | |
| 6 | Refresh feed | Post now appears | |
| 7 | Verify correct timestamp | Shows scheduled time | |

### TC-10.5: Draft to Published Post Flow
| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Create photo post with 3 images | Images selected | |
| 2 | Add caption | Caption entered | |
| 3 | Save as draft | Draft saved | |
| 4 | Close app completely | App closed | |
| 5 | Reopen app | App starts | |
| 6 | Go to Create Post | Screen loads | |
| 7 | Open saved draft | Draft content restored | |
| 8 | Verify all 3 images present | Images loaded | |
| 9 | Post the draft | Post created | |
| 10 | Verify draft removed | No longer in drafts | |

---

## Test Summary

| Test Category | Total Tests | Passed | Failed | Blocked |
|---------------|-------------|--------|--------|---------|
| Navigation | | | | |
| Text Post | | | | |
| Photo Post | | | | |
| Audio Post | | | | |
| Video Post | | | | |
| Drafts | | | | |
| Scheduling | | | | |
| Error Handling | | | | |
| UI/UX | | | | |
| Integration | | | | |
| **TOTAL** | | | | |

---

## Bugs Found

| Bug ID | Severity | Test Case | Description | Steps to Reproduce | Status |
|--------|----------|-----------|-------------|-------------------|--------|
| | | | | | |
| | | | | | |
| | | | | | |

**Severity Levels:**
- **Critical:** App crashes, data loss, security issue
- **High:** Feature doesn't work, blocks user flow
- **Medium:** Feature partially works, workaround exists
- **Low:** Minor UI issue, cosmetic problem

---

## Notes & Observations

_Space for tester comments, suggestions, and general observations:_

```




```

---

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Tester | | | |
| Developer | | | |
| QA Lead | | | |

---

## Appendix A: Test Data

### Sample Text Content
```
Short text: "Hello Tajiri!"
Medium text: "Testing the new post creation feature with multiple sentences. This should work great!"
Long text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
With hashtags: "Check out this #amazing #tajiri #test post!"
With mentions: "Hey @testuser, what do you think about this?"
```

### Test Files Needed
- [ ] 5+ images (various sizes: small <1MB, medium 1-5MB, large >5MB)
- [ ] 3+ videos (short <30s, medium 30-60s, long >60s)
- [ ] 3+ audio files (mp3, wav, m4a formats)
- [ ] 1 corrupted/invalid file for error testing

---

## Appendix B: API Endpoints Tested

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/posts` | POST | Create new post |
| `/api/drafts` | GET | List drafts |
| `/api/drafts` | POST | Save draft |
| `/api/drafts/{id}` | GET | Get single draft |
| `/api/drafts/{id}` | DELETE | Delete draft |
| `/api/drafts/{id}/publish` | POST | Publish draft |
| `/api/posts/scheduled` | GET | List scheduled posts |
