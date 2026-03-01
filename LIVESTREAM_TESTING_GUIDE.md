# TAJIRI Livestreaming Testing Guide

**Version**: 1.0
**Date**: 2026-01-28
**Status**: Ready for Testing

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [ZEGOCLOUD Setup](#zegocloud-setup)
3. [Testing Scenarios](#testing-scenarios)
4. [Feature Testing Checklist](#feature-testing-checklist)
5. [Known Issues & Workarounds](#known-issues--workarounds)
6. [Performance Benchmarks](#performance-benchmarks)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Development Environment
- ✅ Flutter SDK 3.10.1+ installed
- ✅ Xcode (iOS) / Android Studio (Android)
- ✅ Physical device recommended (camera/microphone features)
- ✅ Stable internet connection (minimum 5 Mbps upload)

### 2. Backend Requirements
- ✅ Laravel backend running at `https://zima-uat.site:8003/api`
- ✅ WebSocket server active (`wss://zima-uat.site:8003/`)
- ✅ RTMP server configured to receive streams
- ✅ HLS transcoding pipeline active
- ✅ Database with `streams` table and proper schema

### 3. Test Accounts
Prepare at least 3 test accounts:
- **Broadcaster Account**: For creating streams
- **Viewer Account 1**: For watching streams
- **Viewer Account 2**: For testing interactions

---

## ZEGOCLOUD Setup

### Step 1: Get ZEGOCLOUD Credentials

1. Visit [ZEGOCLOUD Console](https://console.zegocloud.com/)
2. Create a new project or use existing one
3. Get your credentials:
   - **AppID**: A unique numeric identifier
   - **AppSign**: A security signature string

### Step 2: Configure App

Edit `lib/services/zego_streaming_service.dart`:

```dart
class ZegoStreamingService {
  // REPLACE THESE WITH YOUR ACTUAL CREDENTIALS
  static const int appID = 1234567890; // Your AppID
  static const String appSign = 'your_app_sign_here'; // Your AppSign

  // ...
}
```

### Step 3: Platform-Specific Setup

#### iOS Setup

1. Open `ios/Runner/Info.plist`
2. Add camera and microphone permissions:

```xml
<key>NSCameraUsageDescription</key>
<string>TAJIRI needs camera access for livestreaming</string>
<key>NSMicrophoneUsageDescription</key>
<string>TAJIRI needs microphone access for livestreaming</string>
```

#### Android Setup

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## Testing Scenarios

### Scenario 1: Create Immediate Stream

**Objective**: Test "Go Live Now" flow with ZEGOCLOUD camera

**Steps**:
1. Login with broadcaster account
2. Navigate to Profile → Live
3. Tap "Enda Live" button
4. Fill in stream details:
   - Title: "Test Stream 1"
   - Description: "Testing immediate streaming"
   - Tags: "test", "live"
   - Select thumbnail from gallery
5. Select "Sasa" (Now) option
6. Tap "Enda Live"

**Expected Results**:
- ✅ Navigate to BackstageScreen
- ✅ See system checks (camera, microphone, network)
- ✅ Tap "Enda Live" button
- ✅ Navigate to LiveBroadcastScreenAdvanced
- ✅ See live camera preview (ZEGOCLOUD camera)
- ✅ See pulsing LIVE indicator
- ✅ See duration timer starting (00:00, 00:01, 00:02...)
- ✅ Stream appears in backend with `status='live'`
- ✅ RTMP stream pushing to `rtmp://zima-uat.site:8003/live/{stream_id}`
- ✅ HLS playback available at `https://zima-uat.site:8003/live/{stream_id}.m3u8`

**Success Criteria**:
- Stream created with correct status
- Camera feed visible
- RTMP push successful
- HLS playback starts within 10 seconds

---

### Scenario 2: Create Scheduled Stream

**Objective**: Test stream scheduling with countdown

**Steps**:
1. Navigate to Profile → Live → "Enda Live"
2. Fill in stream details
3. Select "Panga" (Schedule)
4. Choose time 5 minutes from now
5. Tap "Panga"

**Expected Results**:
- ✅ Show success dialog with countdown info
- ✅ Stream appears in "Scheduled" tab
- ✅ See countdown: "Inabaki: 4:59"
- ✅ Followers can see stream with countdown badge
- ✅ When time arrives, tap "Anza Sasa"
- ✅ Navigate to BackstageScreen → Go Live

**Success Criteria**:
- Scheduled stream created with `scheduled_at` timestamp
- Countdown displayed correctly
- Transition to backstage works smoothly

---

### Scenario 3: Test Beauty Filters

**Objective**: Verify ZEGOCLOUD beauty effects

**Steps**:
1. Start a livestream (Scenario 1)
2. In LiveBroadcastScreen, tap beauty filter button (right side controls)
3. Test each preset:
   - None (disable)
   - Natural (30% level)
   - Soft (50% level)
   - Strong (80% level)

**Expected Results**:
- ✅ Face beautification applies in real-time
- ✅ Skin smoothing visible
- ✅ Visual feedback on filter selection
- ✅ No lag or performance degradation

**Success Criteria**:
- Beauty filter toggle works
- Effects visible in real-time
- Stream quality maintained (30 FPS)

---

### Scenario 4: Test Camera Controls

**Objective**: Verify camera flip and mute functionality

**Steps**:
1. Start a livestream
2. Tap "Flip Camera" button
3. Verify camera switches (front ↔ back)
4. Tap "Mute" button
5. Verify audio muted (icon changes)
6. Unmute and verify audio restored

**Expected Results**:
- ✅ Camera flip smooth (< 1 second)
- ✅ Preview updates correctly
- ✅ Mute icon changes (mic → mic_off)
- ✅ Audio actually muted (verify with viewer)

**Success Criteria**:
- Camera controls responsive
- No stream interruption during flip
- Audio state persists correctly

---

### Scenario 5: Test Floating Reactions

**Objective**: Test real-time reaction system

**Steps**:
1. Start a livestream
2. Tap reaction buttons at bottom:
   - ❤️ Heart
   - 🔥 Fire
   - 👏 Clap
   - 😮 Wow
   - 😂 Laugh
   - 😢 Sad
3. Observe animated bubbles

**Expected Results**:
- ✅ Reaction bubbles float up from bottom
- ✅ Fade out animation (3 seconds)
- ✅ Multiple reactions can overlap
- ✅ Reactions sent to WebSocket
- ✅ Viewers see reactions in real-time

**Success Criteria**:
- Smooth 60 FPS animations
- No memory leaks (test with 100+ reactions)
- WebSocket events confirmed in backend logs

---

### Scenario 6: Test Live Polls

**Objective**: Create and manage live polls

**Steps**:
1. Start a livestream
2. Tap "Poll" button (right side)
3. Create poll:
   - Question: "Which feature do you like most?"
   - Options: ["Polls", "Q&A", "Super Chat"]
4. Tap "Create"
5. Poll appears on screen
6. As viewer, vote on an option
7. See progress bars update
8. Broadcaster closes poll

**Expected Results**:
- ✅ Poll creator dialog appears
- ✅ Poll displays with progress bars
- ✅ Votes update in real-time via WebSocket
- ✅ Percentages calculated correctly
- ✅ Close button works

**Success Criteria**:
- Poll creation < 5 seconds
- Vote updates < 500ms latency
- Multiple viewers can vote simultaneously

---

### Scenario 7: Test Q&A Mode

**Objective**: Test question submission and management

**Steps**:
1. Start a livestream
2. Tap "Q&A" button
3. Q&A panel opens
4. As viewer, submit question: "How long have you been streaming?"
5. See question appear in queue
6. Other viewers upvote question
7. Broadcaster marks question as answered

**Expected Results**:
- ✅ Q&A panel toggles correctly
- ✅ Questions sorted by upvotes
- ✅ Real-time upvote updates
- ✅ Answered questions highlighted green
- ✅ WebSocket events synchronized

**Success Criteria**:
- Question submission < 1 second
- Upvotes reflected immediately
- Panel doesn't block camera view

---

### Scenario 8: Test Super Chat

**Objective**: Test tiered super chat system

**Steps**:
1. Start a livestream
2. As viewer, send super chat:
   - Amount: TZS 1,000 (Low tier - blue)
   - Amount: TZS 5,000 (Medium tier - amber)
   - Amount: TZS 10,000 (High tier - red)
3. Observer super chat overlay on broadcaster screen

**Expected Results**:
- ✅ Super chat appears with correct tier color
- ✅ Gradient background with glow effect
- ✅ Message displayed prominently
- ✅ Auto-removes after duration (5/10/15 seconds)
- ✅ Earnings ticker updates
- ✅ WebSocket event received

**Success Criteria**:
- Super chat visible to all viewers
- Tiers correctly differentiated
- Earnings accumulated accurately

---

### Scenario 9: Test Stream Health Monitoring

**Objective**: Verify real-time stream metrics

**Steps**:
1. Start a livestream
2. Tap "Analytics" button (top bar)
3. Observe stream health metrics:
   - Network quality
   - Bitrate (kbps)
   - FPS
   - Dropped frames
   - Latency (ms)
4. Simulate poor network (airplane mode for 5 seconds)
5. Re-enable network

**Expected Results**:
- ✅ Health monitor displays in top-right
- ✅ Network quality: Excellent/Good/Poor
- ✅ Metrics update every 3 seconds
- ✅ Poor network detected (quality → Poor, color → red)
- ✅ Recovery detected (quality → Good)

**Success Criteria**:
- Metrics accurate (within 10% of actual)
- Color-coded warnings work
- No false positives

---

### Scenario 10: Test Live Analytics

**Objective**: Verify viewer count graph

**Steps**:
1. Start a livestream
2. Enable analytics panel
3. Observe viewer count graph
4. Have 5 viewers join over 2 minutes
5. 2 viewers leave
6. Observer graph updates

**Expected Results**:
- ✅ Graph displays with gradient fill
- ✅ Data points every 10 seconds
- ✅ Line smoothly interpolates
- ✅ Viewer count matches actual
- ✅ Peak viewer indicator shows

**Success Criteria**:
- Graph renders smoothly
- Data accurate
- UI remains responsive

---

### Scenario 11: Test Battle Mode (PK Battle)

**Objective**: Test competitive streaming feature

**Steps**:
1. Start two livestreams (Broadcaster A & B)
2. Broadcaster A invites Broadcaster B to battle
3. Broadcaster B accepts
4. Battle starts
5. Viewers send gifts to both streamers
6. Observe score updates in real-time
7. Battle ends after 5 minutes
8. Winner declared

**Expected Results**:
- ✅ Battle invite dialog appears
- ✅ Battle overlay displays on both streams
- ✅ Scores update in real-time
- ✅ Progress bars show % for each streamer
- ✅ Pulsing "PK BATTLE" indicator
- ✅ Battle result dialog at end
- ✅ Winner announced correctly

**Success Criteria**:
- Zero latency in score updates
- Overlay doesn't obscure content
- Battle state synchronized perfectly

---

### Scenario 12: Test End Stream

**Objective**: Verify graceful stream termination

**Steps**:
1. Start a livestream (run for 5 minutes)
2. Accumulate some stats:
   - 10 viewers (peak: 15)
   - 50 likes
   - TZS 5,000 earnings
3. Tap "End Stream" (X button, top-right)
4. Confirm end stream

**Expected Results**:
- ✅ Confirmation dialog appears
- ✅ Stream summary shows:
   - Duration: 5:00
   - Peak Viewers: 15
   - Total Likes: 50
   - Earnings: TZS 5,000
- ✅ ZEGOCLOUD stream stops
- ✅ RTMP push ends
- ✅ Backend status updated to `ended`
- ✅ HLS playback stops

**Success Criteria**:
- All resources cleaned up
- No memory leaks
- Backend synchronized

---

## Feature Testing Checklist

### Core Streaming
- [ ] Camera preview works
- [ ] RTMP push successful
- [ ] HLS playback available
- [ ] Stream starts within 10 seconds
- [ ] Video quality: 720p @ 30 FPS
- [ ] Audio quality: Clear, no distortion
- [ ] Latency: < 5 seconds (RTMP→HLS)

### Beauty Filters
- [ ] Beauty toggle works
- [ ] All 4 presets apply correctly
- [ ] Real-time effect (no lag)
- [ ] Settings persist during stream

### Camera Controls
- [ ] Flip camera (front ↔ back)
- [ ] Mute/unmute microphone
- [ ] Camera enable/disable
- [ ] Controls responsive (< 500ms)

### Floating Reactions
- [ ] All 6 reaction types work
- [ ] Animations smooth (60 FPS)
- [ ] Multiple reactions overlap correctly
- [ ] WebSocket synchronization

### Live Polls
- [ ] Poll creation < 5 seconds
- [ ] Votes update in real-time
- [ ] Progress bars accurate
- [ ] Close poll works
- [ ] Multiple polls can exist

### Q&A Mode
- [ ] Panel toggles correctly
- [ ] Questions appear immediately
- [ ] Upvoting works
- [ ] Answer marking works
- [ ] Sorting by upvotes

### Super Chat
- [ ] All 3 tiers display correctly
- [ ] Gradient/glow effects work
- [ ] Auto-removal after duration
- [ ] Earnings tracker updates
- [ ] Multiple super chats stack

### Stream Health
- [ ] Network quality accurate
- [ ] Bitrate tracked correctly
- [ ] FPS monitoring works
- [ ] Dropped frames counted
- [ ] Latency measurement accurate

### Live Analytics
- [ ] Viewer graph renders
- [ ] Data updates every 10s
- [ ] Peak viewer tracking
- [ ] Historical data (50 points)

### Battle Mode
- [ ] Invite/accept flow works
- [ ] Scores synchronized
- [ ] Progress bars update
- [ ] Battle timer accurate
- [ ] Winner determination correct
- [ ] Result dialog displays

### End Stream
- [ ] Confirmation dialog
- [ ] Summary statistics correct
- [ ] Resources cleaned up
- [ ] Backend updated
- [ ] Navigation works

---

## Known Issues & Workarounds

### Issue 1: ZEGOCLOUD AppID Not Configured
**Symptom**: Camera preview shows error, console logs "AppID and AppSign not configured"

**Workaround**:
1. Get credentials from ZEGOCLOUD Console
2. Edit `lib/services/zego_streaming_service.dart`
3. Replace `appID` and `appSign` with actual values
4. Restart app

---

### Issue 2: Backend Rejects Immediate Streams
**Symptom**: Error "Cannot start stream from 'scheduled' status"

**Status**: ✅ FIXED (Backend team implemented pre_live status)

**Workaround** (if issue persists):
1. Use scheduled stream flow
2. Create stream with `scheduled_at`
3. Navigate via "Anza Sasa" button

---

### Issue 3: HLS Playback Delay
**Symptom**: 10-15 second delay for viewers

**Explanation**: Normal HLS latency (segmented streaming)

**Mitigation**:
- Use shorter segment duration (2 seconds)
- Enable low-latency HLS (LL-HLS)
- Consider WebRTC for ultra-low latency (< 500ms)

---

### Issue 4: Battle Mode Score Desync
**Symptom**: Scores don't match between streamers

**Workaround**:
1. Ensure both streamers have stable internet
2. Check WebSocket connection status
3. Restart battle if desync persists

---

### Issue 5: Beauty Filter Performance
**Symptom**: FPS drops with beauty filter enabled

**Workaround**:
1. Use lower beauty level (30-50%)
2. Test on high-end device
3. Disable other heavy features (analytics)

---

## Performance Benchmarks

### Target Metrics
| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Stream Start Time | < 5s | < 10s | > 15s |
| Camera Flip Time | < 1s | < 2s | > 3s |
| Reaction Animation FPS | 60 | 45 | < 30 |
| Poll Vote Latency | < 500ms | < 1s | > 2s |
| WebSocket Reconnect | < 3s | < 5s | > 10s |
| Memory Usage | < 200 MB | < 300 MB | > 400 MB |
| Battery Drain (30 min) | < 20% | < 30% | > 40% |
| Network Upload | 1-2 Mbps | 2-3 Mbps | > 5 Mbps |

### Testing Tools
- **FPS Counter**: Flutter DevTools → Performance
- **Memory Profiler**: Flutter DevTools → Memory
- **Network Monitor**: Charles Proxy / Wireshark
- **Battery Monitor**: Xcode / Android Studio

---

## Troubleshooting

### Problem: "SDK not initialized" error
**Solution**:
```dart
// Verify AppID and AppSign are set
print('AppID: ${ZegoStreamingService.appID}');
print('AppSign: ${ZegoStreamingService.appSign}');
```

### Problem: "Failed to start publishing stream"
**Solution**:
1. Check internet connection
2. Verify RTMP URL format
3. Ensure backend RTMP server running
4. Check firewall rules

### Problem: WebSocket not connecting
**Solution**:
1. Verify backend URL: `wss://zima-uat.site:8003/`
2. Check SSL certificate validity
3. Test with `wscat` or Postman
4. Review backend logs

### Problem: Camera permission denied
**Solution**:
1. iOS: Check Info.plist has camera permission
2. Android: Check AndroidManifest.xml
3. Manually enable in device Settings

### Problem: Beauty filter not applying
**Solution**:
1. Ensure ZEGOCLOUD SDK version supports beauty
2. Check `enableBeautify()` called successfully
3. Verify device has sufficient processing power

---

## Test Report Template

```markdown
## Test Session Report

**Date**: YYYY-MM-DD
**Tester**: [Your Name]
**Device**: [iPhone 14 / Samsung Galaxy S23]
**OS Version**: [iOS 17 / Android 14]
**App Version**: 1.0.0
**Build**: [Debug / Release]

### Tests Executed
- [ ] Scenario 1: Immediate Stream ✅ PASS / ❌ FAIL
- [ ] Scenario 2: Scheduled Stream ✅ PASS / ❌ FAIL
- [ ] Scenario 3: Beauty Filters ✅ PASS / ❌ FAIL
- [ ] Scenario 4: Camera Controls ✅ PASS / ❌ FAIL
- [ ] Scenario 5: Reactions ✅ PASS / ❌ FAIL
- [ ] Scenario 6: Polls ✅ PASS / ❌ FAIL
- [ ] Scenario 7: Q&A ✅ PASS / ❌ FAIL
- [ ] Scenario 8: Super Chat ✅ PASS / ❌ FAIL
- [ ] Scenario 9: Stream Health ✅ PASS / ❌ FAIL
- [ ] Scenario 10: Analytics ✅ PASS / ❌ FAIL
- [ ] Scenario 11: Battle Mode ✅ PASS / ❌ FAIL
- [ ] Scenario 12: End Stream ✅ PASS / ❌ FAIL

### Issues Found
1. [Issue description]
   - Severity: Critical / High / Medium / Low
   - Steps to reproduce
   - Expected vs Actual
   - Screenshots/Logs

### Performance Metrics
- Stream Start Time: X seconds
- Average FPS: X fps
- Memory Usage: X MB
- Battery Drain (30 min): X%

### Overall Assessment
- ✅ Ready for Production
- ⚠️ Minor Issues (can deploy)
- ❌ Critical Issues (cannot deploy)

### Notes
[Additional observations]
```

---

## Next Steps

1. **Complete all 12 testing scenarios**
2. **Document any issues found**
3. **Performance profiling** (Flutter DevTools)
4. **Load testing** (50+ concurrent viewers)
5. **Network resilience testing** (poor connectivity)
6. **Battery/thermal testing** (1 hour streaming)
7. **Cross-device testing** (5+ device models)
8. **Backend load testing** (multiple concurrent streams)

---

**Testing Contact**: [Your Contact Information]
**Bug Reports**: [GitHub Issues / JIRA / Email]
**Documentation**: This file + BACKEND_REQUIREMENTS.md + LIVESTREAM_INTEGRATION_GUIDE.md
