# Ibada (Worship Music) — Feature Description

## Tanzania Context

"Ibada" means "worship" in Swahili. Worship music is deeply embedded in Tanzanian Christian culture. The primary hymn books are "Nyimbo za Injili" (Gospel Hymns, used by Protestant churches — over 300 hymns) and "Tenzi za Rohoni" (Hymns of the Spirit). Catholic churches use "Tumwabudu Mungu Wetu" and various diocesan-specific collections. Beyond traditional hymns, contemporary gospel music from Tanzania (Bongo gospel) is enormously popular — artists like Rose Muhando, Christina Shusho, and Goodluck Gozbert are household names.

Church choirs are a major institution — most churches have multiple choirs (youth, women, main choir, praise team). Choir members need access to lyrics, chord charts, and rehearsal recordings. Many worship leaders currently search YouTube for songs and lyrics, with no organized tool for worship planning or Swahili hymn access.

## International Reference Apps

1. **Planning Center Music** — Worship team scheduling, setlists, chord charts, transpose
2. **SongSelect (CCLI)** — Lyrics and chord charts for worship songs, licensing management
3. **Hymnary.org** — Digital hymnal with searchable hymn database and history
4. **WorshipOnline** — Tutorial videos for worship musicians learning songs
5. **Multitracks** — Backing tracks, click tracks, and stems for worship teams

## Feature List

1. Hymn book — full digital Nyimbo za Injili, Tenzi za Rohoni, Catholic hymnals
2. Hymn search — search by number, title, first line, topic, or Bible reference
3. Gospel music player — stream/download Tanzanian and East African gospel music
4. Lyrics display — synchronized lyrics for gospel songs, large-text hymn view
5. Chord charts — guitar/keyboard chords for hymns and popular gospel songs
6. Transpose — change key of chord charts for different vocal ranges
7. Create playlists — personal worship playlists, shareable with groups
8. Church choir music — dedicated section for choir arrangements and parts
9. Rehearsal recordings — upload and share practice recordings within choir group
10. Worship setlist builder — plan Sunday service music order with notes
11. Favorite hymns — bookmark frequently used hymns for quick access
12. Song suggestions — AI-recommended songs by theme, scripture, or church season
13. Metronome — built-in metronome/click track for practice
14. Audio quality options — low/medium/high quality streaming for data management
15. Offline downloads — save hymns and songs for offline access
16. Share songs — share to feed, messages, or external platforms

## Key Screens

- **Ibada Home** — featured songs, recently played, Sunday setlist, quick access to hymnals
- **Hymn Book Browser** — book selector (Nyimbo za Injili, Tenzi, etc.), number/search browse
- **Hymn Viewer** — large text display with verse navigation, chord toggle, audio play
- **Gospel Music Library** — browsable/searchable library by artist, album, genre
- **Music Player** — full player with lyrics, queue, repeat, shuffle
- **Playlist Manager** — create, edit, share playlists
- **Chord Chart View** — chords above lyrics, transpose controls, scroll speed for performance
- **Setlist Builder** — drag-and-drop song ordering for worship service planning
- **Choir Section** — choir groups, shared recordings, part assignments

## TAJIRI Integration Points

- **MusicService** — gospel/worship content integrated with TAJIRI's main music player; hymn streaming and offline download; worship playlists
- **LivestreamService.createStream()** — live stream worship sessions, choir performances, and praise nights
- **PostService.createPost(), sharePost()** — share favorite worship songs and hymns to social feed with #Worship hashtag
- **MessageService.sendMessage()** — send songs and hymn links directly in chat conversations
- **CalendarService.createEvent()** — choir rehearsal schedule, worship team assignments, Sunday setlist planning
- **ClipService** — short worship clips for sharing highlights of praise sessions
- **HashtagService** — #Worship, #Gospel, #NyimboZaInjili for discoverable worship content
- **Cross-module: Kanisa Langu** — worship setlists linked to church services via GroupService; choir management within church group
- **Cross-module: Jumuiya** — share worship songs for small group devotional time via MessageService
- **Cross-module: Biblia** — songs tagged with scripture references link back to Bible reader
- **Cross-module: Huduma (Sermons)** — worship songs from same service linked to sermon recording via MusicService
