# Newton AI — Feature Description

## Tanzania Context

AI-powered education tools are a massive opportunity in Tanzania, where student-to-teacher ratios are among the highest in Africa. In many secondary schools, one teacher handles 80-120 students per class. University lecturers may have 500+ students with minimal tutorial support. This creates a knowledge gap that students currently fill through:

- **WhatsApp question chains** — A student posts a question in a group, hoping someone knows the answer. Quality varies wildly and wrong answers spread as truth
- **ChatGPT adoption** — University students in urban areas have started using ChatGPT, but face barriers: requires VPN in some cases, needs data bundles, responses are in English and not contextualized to Tanzanian curriculum
- **Private tuition** — Families pay TZS 20,000-100,000/month for private tutors, a significant expense. Tutors are concentrated in Dar es Salaam and Arusha, leaving rural students underserved
- **Photomath phenomenon** — Students have discovered Photomath for solving math problems by photo, but it doesn't cover Tanzanian curriculum specifically
- **Language barrier** — Many students think better in Swahili but study materials are in English. The cognitive load of translating while learning is significant
- **Curriculum specificity** — Tanzania follows its own curriculum (NECTA syllabus for secondary, institution-specific for universities). Global AI tools don't understand this context
- **Cheating concern** — Educators worry AI will be used for plagiarism. Newton must balance helpfulness with educational integrity

Newton AI, named after Isaac Newton, positions itself as a study companion that explains and teaches rather than just giving answers.

## International Reference Apps

1. **ChatGPT (OpenAI)** — General AI assistant with broad knowledge, multi-modal input (text, images), conversation memory. The benchmark for AI assistants.
2. **Khanmigo (Khan Academy)** — AI tutor that guides students through problems with Socratic questioning rather than giving direct answers. Educational guardrails built-in.
3. **Photomath** — Camera captures math problem, provides step-by-step solution with explanation. 300M+ downloads. Math-focused excellence.
4. **Socratic by Google** — Photo of homework question, AI provides explanations, videos, and relevant resources. Multi-subject support.
5. **Wolfram Alpha** — Computational knowledge engine for math, science, engineering. Step-by-step solutions with premium. Academic gold standard.

## Feature List

1. Text-based Q&A: type questions in English or Swahili and receive detailed explanations
2. Photo question solver: take a photo of handwritten or printed question, AI interprets and solves
3. Step-by-step explanations: never just the answer — always show the reasoning and method
4. Subject-specific modes: Mathematics, Physics, Chemistry, Biology, History, Geography, English, Kiswahili, Commerce, Accounting, Computer Science
5. Swahili language support: ask in Swahili, receive answers in Swahili (or mixed Swahili-English as natural for Tanzanian students)
6. Curriculum alignment: responses reference NECTA syllabus topics, Tanzanian textbooks, and local examples
7. Socratic mode: instead of giving the answer, Newton asks guiding questions to help student discover the solution
8. Math equation renderer: proper display of mathematical formulas, graphs, and diagrams
9. Chemistry structure drawer: display molecular structures, chemical equations, periodic table references
10. Physics diagram generator: force diagrams, circuit diagrams, motion graphs
11. Follow-up questions: conversation memory within a session for deeper exploration of a topic
12. Exam-style question generator: "Give me 5 NECTA-style questions on quadratic equations"
13. Difficulty levels: explain concepts at Form 1-4, Form 5-6, or university level
14. Practice problem generator: unlimited practice with immediate feedback
15. Textbook references: cite specific Tanzanian textbooks (e.g., "See Tanzania Institute of Education Mathematics Book 3, Chapter 7")
16. Save conversations: bookmark helpful explanations for later review
17. History: browse past questions and answers
18. Educational guardrails: refuses to write essays or complete assignments directly, guides learning instead
19. Voice input: speak your question when typing is inconvenient
20. Offline mode for basic features: formula references, saved conversations, periodic table
21. Daily question limit for free tier, unlimited for premium
22. Report incorrect answers: community feedback loop for AI improvement
23. Topic suggestions: "Students studying [subject] often ask about..." prompts
24. Integration with class notes for context-aware answers

## Key Screens

- **Newton Chat** — Main conversation interface with text input, camera button, and subject mode selector
- **Photo Capture** — Camera view with crop and enhance for capturing written questions
- **Solution Display** — Rich text response with LaTeX equations, diagrams, step numbering
- **Subject Picker** — Grid of subjects with icons, select mode before asking
- **Conversation History** — List of past conversations with search, organized by subject
- **Saved Explanations** — Bookmarked answers organized by subject and topic
- **Practice Mode** — AI generates questions, student answers, AI provides feedback
- **Settings** — Language preference, difficulty level, daily usage stats, guardrail preferences

## TAJIRI Integration Points

- **PhotoService.uploadPhoto()** — Snap a photo of a handwritten or printed question; Newton interprets and solves with step-by-step explanation
- **ClipService** — Video explanations generated or linked for complex topics; short video walkthroughs
- **MessageService.sendMessage()** — @newton mention in class chat triggers AI response within the conversation context
- **WalletService.deposit(amount, provider:'mpesa')** — Premium Newton features (unlimited questions, advanced subjects) via TAJIRI wallet subscription
- **ProfileService.getProfile()** — "Questions asked" and "Subjects explored" stats display on TAJIRI profile
- **GroupService.getMembers()** — Newton can be added to study group sessions as an AI participant for all members
- **NotificationService** — Study reminders and daily question prompts via push notifications
- **class_chat module** — @newton mention in class chat triggers contextual AI response
- **class_notes module** — "Explain this" button on uploaded notes sends content to Newton for AI explanation
- **past_papers module** — "Solve this question" button on past paper questions opens Newton with full context
- **exam_prep module** — Newton generates flashcards and quiz questions from specified topics
- **assignments module** — "Help me understand" button opens Newton in Socratic mode (guides learning, doesn't solve directly)
- **study_groups module** — Newton joins group sessions as an AI participant, answering questions in real-time
- **library module** — Newton references books available in the TAJIRI digital library for further reading
- **results module** — "What GPA do I need this semester?" calculations powered by Newton
