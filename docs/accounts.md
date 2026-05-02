UI layout

Scaffold > SafeArea > Stack > CustomScrollView                  
├─ SliverAppBar (expandedHeight: 280, pinned)                                                                                                                                                                                        
│    ├─ actions: cog (Settings), popup menu (Edit/Pay/Calls/Saved/Logout)                                                                                                                                                            
│    └─ flexibleSpace: cover photo + gradient + avatar (100px, 4px white border) + name                                                                                                                                              
└─ SliverToBoxAdapter > profile info card (24px rounded top, white)                                                                                                                                                                  
├─ Stats row (followers/following/subscribers/friends/+viral)                                                                                                                                                                   
├─ Streak badge (conditional)                                                                                                                                                                                                   
├─ Milestone badge (≥100 followers)                                                                                                                                                                                             
├─ Me Quick Links (own profile: Edit/Settings/Pay)                                                                                                                                                                              
├─ CreatorDashboardSection (own profile)                 
├─ ServiceDueDashboard (own profile)                                                                                                                                                                                            
├─ Action buttons (other profile: Follow/Subscribe/Message)                                                                                                                                                                     
├─ Bio / Interests / Info items (location, work, school, joined)                                                                                                                                                                
├─ Mutual friends badge                                                                                                                                                                                                         
└─ Tab grid menu (4-col, categorized via ProfileTabDefaults)  