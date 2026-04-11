# Jumuiya (Small Groups / Cell Groups) — Feature Description

## Tanzania Context

"Jumuiya" (full: Jumuiya Ndogo Ndogo za Kikristo, "Small Christian Communities") is a cornerstone of church life in Tanzania, especially within the Catholic Church. The system was formalized after the 1976 AMECEA plenary in Nairobi and has since been adopted across East Africa. Each parish is divided into geographic jumuiya of 10-30 families who meet weekly (usually Wednesday or Thursday evenings) for Bible study, prayer, and mutual support.

Protestant churches have adopted similar models — called cell groups, home groups, or fellowship groups. These groups serve as the primary pastoral care unit: members visit the sick, contribute to emergencies (harambee), coordinate funerals, and celebrate together. Most jumuiya coordination happens via phone calls and WhatsApp, with no structured tools for scheduling, attendance, resource sharing, or financial tracking.

## International Reference Apps

1. **Church Center (Planning Center Groups)** — Small group finder, scheduling, communication
2. **GroupMe** — Group messaging with calendar events and shared content
3. **Faithlife Groups** — Bible study groups with integrated study tools and discussion
4. **The Bible App (YouVersion Plans with Friends)** — Shared reading plans with group discussion
5. **RightNow Media** — Group Bible study curriculum with video and discussion guides

## Feature List

1. Group finder — discover jumuiya groups by location, church, or topic
2. Group profile — name, description, meeting schedule, location, leader info, member count
3. Weekly meeting schedule — day, time, location (rotating homes), meeting agenda
4. Group membership — join requests, member list with roles (leader, secretary, treasurer)
5. Group chat — dedicated messaging channel for the jumuiya
6. Bible study materials — weekly study guides, discussion questions, scripture readings
7. Meeting agenda — structured agenda template: opening prayer, scripture, discussion, announcements, closing
8. Attendance tracking — check-in for weekly meetings, attendance history
9. Prayer requests — group prayer list with status updates and answered prayer celebrations
10. Contribution tracking — jumuiya financial contributions (emergency fund, church projects)
11. Event coordination — plan group activities (visits, outreach, social events)
12. Leader tools — manage members, assign roles, send announcements, view reports
13. Resource library — shared documents, study guides, meeting notes
14. Photo sharing — group photos from meetings, events, and social activities
15. Visitor tracking — record and follow up with new visitors to the group
16. Annual calendar — jumuiya events, rotating host schedule, church deadlines

## Key Screens

- **Jumuiya Home** — my groups list, next meeting countdown, recent messages
- **Group Finder** — map and list view of nearby jumuiya groups with filters
- **Group Profile** — banner, description, schedule, members, join button
- **Group Chat** — messaging interface with media sharing, prayer request pins
- **Meeting View** — agenda, Bible passage, discussion questions, attendance check-in
- **Bible Study** — guided study with passage, context, questions, notes space
- **Members List** — member cards with roles, contact info, attendance stats
- **Contribution Tracker** — group fund balance, contribution history, member ledger
- **Group Calendar** — meeting schedule, host rotation, events

## TAJIRI Integration Points

- **GroupService.createGroup(), joinGroup(), getMembers()** — each jumuiya is a TAJIRI group with roles (leader, secretary, treasurer); group finder for discovering nearby jumuiya; member management and attendance tracking
- **MessageService.sendMessage(), createGroup()** — jumuiya group chat uses TAJIRI messaging infrastructure; dedicated channel for Bible study discussion, prayer requests, and announcements
- **CalendarService.createEvent()** — weekly meeting schedule synced to personal calendar with reminders; rotating host schedule; jumuiya events and outreach activities
- **NotificationService + FCMService** — meeting reminders, new message alerts, prayer request updates, leader announcements
- **ContributionService.createCampaign(), donate()** — jumuiya financial contributions for emergency fund, church projects, and mutual aid
- **PhotoService.uploadPhoto()** — group photos from meetings, events, and social activities shared in group
- **Cross-module: Kanisa Langu** — jumuiya groups linked to parent church via GroupService; discoverable from church profile
- **Cross-module: Biblia** — weekly Bible study passages open directly in Bible reader; study guides shared via MessageService
- **Cross-module: Sala (Prayer)** — prayer requests shared between jumuiya group and personal prayer journal
- **Cross-module: Fungu la Kumi** — jumuiya contributions tracked alongside personal giving via WalletService
- **Cross-module: my_family/** — family members in same jumuiya connected; family prayer and devotional coordination
