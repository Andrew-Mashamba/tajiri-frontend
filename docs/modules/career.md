# Career / Kazi — Feature Description

## Tanzania Context

Career development and job placement for Tanzanian students and graduates is one of the most broken systems in the education-to-employment pipeline:

- **Internship/attachment crisis** — Most degree programs require industrial training ("practical attachment") but universities provide minimal placement support. Students scramble to find placements through personal connections ("ukoo" — family network). Students without connections often fabricate attachment reports
- **Notice board job postings** — Many companies still post job advertisements on university notice boards. Students check these physically and manually. By the time you see it, the deadline may have passed
- **CV culture** — Most Tanzanian students have never written a CV before graduation. Career counseling is minimal. Students copy each other's CV formats, resulting in nearly identical, poorly structured documents
- **"Watu wetu" culture** — Hiring in Tanzania is heavily influenced by personal connections. "It's not what you know, it's who you know" is deeply true. This disadvantages talented students without networks
- **Youth unemployment** — Tanzania's youth unemployment rate is estimated at 13-14% officially, but underemployment is much higher. Graduates often take jobs unrelated to their degrees
- **NACTVET and professional registration** — Some careers require professional body registration (ERB for engineers, MCT for accountants, NBAA). Students don't know the requirements or timelines
- **Entrepreneurship push** — The government encourages self-employment ("kujiajiri"), and some universities have entrepreneurship courses. But practical support (funding, mentorship, market access) is lacking
- **Public sector hiring** — Government jobs are posted on ajira.go.tz and portal.opras.go.tz. These portals are confusing and frequently crash during application periods
- **Alumni disconnect** — Universities have weak alumni networks. Graduated students who could mentor or hire don't stay connected with their institutions
- **Skills gap** — Employers consistently cite a gap between what universities teach and what the job market needs. Digital skills, soft skills, and practical experience are common gaps

## International Reference Apps

1. **Handshake** — University career platform with employer connections, job/internship listings, virtual fairs, on-campus recruiting. Used by 1,400+ universities and 700K+ employers.
2. **LinkedIn (Students)** — Professional networking, job search, skill endorsements, learning courses, alumni connections. Global standard for career development.
3. **Indeed** — Job search aggregator with resume builder, company reviews, salary data, application tracking. Largest job site globally.
4. **Glassdoor** — Company reviews, salary transparency, interview questions, job listings. Employee perspective on companies.
5. **Internshala** — Indian internship platform with filtered search, resume builder, online courses, stipend information. Good model for developing market.

## Feature List

1. Internship/attachment listings: browse opportunities by field, company, location, duration
2. Job board: entry-level and graduate positions with salary ranges (where disclosed)
3. Filter by: field of study, location (Dar, Arusha, Dodoma, remote), company size, industry
4. CV/resume builder: step-by-step wizard with templates suited to Tanzanian job market
5. Cover letter templates: customizable templates for common application types (internship, graduate, government)
6. Portfolio section: showcase projects, code, designs, writing samples
7. Interview preparation: common interview questions with example answers, tips for Tanzanian employers
8. Company profiles: information about employers — culture, size, industry, open positions, reviews
9. Career events: career fairs, employer talks, networking events, workshops
10. Alumni network: connect with graduates from your institution who work in your target industry
11. Mentorship matching: find mentors in your field for guidance and networking
12. Application tracker: track status of all job/internship applications (Applied, Under Review, Interview, Offer, Rejected)
13. Skill assessments: take tests in common skills (Excel, Python, English, accounting) and earn badges
14. Professional body registration guide: requirements for ERB, MCT, NBAA, TLS, and other bodies
15. Government job alerts: notifications when new positions are posted on ajira.go.tz
16. Salary information: salary ranges by industry, position, and experience level in Tanzania
17. Career quiz: assessment to suggest suitable career paths based on interests and skills
18. Entrepreneurship resources: business plan templates, funding opportunities, SME support programs
19. Certificate upload: store and share academic certificates, professional certifications
20. Recommendation letters: request and manage recommendation letters from lecturers/supervisors
21. Job readiness checklist: TIN registration, NSSF enrollment, bank account, professional body, email setup
22. Career blog/tips: articles on job market trends, interview tips, career development in East Africa

## Key Screens

- **Career Home** — Featured opportunities, recent listings, application stats, career events
- **Job/Internship Listings** — Filterable list with company logo, title, location, deadline, stipend/salary
- **Job Detail** — Full description, requirements, company info, apply button, save, share
- **CV Builder** — Multi-step form: personal info, education, experience, skills, references, preview
- **Application Tracker** — Kanban or list view of all applications with status indicators
- **Company Profile** — Company info, open positions, reviews, alumni who work there
- **Interview Prep** — Question bank by category (behavioral, technical, HR), practice mode
- **Alumni Network** — Browse alumni by institution, graduation year, company, industry
- **Skill Assessments** — Available tests with difficulty level, time estimate, badge reward
- **Career Events** — Calendar of career fairs, workshops, employer talks with RSVP
- **My Portfolio** — Showcase of work samples, projects, and certifications
- **Settings** — Job alert preferences, privacy settings, profile visibility

## TAJIRI Integration Points

- **ProfileService.getProfile()** — Career profile extends TAJIRI profile; CV data (education, skills, experience) pulled from profile; professional information display
- **PostService.createPost() / sharePost()** — Share job postings, career tips, and achievement updates to the TAJIRI feed
- **MessageService.sendMessage()** — Direct message recruiters or alumni through TAJIRI messaging
- **WalletService.deposit(amount, provider:'mpesa')** — Pay for premium features (CV review, skill courses) or receive internship stipends
- **GroupService.createGroup() / joinGroup()** — Career-focused groups (industry meetups, job seekers, entrepreneurs)
- **NotificationService + FCMService** — Job alerts, application status updates, and deadline reminders via push notifications
- **CalendarService.createEvent()** — Career fair dates, interview schedules, and application deadlines synced to calendar
- **FriendService.getMutualFriends()** — Discover mutual connections at target companies for referrals
- **PeopleSearchService.search(employer:)** — Find alumni and professionals at specific companies or industries
- **PhotoService.uploadPhoto()** — Upload ID photos, certificates, and portfolio images for applications
- **VideoUploadService** — Record video introductions and portfolio presentations
- **events/ module** — Career fairs, employer talks, and networking events integrate with TAJIRI events
- **results module** — GPA and academic transcript accessible for job/internship applications
- **business/ module** — Entrepreneurship resources link to TAJIRI business tools; student businesses and side hustles
- **newton module** — AI helps with CV writing, cover letter drafting, and interview preparation
- **my_class module** — Career advice relevant to your field of study
- **fee_status module** — Link to HESLB repayment tracking once employed
