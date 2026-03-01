# Group Chats & Event Tools — Scope

Product scope for group messaging and in-group events (as reported in betas).

---

## Group Chats

- **Large groups with roles** — Admins, moderators, members; role-based permissions.
- **@all mentions** — Notify all members in a group chat.
- **Group metadata and member tags** — Info (name, description, rules) and tags/labels for members (e.g. admin, moderator).
- **See who’s online** — Online/presence indicators for group members at a glance.
- **Voice chats** — Ongoing audio rooms where members can join (voice-only group calls).

**Current codebase (reference):**

| Area | Location | Notes |
|------|----------|--------|
| Groups (community) | `lib/screens/groups/`, `lib/models/group_models.dart`, `lib/services/group_service.dart` | Groups have `userRole`, `isAdmin`; creator, members, posts. |
| Chat (1:1 / convos) | `lib/screens/messages/chat_screen.dart`, `lib/models/message_models.dart`, `lib/services/message_service.dart` | Conversations, messages, typing, reply; not yet “group chat” with roles/@all. |
| Group call (voice) | `lib/screens/messages/group_call_screen.dart`, `lib/services/group_call_service.dart` | Story 60: group call from group chat; start/join, participants, mute/video. |
| Mentions (posts) | `lib/widgets/mention_text_field.dart`, `lib/widgets/rich_comment_content.dart` | Mention parsing in posts/comments; @all in group chat would be separate. |

Gaps vs scope: dedicated group chat with roles, @all, member tags, online presence, and “voice chat” as ongoing room (vs one-off group call) to be aligned with backend and design.

---

## Event Tools (reported in betas)

- **Tools for organising events** — Create/manage events (name, time, place, description, etc.).
- **RSVPs** — Invitees can respond (e.g. going / not going / maybe).

**Current codebase (reference):**

| Area | Location | Notes |
|------|----------|--------|
| Events (standalone) | `lib/screens/events/`, `lib/models/event_models.dart`, `lib/services/event_service.dart` | Events list, detail, create; event attendees. |
| Events inside groups | `lib/screens/groups/events_screen.dart`, `lib/screens/groups/createevent_screen.dart`, `lib/screens/groups/create_event_screen.dart` | Events tied to groups; create event from group. |
| Event attendees / RSVP | `lib/screens/events/event_attendees_screen.dart` | View who’s attending (or similar); RSVP flow to be confirmed. |

Gaps vs scope: full “event tools” and RSVP flows inside groups to be aligned with backend and beta feedback.

---

## Next steps

- **Backend:** Confirm APIs for group chat (roles, @all, presence, voice rooms) and for in-group events + RSVP.
- **Frontend:** Implement or refine UI for group chat (roles, @all, tags, online), voice chat (ongoing room vs group call), and event tools + RSVP per DESIGN.md and NAVIGATION.md.
