# Video Reply / Duet / Remix Feature Research

**Date:** 2026-03-27
**Purpose:** Deep research into how major social platforms implement video reply/duet/remix features, for informing TAJIRI's implementation.

---

## Table of Contents
1. [TikTok Duet](#1-tiktok-duet)
2. [Instagram Reels Remix](#2-instagram-reels-remix)
3. [YouTube Shorts Collab/Remix](#3-youtube-shorts-collabremix)
4. [Snapchat Remix Snap](#4-snapchat-remix-snap)
5. [X (Twitter) Video Reactions](#5-x-twitter-video-reactions)
6. [Facebook Reels Remix](#6-facebook-reels-remix)
7. [Cross-Platform Comparison Table](#7-cross-platform-comparison-table)
8. [Technical Architecture](#8-technical-architecture)
9. [Best Practices & Recommendations for TAJIRI](#9-best-practices--recommendations-for-tajiri)

---

## 1. TikTok Duet

TikTok is the originator and gold standard for this feature. ~30% of users actively use Duets. TikTok also offers **Stitch** (clip a segment of another video and lead into your own) as a separate but related feature.

### 1.1 Layout Options (5 layouts)

| Layout | Description | Screen Split |
|--------|-------------|-------------|
| **Side-by-Side (Left/Right)** | Classic layout. Original on right, yours on left (toggleable). | 50/50 horizontal split |
| **React** | Original video fills most of the screen; your video appears in a small circular or rectangular overlay (PiP). | ~80% original / ~20% reaction bubble |
| **Top-Bottom** | Videos stacked vertically. Original on top, yours on bottom (toggleable). | 50/50 vertical split |
| **Three Screen** | Three columns for group/chain duets. | ~33/33/33 horizontal split |
| **Green Screen** | Original video becomes your background. You are composited on top, full screen. | 100% overlay, user foreground |

- **Repositioning:** In top-bottom and three-screen layouts, users can hold and drag videos to reposition within the frame.
- **Toggling sides:** In left-right and top-bottom layouts, users can toggle which side their video occupies.
- **Resizing the overlay:** In React layout, the PiP bubble position can be moved but the size is not freely resizable by the user (fixed proportions).

### 1.2 Audio Mixing

- **Two independent volume sliders:** "Original Sound" and "Added Sound" (your microphone input).
- Users can set original sound to 0% (full mute) or 100%, and independently control their own volume.
- Both audio tracks play simultaneously during recording and in the final output.
- Volume adjustments are only available during the editing phase before posting; cannot be changed after publishing.
- Sliders can reset if you change effects or songs mid-edit.
- You can also add a separate music track during the post-recording edit phase.

### 1.3 Duration Limits

- Duet length matches the original video's length.
- TikTok's maximum video duration is 10 minutes, so duets can technically be up to 10 minutes.
- Most duets are 15-60 seconds in practice.

### 1.4 Content Types

- **Videos only** for Duet. You cannot duet an image or text post directly.
- **Stitch** (separate feature) also only works on videos.

### 1.5 UX/Recording Flow

1. Open the video you want to duet.
2. Tap the **Share** button (arrow icon).
3. Select **Duet** from the share sheet.
4. **Trim prompt:** Slider to trim the original video to a specific segment, or use the full video. Tap "Done" when satisfied.
5. **Choose layout:** Select from the 5 layout options before or during recording.
6. **Recording:** Press and hold the red Record button. The original video plays simultaneously. A **3-2-1 countdown timer** is available for hands-free recording.
7. **Effects & Filters:** Available from the right-side menu during recording (beauty filters, AR effects, speed adjustments).
8. **Upload option:** You can tap "Upload" to use a pre-recorded video from your gallery instead of live recording.
9. **Edit phase:** After recording, tap the red checkmark. Add filters, effects, text overlays, stickers, and adjust audio volume sliders.
10. **Preview:** Watch a preview of the combined video.
11. **Post:** Tap "Next" to add caption and publish.

### 1.6 Attribution/Credit

- The original creator is **automatically attributed** in the duet video's caption.
- The attribution caption links directly to the original video.
- The original creator's username is displayed on the duet.

### 1.7 Privacy/Controls

- Creators can disable duets **per-video** (via three-dot menu on individual video).
- Creators can disable duets **globally** (Privacy Settings > "Who can Duet with your videos" > set to "No One" or "Friends").
- Creators can disable duets **during upload** before publishing a specific video.
- Three options: Everyone, Friends, No One.

### 1.8 Technical Details

- **Aspect ratio:** The final duet video is exported as a single 9:16 portrait file for the feed.
- **Resolution:** For side-by-side layout, each half is approximately 540x960 pixels within a 1080x1920 canvas. The combined canvas for side-by-side is sometimes reported as 1080x960 or the platform auto-crops to fit 9:16.
- **File format:** MP4 or MOV, max 287.6 MB for standard users.
- **Rendering:** The duet is **composited client-side** during recording/editing, then uploaded as a **single merged video file** to TikTok's servers. The server stores it as one file, not as separate tracks.
- **Server processing:** After upload, TikTok transcodes the video into multiple resolutions/formats for different devices and network conditions.

---

## 2. Instagram Reels Remix

Instagram's answer to TikTok Duet, launched March 2021, expanded significantly through 2022-2025.

### 2.1 Layout Options (5 layouts)

| Layout | Description |
|--------|-------------|
| **Side-by-Side (Horizontal Split)** | Your video next to the original, both play simultaneously. Classic format. |
| **Top-Bottom (Vertical Split)** | Your video above/below the original. |
| **Picture-in-Picture (PiP)** | Your video in a small overlay window on top of the original. |
| **Green Screen** | Original Reel becomes your virtual background; you are composited in the foreground. |
| **Sequential (After)** | Your clip plays **after** the original (not simultaneously). Unique to Instagram. |

### 2.2 Audio Mixing

- **Audio Mix feature:** A dedicated "Mix Audio" window with volume sliders.
- You can adjust the volume of your voiceover relative to the original audio.
- You can add a separate voiceover layer on top.
- You can add music from Instagram's library.
- **Copyright caveat:** If the original Reel's audio is removed due to copyright, your remix loses that audio track too.

### 2.3 Duration Limits

- Reels can be up to 90 seconds (standard Reels limit as of 2025).
- Best practice recommendation: 15-30 seconds for optimal engagement.
- Sequential remixes can effectively double the content length (original + your addition).

### 2.4 Content Types

- **Reels (videos):** Yes, the primary content type.
- **Photos/Images:** Yes -- Instagram expanded Remix to support public photos (since July 2022). Old photos require the creator to enable remixing per-post.
- **Feed videos:** Yes, can be remixed.
- **Text posts:** Not directly remixable.

### 2.5 UX/Recording Flow

1. Open the Reel/photo/video you want to remix.
2. Tap the **three-dot menu** (or the Remix icon).
3. Select **"Remix"**.
4. **Choose layout:** Select from horizontal split, vertical split, PiP, green screen, or sequential.
5. **Record** your video (or upload from gallery).
6. **Edit:** Add text, stickers, voiceovers, filters, effects.
7. **Audio mixing:** Adjust original vs. your audio levels.
8. **Preview** before publishing.
9. **Publish** as a new Reel on your profile.

### 2.6 Attribution/Credit

- The remix appears as a **new Reel on your profile**, tagged/linked to the original.
- Viewers can navigate from the remix to the original Reel and vice versa.
- Original creator's username is displayed.

### 2.7 Privacy/Controls

- **Per-Reel control:** Creators can toggle off "Allow Remixing" on individual Reels via settings.
- **Global control:** Settings > "Reels and Remix Controls" > toggle on/off remixes for all reels and feed videos.
- **Only public accounts** can have their Reels remixed. Private accounts' content is not remixable.
- Old photos default to remix-disabled; creators must opt-in per post.

---

## 3. YouTube Shorts Collab/Remix

YouTube's approach combines multiple tools: **Collab** (side-by-side recording), **Remix** (use audio/clips from existing content), and recently **AI-powered Remix** tools (2026).

### 3.1 Layout Options

| Layout | Description |
|--------|-------------|
| **Side-by-Side (Split Screen)** | Record alongside the original video. Multiple split configurations available. |
| **Picture-in-Picture** | Your video overlaid on the original. |
| **Green Screen** | Original video/frame as your background. |

- Users can adjust layout, zoom, and crop of the video segment.
- Layout selection via a "Layouts" button in the recording UI.

### 3.2 Audio Controls

- **Microphone toggle** during Collab recording to adjust audio.
- Timer/countdown available for hands-free recording.
- Audio from original video plays during recording.
- Can use audio from any eligible video (audio remix) separately from visual collab.

### 3.3 Duration Limits

- **60 seconds maximum** (YouTube Shorts limit).
- Can remix clips from long-form YouTube videos (not just Shorts), but the resulting Short must be under 60 seconds.
- As of 2025/2026, YouTube has been testing extending Shorts to 3 minutes, which may affect remix limits.

### 3.4 Content Types

- **YouTube Shorts:** Yes.
- **Regular YouTube videos (long-form):** Yes, you can Collab/Remix with segments from any public YouTube video.
- **Images/text:** No.

### 3.5 UX/Recording Flow

1. On a Short or video, tap the **Remix** icon.
2. Select **"Collab"** (for side-by-side) or other remix options (Sound, Cut, Green Screen).
3. **Choose layout** via the Layouts button.
4. **Adjust zoom/crop** of the original segment.
5. **Record** using timer/countdown if desired.
6. **Edit** with YouTube's Shorts editing tools.
7. **Preview and publish.**

### 3.6 Attribution/Credit

- Original video is linked/credited in the Short's metadata.
- Viewers can navigate to the original video.

### 3.7 Privacy/Controls

- **Opted-in by default:** All public Shorts and videos are automatically eligible for remixing.
- **Opt-out for long-form videos:** Creators can opt out of video remixing in YouTube Studio settings.
- **Limited opt-out for Shorts:** Shorts creators have fewer options; historically, Shorts content could not be fully opted out of audio remixing. Deleting the original Short was the only way to fully remove it.
- **AI Remix opt-out (2026):** Creators can opt out of AI-powered remix features, though this may also disable standard remix functionality.
- YouTube Partners with Content Manager access can opt out of both audio and video remixing.

### 3.8 AI-Powered Remix (2026, Testing)

- **Add Object:** Insert AI-generated items into scenes from another creator's Short (up to 8 seconds).
- **Reimagine:** Take a single frame from any eligible Short and transform it into an entirely new video via text prompts, with option to add up to 2 reference photos.
- Currently in limited testing with a small group of creators.

---

## 4. Snapchat Remix Snap

Snapchat's Remix is more intimate/social -- designed for friend-to-friend reactions rather than public content creation.

### 4.1 Layout Options

| Layout | Description |
|--------|-------------|
| **Side-by-Side (Horizontal)** | Your snap next to the original. |
| **Top-Bottom (Vertical)** | Stacked vertically. |
| **Picture-in-Picture** | Your reaction overlaid on the original. |
| **With the Snap** | Content displayed alongside simultaneously. |
| **After the Snap** | Your content plays sequentially after the original. |

- 5 total options accessible via buttons on the left side of the screen.
- Users can reposition their reply using on-screen buttons.

### 4.2 Audio Controls

- Not well documented publicly. Standard Snapchat audio recording applies.
- No documented independent volume slider for original vs. reply audio.

### 4.3 Duration Limits

- Follows standard Snap duration limits (up to 60 seconds per Snap).
- Spotlight videos can be longer.

### 4.4 Content Types

- **Received Snaps** (from friends).
- **Chat media** (viewed in conversations).
- **Spotlight content** (public short videos).
- **Saved Memories.**
- Can also remix from Camera Roll.
- No mention of text-only content.

### 4.5 UX/Recording Flow

1. View a Snap, Story, or Spotlight video.
2. Tap **three dots** (top right) or hold and swipe up.
3. Select **"Remix Snap"**.
4. Choose layout option (with/after the snap, side-by-side, etc.).
5. **Record** your reply snap using the camera.
6. Add stickers, text, effects.
7. **Share** to your Story or send to friends.

### 4.6 Attribution/Credit

- The original Snap is embedded in the remix.
- Limited public attribution compared to TikTok/Instagram since most sharing is friend-to-friend.

### 4.7 Privacy/Controls

- Not extensively documented.
- Primarily limited to content you've received or public Spotlight content.
- Friends-based distribution model inherently limits exposure.

---

## 5. X (Twitter) Video Reactions

X's video reaction feature is newer and less mature than TikTok/Instagram equivalents.

### 5.1 Layout Options

| Layout | Description |
|--------|-------------|
| **Post as Background** | The original post (text, image, or video) is displayed as a background, with your video reaction overlaid on top. Similar to TikTok's green screen effect. |
| **Entity Segmentation (Testing)** | AI-powered feature that isolates your video (removes background) and overlays just you on screen. |

- More limited than TikTok's 5 layouts.
- No traditional side-by-side split screen.

### 5.2 Audio Controls

- Not extensively documented.
- Your recorded audio is the primary track.
- If reacting to a video post, the original video's audio handling is unclear.

### 5.3 Duration Limits

- Follows X's standard video upload limits (up to 2 minutes 20 seconds for standard users, longer for Premium).

### 5.4 Content Types

- **Video posts:** Yes.
- **Image posts:** Yes.
- **Text posts:** Yes -- this is a differentiator. You can video-react to a plain text tweet.
- Most versatile in terms of source content types.

### 5.5 UX/Recording Flow

1. Open a post you want to react to.
2. Select the **video reaction** option.
3. **Record** your reaction with the original post visible as background.
4. **Post** as a reply or quote post.

### 5.6 Attribution/Credit

- The original post is embedded within the video reaction.
- Functions as a reply or quote post, maintaining the conversation thread.

### 5.7 Privacy/Controls

- Limited documentation on per-post opt-out for video reactions.
- Standard reply/quote controls apply.

---

## 6. Facebook Reels Remix

Facebook's Remix is essentially the same as Instagram's Remix (both Meta products), with minor differences.

### 6.1 Layout Options

- **Side-by-side:** Your reel next to the original.
- **Sequential (After):** Your clip plays after the original.
- Same layout options as Instagram Reels Remix (horizontal split, vertical split, PiP, green screen, sequential).

### 6.2 Audio Controls

- Same as Instagram: audio mix window, volume adjustment between original and your audio.

### 6.3 Duration Limits

- Facebook Reels: up to 90 seconds.

### 6.4 Content Types

- **Reels/videos:** Yes.
- **Photos:** Yes (same expansion as Instagram).
- As of 2025, all new Facebook videos are automatically Reels.

### 6.5 Privacy/Controls

- **Per-Reel toggle:** Disable remixing on individual Reels.
- **Audience settings:** Public (anyone can remix, use original audio), Friends (only friends see/remix), Friends Except.
- Only public Reels are remixable by non-friends.

---

## 7. Cross-Platform Comparison Table

| Feature | TikTok | Instagram | YouTube Shorts | Snapchat | X (Twitter) | Facebook |
|---------|--------|-----------|---------------|----------|-------------|----------|
| **Side-by-Side** | Yes | Yes | Yes | Yes | No | Yes |
| **Top-Bottom** | Yes | Yes | No | Yes | No | Yes |
| **PiP/React** | Yes (circle) | Yes | Yes | Yes | No | Yes |
| **Green Screen** | Yes | Yes | Yes | No | Yes (primary) | Yes |
| **Sequential** | No (Stitch) | Yes | No | Yes | No | Yes |
| **Three Screen** | Yes | No | No | No | No | No |
| **Remix Photos** | No | Yes | No | Yes (Snaps) | Yes (tweets) | Yes |
| **Remix Text** | No | No | No | No | Yes | No |
| **Audio Sliders** | Yes (2) | Yes | Basic | Undocumented | Undocumented | Yes |
| **Max Duration** | 10 min | 90 sec | 60 sec | 60 sec | 2m 20s | 90 sec |
| **Disable Per-Post** | Yes | Yes | Partial | Limited | Limited | Yes |
| **Disable Globally** | Yes | Yes | Yes (long-form) | N/A | N/A | Yes |
| **AI Remix Tools** | No | No | Yes (2026 test) | No | Entity seg. | No |
| **Trim Original** | Yes | Yes | Yes (crop) | No | No | Yes |

---

## 8. Technical Architecture

### 8.1 Rendering: Client-Side vs Server-Side

All major platforms use a **client-side compositing** approach:

- **During recording:** The app renders both video feeds in real-time on the device (original playback + camera feed) using the device's GPU.
- **During editing:** Layout, audio mixing, effects, and filters are all applied client-side.
- **Upload:** The final composited video is uploaded as a **single merged video file** (MP4). The server receives one file, not separate tracks.
- **Server-side processing:** After upload, the platform transcodes the single file into multiple resolutions and formats for different devices/network conditions, same as any other video upload.

**Why client-side:**
- Reduces server compute costs (billions of videos).
- Provides real-time preview during recording.
- Allows instant editing without network latency.
- The user sees exactly what will be posted.

### 8.2 Video Resolution & Aspect Ratio

| Platform | Native Aspect | Resolution | Duet/Remix Resolution |
|----------|--------------|------------|----------------------|
| TikTok | 9:16 | 1080x1920 | Each half ~540x960 in side-by-side; full canvas remains 1080x1920 |
| Instagram | 9:16 | 1080x1920 | Similar split to TikTok for side-by-side |
| YouTube Shorts | 9:16 | 1080x1920 | Similar approach |
| Snapchat | 9:16 | 1080x1920 | Platform-native |
| X | 16:9 or 9:16 | Variable | Post embedded in video background |
| Facebook | 9:16 | 1080x1920 | Same as Instagram |

### 8.3 Storage Model

- **Single merged file** is the universal approach. No platform stores duets/remixes as separate video tracks that are composited on playback.
- The server stores a reference/link to the original video for attribution purposes (metadata, not video data).
- Original video continues to exist independently -- deleting the original does NOT delete existing duets/remixes (they are self-contained files).

---

## 9. Best Practices & Recommendations for TAJIRI

### 9.1 Must-Have Layouts (Priority Order)

1. **Side-by-Side (Left/Right)** -- The most recognized and used layout. Universal across all platforms. Start here.
2. **React/PiP** -- Small overlay of the reactor on top of the original. Second most popular. Great for commentary.
3. **Green Screen** -- Original as background, user in foreground. Very popular for educational/commentary content.
4. **Top-Bottom** -- Clean vertical split. Good for tutorials and comparisons.
5. **Sequential** -- User's clip plays after the original. Unique storytelling capability (Instagram's innovation).

### 9.2 Audio Implementation

- **Two independent volume sliders** are essential (Original Sound + Your Sound).
- Allow muting either track completely (0-100% range).
- Volume controls should be in the post-recording edit phase.
- Consider allowing a third audio track (background music from library).

### 9.3 Privacy Controls (Essential)

- **Per-post toggle** to enable/disable replies/duets.
- **Global account setting** (Everyone / Friends / No One).
- **During upload** option to disable before publishing.
- Default should be "Everyone" for public accounts.

### 9.4 Content Type Support

- Start with **video-to-video** duets (core feature).
- Phase 2: Support **image/photo** remix (Instagram proved this is valuable).
- Phase 3: Support **text post** video reactions (X's differentiator, good for TAJIRI's social feed).

### 9.5 Technical Recommendations

- **Client-side compositing** using Flutter's canvas/rendering pipeline or a native video compositing library (e.g., `ffmpeg_kit_flutter` for final encoding).
- **Real-time preview** during recording using two video players + camera overlay.
- Upload the **single merged MP4 file** to the backend.
- Store a **foreign key reference** to the original post for attribution/linking.
- Backend should store: `reply_to_post_id`, `reply_type` (duet/remix), `layout_used`.
- **Resolution:** Maintain 1080x1920 (9:16) for the final output regardless of layout.
- **Countdown timer** (3-2-1) for hands-free recording.
- **Trim slider** for selecting a segment of the original video.
- **Preview screen** before posting is mandatory.

### 9.6 UX Flow Recommendation

1. User taps Share/Reply on a post.
2. Selects "Video Reply" / "Duet".
3. **Trim screen:** Slider to select segment of original (or use full).
4. **Layout picker:** Horizontal strip of layout thumbnails (side-by-side, react, green screen, top-bottom, sequential).
5. **Recording screen:** Split view with original playing + camera feed. Timer, filters, flip camera, effects on right rail.
6. **Edit screen:** Volume sliders (original + yours), add text/stickers, add music track, preview playback.
7. **Post screen:** Caption, hashtags, who can see, who can re-duet. Automatic attribution to original creator.

### 9.7 Attribution Display

- Show original creator's username + profile photo on the duet post.
- Tappable link to the original post.
- Caption should auto-include attribution text (e.g., "Duet with @username").
- Both the original and the duet should appear in search/discovery.
