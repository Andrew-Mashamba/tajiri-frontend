# Newton AI — Implementation Plan

## Overview
AI-powered study companion named after Isaac Newton. Socratic tutor that explains and teaches rather than giving answers directly. Features text Q&A in English/Swahili, photo question solver (handwritten/printed), step-by-step explanations with LaTeX math rendering, subject-specific modes, curriculum alignment (NECTA syllabus), practice problem generation, conversation history, and educational guardrails.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/newton/
├── newton_module.dart
├── models/
│   ├── newton_conversation.dart
│   ├── newton_message.dart
│   └── subject_mode.dart
├── services/
│   └── newton_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── newton_chat_page.dart
│   ├── photo_capture_page.dart
│   ├── conversation_history_page.dart
│   ├── saved_explanations_page.dart
│   ├── practice_mode_page.dart
│   ├── subject_picker_page.dart
│   └── newton_settings_page.dart
└── widgets/
    ├── newton_message_bubble.dart
    ├── latex_renderer.dart
    ├── step_by_step_view.dart
    ├── subject_chip.dart
    ├── photo_capture_button.dart
    └── usage_indicator.dart
```

### Data Models
```dart
class NewtonConversation {
  final int id;
  final String subject, title;
  final List<NewtonMessage> messages;
  final DateTime createdAt, updatedAt;
  factory NewtonConversation.fromJson(Map<String, dynamic> j) => NewtonConversation(
    id: _parseInt(j['id']),
    subject: j['subject'] ?? 'general',
    title: j['title'] ?? '',
    messages: (j['messages'] as List?)?.map((m) => NewtonMessage.fromJson(m)).toList() ?? [],
    createdAt: DateTime.parse(j['created_at']),
  );
}

class NewtonMessage {
  final int id;
  final String role;            // user, newton
  final String content;
  final String? imageUrl;       // for photo questions
  final String? latexContent;   // for math rendering
  final List<String> steps;     // step-by-step breakdown
  final DateTime createdAt;
}

class SubjectMode {
  final String id, name, icon;  // mathematics, physics, chemistry, biology, etc.
  final String difficultyLevel; // form1_4, form5_6, university
}
```

### Service Layer
```dart
class NewtonService {
  static Future<NewtonMessage> askQuestion(String token, Map body);            // POST /api/newton/ask
  static Future<NewtonMessage> askFromPhoto(String token, File photo, Map b);  // POST /api/newton/ask-photo (multipart)
  static Future<NewtonMessage> generatePractice(String token, Map body);       // POST /api/newton/practice
  static Future<List<NewtonConversation>> getHistory(String token);            // GET /api/newton/history
  static Future<NewtonConversation> getConversation(String token, int id);     // GET /api/newton/history/{id}
  static Future<void> saveExplanation(String token, int messageId);            // POST /api/newton/save/{messageId}
  static Future<List<NewtonMessage>> getSaved(String token);                   // GET /api/newton/saved
  static Future<Map> getUsageStats(String token);                              // GET /api/newton/usage
  static Future<void> reportIncorrect(String token, int messageId, String r);  // POST /api/newton/report/{messageId}
}
```

### Pages & Widgets
- **NewtonChatPage**: main conversation with text input, camera button, subject mode selector, streaming response
- **PhotoCapturePage**: camera view with crop/enhance for handwritten questions
- **ConversationHistoryPage**: list of past conversations with search, organized by subject
- **SavedExplanationsPage**: bookmarked answers organized by subject and topic
- **PracticeModePage**: AI generates questions, student answers, AI provides feedback
- **SubjectPickerPage**: grid of subjects with icons, select mode before asking
- **NewtonSettingsPage**: language, difficulty level, daily usage, guardrail preferences

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Chat-style interface: user messages right-aligned, Newton responses left-aligned
- Newton responses use rich formatting: LaTeX equations, numbered steps, diagrams
- Dark hero area: subject mode selector bar at top

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Newton AI          [⏱ ⚙]  │
├──────────────────────────────┤
│ [Math][Physics][Chem][Bio]▸  │
├──────────────────────────────┤
│                              │
│         ┌──────────────┐     │
│         │ What is the  │     │
│         │ derivative   │     │
│         │ of sin(x)?   │     │
│         └──────────────┘     │
│ ┌────────────────────────┐   │
│ │ Newton:                │   │
│ │ Step 1: Recall that... │   │
│ │ Step 2: d/dx[sin(x)]   │   │
│ │        = cos(x)        │   │
│ │ Step 3: Therefore...   │   │
│ │                        │   │
│ │ 💡 Try: What is the    │   │
│ │ derivative of cos(x)?  │   │
│ └────────────────────────┘   │
│                              │
├──────────────────────────────┤
│ [📷] [Type your question...] │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE newton_conversations(id INTEGER PRIMARY KEY, subject TEXT, title TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_nc_subject ON newton_conversations(subject);

CREATE TABLE newton_messages(id INTEGER PRIMARY KEY, conversation_id INTEGER, role TEXT, content TEXT, json_data TEXT);
CREATE INDEX idx_nm_conv ON newton_messages(conversation_id);

CREATE TABLE saved_explanations(id INTEGER PRIMARY KEY, message_id INTEGER, subject TEXT, json_data TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — saved explanations, history, formula references
- Offline write: NO — requires API for AI responses; queue questions for when online

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE newton_conversations(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  subject VARCHAR(50), difficulty_level VARCHAR(20),
  title VARCHAR(255), created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE newton_messages(
  id SERIAL PRIMARY KEY, conversation_id INT REFERENCES newton_conversations(id),
  role VARCHAR(10),  -- user, newton
  content TEXT, image_url TEXT, latex_content TEXT,
  steps JSONB, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE saved_explanations(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  message_id INT REFERENCES newton_messages(id),
  UNIQUE(user_id, message_id)
);
CREATE TABLE newton_usage(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  date DATE DEFAULT CURRENT_DATE, question_count INT DEFAULT 0,
  UNIQUE(user_id, date)
);
CREATE TABLE newton_reports(
  id SERIAL PRIMARY KEY, message_id INT REFERENCES newton_messages(id),
  reporter_id INT REFERENCES users(id), reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/newton/ask | Text question (streaming) | Bearer |
| POST | /api/newton/ask-photo | Photo question (multipart) | Bearer |
| POST | /api/newton/practice | Generate practice problems | Bearer |
| GET | /api/newton/history | Conversation list | Bearer |
| GET | /api/newton/history/{id} | Single conversation | Bearer |
| POST | /api/newton/save/{msgId} | Save explanation | Bearer |
| GET | /api/newton/saved | Saved explanations | Bearer |
| GET | /api/newton/usage | Usage stats/limits | Bearer |
| POST | /api/newton/report/{msgId} | Report incorrect answer | Bearer |

### Controller
`app/Http/Controllers/Api/NewtonController.php` — proxies to AI service (OpenAI/Claude) with system prompt enforcing Socratic teaching, curriculum alignment, and educational guardrails.

---

## 5. Integration Wiring
- class_chat module — @newton mention triggers AI response in conversation
- class_notes module — "Explain this" button sends note content to Newton
- past_papers module — "Solve this question" opens Newton with context
- exam_prep module — Newton generates flashcards and quiz questions
- assignments module — "Help me understand" opens Socratic mode
- study_groups module — Newton joins group sessions as AI participant
- library module — Newton references books in digital library
- results module — "What GPA do I need?" calculations
- PhotoService — snap photo of question for AI interpretation
- WalletService — premium subscription for unlimited questions

---

## 6. Implementation Phases

### Phase 1 — Core Chat (Week 1-2)
- [ ] NewtonConversation and NewtonMessage models, service, SQLite cache
- [ ] Newton chat page with text input and streaming response
- [ ] Subject mode selector
- [ ] Basic step-by-step response rendering

### Phase 2 — Photo & Math (Week 3)
- [ ] Photo capture page with crop/enhance
- [ ] Photo question submission and AI interpretation
- [ ] LaTeX equation rendering (flutter_math_fork)
- [ ] Swahili language support in prompts

### Phase 3 — History & Practice (Week 4)
- [ ] Conversation history page with search
- [ ] Save/bookmark explanations
- [ ] Practice problem generator
- [ ] Usage tracking and daily limits

### Phase 4 — Integrations (Week 5-6)
- [ ] @newton mention in class chat
- [ ] "Explain this" from notes viewer
- [ ] "Solve this" from past papers
- [ ] Educational guardrails (refuse direct essay writing)
- [ ] Voice input for questions
- [ ] Report incorrect answers

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Anthropic Claude API | Anthropic | Primary AI tutoring, Socratic explanations, problem solving | Haiku 4.5: $1/$5 per M tokens; Sonnet 4.6: $3/$15; Opus 4.6: $5/$25 | **Already in TAJIRI backend.** Best reasoning capability. 1M context window. Prompt caching saves 90%. Batch API saves 50%. Use Haiku for simple Q&A, Sonnet for complex tutoring. |
| Wolfram Alpha API | Wolfram | Step-by-step math solutions, verified computation | Free: 2,000 calls/mo; Paid from $5/mo | Full Results API and Short Answers API. Excellent for STEM subjects. Returns verified mathematical results -- complements AI for accuracy. |
| Google ML Kit Text Recognition | Google | On-device OCR for photo math questions | Free | Flutter package: `google_mlkit_text_recognition ^0.15.0`. Captures handwritten/printed math from camera for AI interpretation. iOS/Android only. |
| Newton API (open-source) | Newton | Basic math operations (derive, integrate, simplify) | Free, no API key | Simple REST: `https://newton.now.sh/api/v2/:operation/:expression`. Limited scope but useful for quick math verification. |
| OpenAI API | OpenAI | Alternative AI tutoring, code help | GPT-4o: $2.50/$10 per M tokens | Backup AI provider. Good for code-related tutoring. |
| Google Gemini API | Google | Multimodal AI (image+text analysis) | Free tier available; Paid from $3.50/M tokens | Can analyze photos of math problems directly. Alternative multimodal option. |

**Recommendation:** Anthropic Claude API as primary (already in TAJIRI backend). Wolfram Alpha for verified math computation. Google ML Kit for math photo capture.

### Integration Priority
1. **Immediate** -- Anthropic Claude API (already integrated in TAJIRI backend), Google ML Kit Text Recognition (free, on-device OCR via `google_mlkit_text_recognition` on pub.dev), Newton API (free, no key, basic math verification)
2. **Short-term** -- Wolfram Alpha API (2,000 free calls/mo, verified step-by-step math solutions)
3. **Partnership** -- Google Gemini API (multimodal alternative for complex image-based questions)
