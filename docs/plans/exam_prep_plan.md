# Exam Prep / Mitihani — Implementation Plan

## Overview
Comprehensive exam preparation toolkit with flashcards (spaced repetition), quiz generator, Pomodoro study timer, exam countdowns, AI-generated study plans, revision checklists with confidence ratings, formula sheets, group quiz battles, and performance analytics. Integrates Newton AI for auto-generating flashcards from notes.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/exam_prep/
├── exam_prep_module.dart
├── models/
│   ├── flashcard_deck.dart
│   ├── flashcard.dart
│   ├── quiz.dart
│   ├── study_session.dart
│   ├── revision_topic.dart
│   └── exam_countdown.dart
├── services/
│   └── exam_prep_service.dart       — AuthenticatedDio.instance
├── pages/
│   ├── exam_prep_dashboard_page.dart
│   ├── flashcard_creator_page.dart
│   ├── flashcard_study_page.dart
│   ├── quiz_mode_page.dart
│   ├── study_timer_page.dart
│   ├── study_plan_page.dart
│   ├── revision_checklist_page.dart
│   ├── exam_countdown_page.dart
│   ├── analytics_page.dart
│   └── formula_sheets_page.dart
└── widgets/
    ├── flashcard_widget.dart
    ├── quiz_question_widget.dart
    ├── pomodoro_timer.dart
    ├── countdown_card.dart
    ├── confidence_indicator.dart
    ├── streak_badge.dart
    └── study_chart.dart
```

### Data Models
```dart
class FlashcardDeck {
  final int id;
  final String title, subject;
  final int cardCount, masteredCount;
  final bool isShared;
  factory FlashcardDeck.fromJson(Map<String, dynamic> j) => FlashcardDeck(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    subject: j['subject'] ?? '',
    cardCount: _parseInt(j['card_count']),
    masteredCount: _parseInt(j['mastered_count']),
  );
}

class Flashcard { int id; String front, back; String? imageUrl; int interval; DateTime nextReview; }
class Quiz { int id; String title, subject; List<QuizQuestion> questions; int? score; }
class QuizQuestion { int id; String question; List<String> options; int correctIndex; String? explanation; }
class StudySession { int id; String subject; int durationMinutes; DateTime date; }
class RevisionTopic { int id; String subject, topic; String confidence; bool completed; } // confidence: red/yellow/green
class ExamCountdown { int id; String subject, venue; DateTime examDate; }
```

### Service Layer
```dart
class ExamPrepService {
  static Future<List<FlashcardDeck>> getDecks(String token);                  // GET /api/exam-prep/decks
  static Future<FlashcardDeck> createDeck(String token, Map body);            // POST /api/exam-prep/decks
  static Future<List<Flashcard>> getCards(String token, int deckId);           // GET /api/exam-prep/decks/{id}/cards
  static Future<void> addCard(String token, int deckId, Map body);            // POST /api/exam-prep/decks/{id}/cards
  static Future<void> updateCardProgress(String token, int cardId, Map b);    // PUT /api/exam-prep/cards/{id}/progress
  static Future<Quiz> generateQuiz(String token, Map body);                   // POST /api/exam-prep/quizzes/generate
  static Future<void> submitQuizResult(String token, int quizId, Map body);   // POST /api/exam-prep/quizzes/{id}/result
  static Future<void> logStudySession(String token, Map body);                // POST /api/exam-prep/sessions
  static Future<Map> getAnalytics(String token);                              // GET /api/exam-prep/analytics
  static Future<List<RevisionTopic>> getChecklist(String token, String subj); // GET /api/exam-prep/checklist
  static Future<List<ExamCountdown>> getExamCountdowns(String token);         // GET /api/exam-prep/countdowns
  static Future<FlashcardDeck> generateFromNotes(String token, int noteId);   // POST /api/exam-prep/generate-from-notes
}
```

### Pages & Widgets
- **ExamPrepDashboardPage**: upcoming exams, study streak, weak topics, quick-action buttons
- **FlashcardStudyPage**: full-screen card flip with swipe left/right, progress bar, spaced repetition
- **QuizModePage**: timed quiz with question display, answer selection, score summary
- **StudyTimerPage**: large Pomodoro timer (25/5 configurable), session counter, ambient sounds
- **StudyPlanPage**: AI-generated calendar of daily topics based on exam dates
- **RevisionChecklistPage**: topic list with completion checks and confidence ratings (red/yellow/green)
- **AnalyticsPage**: charts for study hours, quiz scores, topic mastery

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Flashcard: centered text, tap to flip with animation, swipe gestures
- Dark hero card: study streak count, hours this week, next exam countdown

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Exam Prep              [⋮] │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 🔥 12-day streak         │ │
│ │ 14h studied this week    │ │
│ │ Next: CS201 in 5 days    │ │
│ └──────────────────────────┘ │
│                              │
│ [Flashcards] [Quiz] [Timer]  │
│                              │
│ WEAK TOPICS                  │
│ ┌──────────────────────────┐ │
│ │ 🔴 Binary Trees          │ │
│ │ 🔴 Graph Traversal       │ │
│ │ 🟡 Sorting Algorithms    │ │
│ │ 🟢 Arrays & Linked Lists │ │
│ └──────────────────────────┘ │
│                              │
│ MY DECKS                     │
│ ┌────────────┐ ┌────────────┐│
│ │ CS201      │ │ MA101      ││
│ │ 48 cards   │ │ 32 cards   ││
│ │ 60% done   │ │ 40% done   ││
│ └────────────┘ └────────────┘│
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE flashcard_decks(id INTEGER PRIMARY KEY, subject TEXT, card_count INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE flashcards(id INTEGER PRIMARY KEY, deck_id INTEGER, front TEXT, back TEXT, interval INTEGER, next_review TEXT, json_data TEXT);
CREATE INDEX idx_cards_deck ON flashcards(deck_id);
CREATE INDEX idx_cards_review ON flashcards(next_review);

CREATE TABLE quizzes(id INTEGER PRIMARY KEY, subject TEXT, score INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE study_sessions(id INTEGER PRIMARY KEY, subject TEXT, duration INTEGER, date TEXT, synced_at TEXT);
CREATE TABLE revision_topics(id INTEGER PRIMARY KEY, subject TEXT, confidence TEXT, completed INTEGER, json_data TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — flashcards, quizzes, checklists fully offline
- Offline write: pending_queue for session logs, card progress, quiz results

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE flashcard_decks(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  title VARCHAR(255), subject VARCHAR(255),
  is_shared BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE flashcards(
  id SERIAL PRIMARY KEY, deck_id INT REFERENCES flashcard_decks(id),
  front TEXT, back TEXT, image_url TEXT,
  interval_days INT DEFAULT 1, ease_factor DECIMAL(3,2) DEFAULT 2.5,
  next_review DATE DEFAULT CURRENT_DATE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE quizzes(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  title VARCHAR(255), subject VARCHAR(255),
  score INT, total_questions INT, completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE quiz_questions(
  id SERIAL PRIMARY KEY, quiz_id INT REFERENCES quizzes(id),
  question TEXT, options JSONB, correct_index SMALLINT, explanation TEXT
);
CREATE TABLE study_sessions(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  subject VARCHAR(255), duration_minutes INT,
  session_date DATE DEFAULT CURRENT_DATE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE revision_topics(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  subject VARCHAR(255), topic VARCHAR(255),
  confidence VARCHAR(10) DEFAULT 'red', completed BOOLEAN DEFAULT FALSE
);
CREATE TABLE exam_countdowns(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  subject VARCHAR(255), venue VARCHAR(255),
  exam_date TIMESTAMP, created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/exam-prep/decks | List flashcard decks | Bearer |
| POST | /api/exam-prep/decks | Create deck | Bearer |
| GET | /api/exam-prep/decks/{id}/cards | Get cards in deck | Bearer |
| POST | /api/exam-prep/decks/{id}/cards | Add card | Bearer |
| PUT | /api/exam-prep/cards/{id}/progress | Update SRS progress | Bearer |
| POST | /api/exam-prep/quizzes/generate | AI-generate quiz | Bearer |
| POST | /api/exam-prep/quizzes/{id}/result | Submit quiz result | Bearer |
| POST | /api/exam-prep/sessions | Log study session | Bearer |
| GET | /api/exam-prep/analytics | Study analytics | Bearer |
| GET | /api/exam-prep/checklist | Revision checklist | Bearer |
| GET | /api/exam-prep/countdowns | Exam countdowns | Bearer |
| POST | /api/exam-prep/generate-from-notes | AI flashcards from notes | Bearer |

### Controller
`app/Http/Controllers/Api/ExamPrepController.php`

---

## 5. Integration Wiring
- CalendarService — exam dates and study plan sessions sync to calendar
- NotificationService + FCM — study reminders, exam countdown alerts, streak notifications
- MusicService — study playlists from TAJIRI music during focus sessions
- class_notes module — generate flashcards/quizzes from uploaded notes
- past_papers module — past paper questions feed into quiz mode
- study_groups module — group quiz battles and shared study sessions
- newton module — AI generates questions, explains wrong answers, creates study plans
- timetable module — exam schedule overlay synced with timetable

---

## 6. Implementation Phases

### Phase 1 — Flashcards (Week 1-2)
- [ ] FlashcardDeck and Flashcard models, service, SQLite cache
- [ ] Flashcard creator page
- [ ] Flashcard study page with flip animation and swipe gestures
- [ ] Spaced repetition algorithm (SM-2)

### Phase 2 — Quizzes & Timer (Week 3-4)
- [ ] Quiz model with question types (MCQ, true/false, fill-blank)
- [ ] Quiz mode page with timer and scoring
- [ ] Pomodoro study timer with session tracking
- [ ] Study session logging and streak tracking

### Phase 3 — Planning & Analytics (Week 5)
- [ ] Exam countdown page and widgets
- [ ] Revision checklist with confidence ratings
- [ ] AI-generated study plan (Newton integration)
- [ ] Performance analytics charts

### Phase 4 — Social & AI (Week 6)
- [ ] Auto-generate flashcards from notes (Newton AI)
- [ ] Share decks and quizzes with classmates
- [ ] Community decks browsing
- [ ] Group quiz battles
- [ ] Formula sheets with search

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Open Trivia Database API | OpenTDB | Free trivia questions, 20+ categories | Free, no API key | 4,000+ verified questions. Max 50/call. Rate limit: 1 req/5 sec. Session tokens prevent repeats. Good for general knowledge quizzes. |
| The Trivia API | the-trivia-api.com | Trivia questions with categories | Free, no API key | Alternative to OpenTDB with more questions. |
| Anthropic Claude API | Anthropic | AI-generated flashcards, quiz questions, explanations | From $1/M input tokens (Haiku 4.5) | Generate custom flashcards from any topic. **Already in TAJIRI backend** -- route through Newton AI service. |
| OpenAI API | OpenAI | AI-generated quiz questions | From $2.50/M input tokens (GPT-4o) | Alternative AI for contextual practice question generation. |
| Quizizz API | Quizizz | Gamified quizzes, LMS integration | Free for basic; Paid for schools | Popular in education. AI-powered quiz generation. |

**Tanzania context:** Build custom NECTA-aligned question banks. Use AI APIs (via Newton) to generate Tanzanian curriculum-specific content.

### Integration Priority
1. **Immediate** -- Open Trivia Database (free, no API key, ready to use), Anthropic Claude API (already in TAJIRI backend via Newton service)
2. **Short-term** -- The Trivia API (free alternative with more questions), custom NECTA question bank
3. **Partnership** -- Quizizz (for gamified quiz features and LMS integration)
