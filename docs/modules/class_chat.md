# Class Chat / Gumzo la Darasa — Feature Description

## Tanzania Context

WhatsApp is the undisputed communication tool for Tanzanian students, but it's deeply flawed for academic purposes. A typical university student is in 10-15 WhatsApp groups: one per course unit, a department group, a year group, a hostel group, and several social groups. The problems are severe:

- Important announcements (exam dates, room changes, fee deadlines) get buried under memes, stickers, and off-topic banter
- No way to separate academic discussion from social chat within the same group
- When a student asks a genuine academic question, it's lost in 200+ unread messages within hours
- File sharing is limited: WhatsApp compresses images (notes become unreadable), file size limits prevent sharing large PDFs
- No threading: a question about Topic A gets mixed with answers about Topic B
- Group admins (usually the CR) have limited moderation tools
- Students join mid-semester and can't see message history before they joined
- Lecturers rarely join WhatsApp groups, creating a communication gap
- Exam periods are the worst: groups explode with panic messages, rumors, and requests for past papers

Students have tried Telegram (better file sharing, larger groups) but adoption is low. Some progressive lecturers use Google Classroom but most don't.

## International Reference Apps

1. **Microsoft Teams (Education)** — Channels per subject, threaded replies, file tabs, assignments integration, video calls, moderation. Full classroom collaboration.
2. **Slack** — Organized channels, threads, pinned messages, app integrations, search, file sharing. Best-in-class messaging organization.
3. **Piazza** — Q&A format for classes, instructor-endorsed answers, anonymous posting, wiki-style collaborative answers. Academic-focused.
4. **Discord** — Server channels, voice channels, roles/permissions, threading, bots, screen sharing. Popular with tech students.
5. **Ed Discussion** — Threaded Q&A, code blocks, LaTeX support, categorized posts, instructor highlights. Modern Piazza alternative.

## Feature List

1. Auto-create chat space when a class is created in My Class module
2. Organized channels per subject/unit within a class (e.g., #cs201-data-structures, #cs202-algorithms)
3. General channel for non-academic class discussion and socializing
4. Announcements channel: only CR and lecturers can post, all members receive push notification
5. Threaded replies: respond to specific messages without cluttering the main feed
6. Pin important messages: exam dates, assignment briefs, room changes stay at top
7. File sharing with no compression: PDFs, documents, images, audio recordings at original quality
8. Polls: CR creates polls for class decisions (meeting time, trip destination, contribution amount)
9. Message search: find old messages by keyword, sender, date, or file type
10. Role-based permissions: Lecturer (full access), CR (moderate), Member (chat), Observer (read-only)
11. Mute options: mute specific channels, mute all except announcements, custom schedule mute
12. @mention support: @all for everyone, @cr for class rep, @lecturer for teachers, @username for individuals
13. Message formatting: bold, italic, bullet points, code blocks (for CS students)
14. Voice messages with playback speed control (1x, 1.5x, 2x)
15. Question tagging: mark a message as a "Question" so it appears in a filterable Q&A list
16. Answered/unanswered question tracking: lecturers or CRs can mark questions as resolved
17. Read receipts: see who has read announcements (useful for CRs to track reach)
18. Schedule messages: CR can draft announcements and schedule for specific time
19. Translation support: auto-translate between Swahili and English
20. Media gallery: browse all shared files, photos, and documents in one view
21. Bookmark messages: save important messages to personal collection
22. Offline message queue: compose messages offline, auto-send when connected

## Key Screens

- **Class Chat Home** — List of channels within a class with unread counts and last message preview
- **Channel View** — Message thread with input bar, attachment button, formatting tools
- **Announcements Feed** — Chronological list of official announcements with read status
- **Pinned Messages** — All pinned messages in a channel, sorted by date
- **Q&A Board** — Filtered view of all questions with answered/unanswered status
- **Media Gallery** — Grid view of all shared files, photos, documents in the channel
- **Polls** — Create poll with options, view results with vote counts and percentages
- **Search** — Search across all channels with filters for sender, date, file type
- **Channel Settings** — Manage channel name, description, permissions, notification preferences
- **Members** — List of channel members with roles, last active, mute/remove options

## TAJIRI Integration Points

- **MessageService.sendMessage() / createGroup()** — Class Chat is an extension of TAJIRI messaging; class group conversation auto-created with full messaging infrastructure
- **GroupService.createGroup() / joinGroup()** — Auto-created when a class is formed; membership synced with class roster via group membership
- **GroupService.getMembers()** — Class roster powers member list, roles, and @mention suggestions
- **NotificationService + FCMService** — Announcement channel push notifications, @mention alerts, and urgent broadcasts
- **PhotoService.uploadPhoto()** — Share note photos, whiteboard captures, and documents at original quality (no compression)
- **PostService.sharePost()** — Promote important class chat content to the TAJIRI feed
- **ProfileService.getProfile()** — Tap any member to view their TAJIRI profile with education details
- **ContributionService** — Collect class contributions by posting M-Pesa payment links in chat
- **LiveUpdateService** — Real-time message delivery and read receipt updates
- **class_notes module** — Files shared in chat can be "promoted" to the class notes repository with proper tagging
- **assignments module** — Assignment discussions link to dedicated threads in relevant channels
- **newton module** — @newton mention in chat triggers AI response within the conversation context
- **events/ module** — Create class events from chat and auto-invite all channel members
- **study_groups module** — Spin off study group conversations from class chat discussions
