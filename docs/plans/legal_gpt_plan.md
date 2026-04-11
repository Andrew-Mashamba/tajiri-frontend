# LegalGPT — Implementation Plan

## Overview
AI-powered legal assistant for Tanzania providing legal Q&A in Swahili/English citing Tanzanian law, Know Your Rights cards, document templates (contracts, wills, demand letters), court procedure guides, lawyer/legal aid directory, contract review, case tracking, and emergency legal hotline. Addresses the 80%+ of Tanzanians who cannot afford a lawyer.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/legal_gpt/
├── legal_gpt_module.dart
├── models/
│   ├── legal_chat_models.dart
│   ├── template_models.dart
│   └── lawyer_models.dart
├── services/
│   └── legal_gpt_service.dart
├── pages/
│   ├── legal_chat_page.dart
│   ├── rights_cards_page.dart
│   ├── document_templates_page.dart
│   ├── court_guide_page.dart
│   ├── lawyer_search_page.dart
│   ├── legal_aid_map_page.dart
│   ├── topic_guides_page.dart
│   ├── document_review_page.dart
│   ├── case_tracker_page.dart
│   └── emergency_legal_page.dart
└── widgets/
    ├── chat_bubble.dart
    ├── rights_card.dart
    ├── template_preview.dart
    ├── lawyer_card.dart
    └── case_status_widget.dart
```

### Data Models
- `LegalMessage` — id, role (user/assistant), content, citations (list of LawCitation), timestamp
- `LawCitation` — lawName, section, summary, fullText
- `DocumentTemplate` — id, name, category, description, fields (list of TemplateField), templateContent
- `Lawyer` — id, name, specializations, location, rating, feeRange, phone, verified
- `LegalAidCenter` — id, name, organization, services, location, phone, hours
- `CourtCase` — id, caseNumber, court, parties, status, nextHearing, history

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `askQuestion(message, history)` | POST | `/api/legal/ask` | `SingleResult<LegalMessage>` |
| `getRightsCards(category)` | GET | `/api/legal/rights` | `PaginatedResult<RightsCard>` |
| `getTemplates(category)` | GET | `/api/legal/templates` | `PaginatedResult<DocumentTemplate>` |
| `searchLawyers(filters)` | GET | `/api/legal/lawyers` | `PaginatedResult<Lawyer>` |
| `getLegalAidCenters(location)` | GET | `/api/legal/aid-centers` | `PaginatedResult<LegalAidCenter>` |
| `reviewDocument(file)` | POST | `/api/legal/review` | `SingleResult<DocumentReview>` |
| `trackCase(caseNumber, court)` | GET | `/api/legal/cases/{number}` | `SingleResult<CourtCase>` |
| `getCourtGuide(courtType)` | GET | `/api/legal/court-guide` | `SingleResult<CourtGuide>` |
| `getDictionary(term)` | GET | `/api/legal/dictionary` | `PaginatedResult<LegalTerm>` |

### Pages
- **LegalChatPage** — AI conversation with citations, Swahili/English toggle, voice input
- **RightsCardsPage** — Swipeable cards by category with illustrations
- **DocumentTemplatesPage** — Browse, preview, fill-in wizard, download/share
- **CourtGuidePage** — Step-by-step per court type with timeline and fees
- **LawyerSearchPage** — Map/list with specialization, location, price filters
- **LegalAidMapPage** — Map of free legal aid centers with services
- **TopicGuidesPage** — Deep articles on land, employment, family, tenant law
- **DocumentReviewPage** — Upload contract, get AI-annotated risky clauses
- **CaseTrackerPage** — Case number input, court selection, hearing dates

### Widgets
- `ChatBubble` — Message with optional citation chips, copy action
- `RightsCard` — Icon, right name, key points, "What to do" CTA
- `LawyerCard` — Photo, name, specializations, rating, fee range, contact
- `CaseStatusWidget` — Case number, court, next hearing, status badge

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  LegalGPT         🌐 │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ 🤖 How can I help?  │ │
│ │ Ask any legal       │ │
│ │ question in Swahili │ │
│ │ or English...       │ │
│ └─────────────────────┘ │
│                         │
│ [Rights] [Templates]    │
│ [Courts] [Lawyers]      │
│                         │
│ Quick Topics            │
│ ├─ 🏠 Land Rights      │
│ ├─ 👷 Employment Law   │
│ ├─ 👨‍👩‍👧 Family Law      │
│ ├─ 🏪 Tenant Rights    │
│ └─ 🚔 Arrest Rights    │
│                         │
│ [Emergency Legal Help]  │
│ ┌─────────────────────┐ │
│ │ Type your question  │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE legal_rights(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE legal_templates(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE legal_chat_history(id INTEGER PRIMARY KEY, user_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_legal_rights_cat ON legal_rights(category);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Rights cards 7d, templates 7d, lawyer directory 24h, dictionary 30d
- Offline read: YES — rights cards, court procedures, dictionary, templates
- Offline write: pending_queue for chat history sync

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE legal_conversations (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    messages JSONB NOT NULL, created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE legal_lawyers (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    name TEXT NOT NULL, specializations JSONB, location TEXT,
    rating DECIMAL(3,2), fee_range TEXT, phone TEXT, verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE legal_templates (
    id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, category TEXT,
    description TEXT, fields JSONB, template_content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/legal/ask | AI legal question | Yes |
| GET | /api/legal/rights | Rights cards | No |
| GET | /api/legal/templates | Document templates | Yes |
| GET | /api/legal/lawyers | Lawyer directory | Yes |
| GET | /api/legal/aid-centers | Legal aid centers | No |
| POST | /api/legal/review | Document review | Yes |
| GET | /api/legal/cases/{number} | Track court case | Yes |
| GET | /api/legal/court-guide | Court procedures | No |
| GET | /api/legal/dictionary | Legal dictionary | No |

### Controller
- `app/Http/Controllers/Api/LegalGptController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Premium legal consultations, lawyer fees, notarization payments
- **MessageService** — Encrypted legal conversations with lawyers
- **NotificationService + FCMService** — Court hearing reminders, legal deadline alerts
- **CalendarService** — Hearing dates, filing deadlines, statute of limitations
- **PhotoService** — Contract/document uploads for AI review
- **LocalStorageService** — Offline rights cards, court procedures, dictionary
- **Cross-module: katiba** — Constitutional provisions (Articles 12-29 Bill of Rights)
- **Cross-module: nida/rita/tra/brela/land_office** — Legal guidance for each government service

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, chat infrastructure, AI integration
- Rights cards content and display

### Phase 2: Core UI (Week 2)
- Chat interface with citations, document templates with fill wizard
- Court procedure guides, lawyer directory with search

### Phase 3: Integration (Week 3)
- Document review upload + AI analysis, case tracker
- Legal aid map, emergency legal hotline connection

### Phase 4: Polish (Week 4)
- Voice input for Swahili questions, offline content caching
- Cross-module linking for all government service legal guidance

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Anthropic Claude API | Anthropic | LLM reasoning engine for legal Q&A, drafting, analysis | Haiku: $1/$5, Sonnet: $3/$15, Opus: $5/$25 per 1M tokens | 1M context window; batch API 50% off; platform.claude.com |
| OpenAI GPT API | OpenAI | Alternative LLM for legal analysis, summarization | GPT-4.1: $2/$8, Mini: $0.40/$1.60 per 1M tokens | 1M context (GPT-4.1); batch API 50% off |
| Laws.Africa Content API | Laws.Africa | Tanzania legal corpus retrieval for RAG pipeline | Free (non-commercial) | laws.africa/api/ — Akoma Ntoso XML, structured |
| Laws.Africa Knowledge Base API | Laws.Africa | Purpose-built legal data retrieval for AI agents | Free (non-commercial) | developers.laws.africa/ai-api/knowledge-bases |
| SAFLII | Southern African Legal Information Institute | Tanzania case law for RAG context | Free | saflii.org — 16 African countries |
| CourtListener API | Free Law Project | Case law reference data | Free (means-based) | courtlistener.com/help/api/ |
| Smile ID | Smile Identity | Client identity verification before legal consultations | Pay-per-verification | docs.usesmileid.com — Pan-African KYC |
| AzamPay API | AzamPay | Payment for legal consultation fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |

### Integration Priority
1. **Immediate** — Claude/GPT API (pay-per-token, well-documented), Laws.Africa APIs (free non-commercial, Tanzania coverage), SAFLII (free)
2. **Short-term** — AzamPay for consultation payments (has Dart SDK), Smile ID for client identity verification
3. **Partnership** — Tanzania Law Society for lawyer directory data, Tanganyika Law Reports for premium case law access
