The tab grid wraps every tab in a private _ProfileTabPage (line 2095) that provides the Scaffold + AppBar + back button.

Adopt-now checklist for any new screen

☐ Scaffold(backgroundColor: #FAFAFA)                                                                                                                                                                                                   
☐ AppBar(elevation: 0, scrolledUnderElevation: 1, centerTitle: false)                                                                                                                                                                  
☐ SafeArea body                                                                                                                                                                                                                        
☐ GestureDetector tap-outside unfocus (if TextField present)                                                                                                                                                                           
☐ ScrollViewKeyboardDismissBehavior.onDrag on long forms                                                                                                                                                                               
☐ Loading: CircularProgressIndicator(strokeWidth: 2, color: #1A1A1A)                                                                                                                                                                   
☐ Empty: icon (grey.shade300) + title (grey.shade500) + subtitle (grey.shade400) + CTA                                                                                                                                                 
☐ Error: icon + sanitized message + OutlinedButton(Retry, primary outline, 12-radius)                                                                                                                                                  
☐ RefreshIndicator(color: #1A1A1A) on lists                                                                                                                                                                                            
☐ FilledButton(#1A1A1A) for primary actions; OutlinedButton(#1A1A1A) for secondary                                                                                                                                                     
☐ Pills: circular(20), 14×8 padding, dark bg, white text, 12px w600                                                                                                                                                                    
☐ Cards: BorderRadius.circular(16), shadow (black 4% alpha, blur 10), no heavy border                                                                                                                                                  
☐ Dynamic text: maxLines + overflow: ellipsis                                                                                                                                                                                          
☐ Bilingual: isSwahili ? sw : en                                                                                                                                                                                                       
☐ Tooltips on every IconButton; MergeSemantics on compound widgets                                                                                                                                                                     
☐ TextField: keyboardType + autofillHints + textInputAction + onSubmitted                                                                                                                                                              
☐ Form: validate on first blur, not while typing; inline errorText                                                                                                                                                                     
☐ Save flow: invalidate → pop(true) on success; inline _formError on failure                                                                                                                                                           
☐ Confirm destructive in AlertDialog with red TextButton                                                                                                                                                                               
☐ Dispose every controller / focus node / timer / subscription                                                                                                                                                                         
☐ Mounted guard after every await                                                                                                                                                                                                      
☐ flutter analyze → zero new errors 
performance fixes


1. Disk cache for user's posts — so cold-start renders cached posts instantly, then syncs in background (stale-while-revalidate)
2. In-memory persistence across page visits — so re-opening the My Posts page reuses its loaded state instead of starting from scratch


lib/screens/profile/creator_earnings_dashboard_screen.dart

lib/screens/profile/earnings_provenance_screen.dart

lib/screens/profile/creator_tier_screen.dart

lib/screens/profile/creator_earnings_dashboard_screen.dart

lib/screens/profile/earnings_provenance_screen.dart


                                                                                                                                                                                                                
lib/main.dart                                                                                                                                                                                 
30 +import 'screens/profile/creator_earnings_dashboard_screen.dart';                                                                                                                                                        
31 +import 'screens/profile/earnings_provenance_screen.dart';                                                                                                                                                                      
32 +import 'screens/profile/creator_tier_screen.dart';  



Backend (/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-BACKEND/):

┌───────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   
│     Layer     │                                                                                                      Files                                                                                                       │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Migrations    │ 2026_05_03_000001 through _000013 — extends creator_earnings_rates; creates earning_events, creator_tiers, creators_fund_periods, creators_fund_points, earnings_reserve_ledger, post_share_attributions,        │
│ (13)          │ earnings_disputes; adds origin_post_id columns to user_follows + subscriptions, disbursed_at to earning_events, is_discovery_mode + discovery_mode_until to posts                                                │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Seeders (2)   │ CreatorsFundCoaSeeder (16 COA accounts), CreatorsFundInitialPeriodSeeder                                                                                                                                         │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Models (4)    │ EarningEvent, CreatorTier, CreatorsFundPeriod, CreatorsFundPoint                                                                                                                                                 │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Services (7)  │ EarningsEngine, AbuseGuard, MultiplierEngine, CreatorEarningsRateRegistry, OriginalityDetector, CreatorTierService, PayoutService                                                                                │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ DTO + Traits  │ EarningEventDto, FiresEarningEvents, ResolvesUserProfileFromSanctumUser                                                                                                                                          │
│ (3)           │                                                                                                                                                                                                                  │   
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Jobs (6)      │ CreatorsFundPeriodSettlementJob (weekly), SettlementSweepJob (daily, with WHT), MwanzoExpiryJob, TierReviewJob, PayoutDisbursementJob, TRARemittanceJob                                                          │   
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Controllers   │ PostEarningsController (rewritten — read from event ledger; events endpoint; Discovery Mode), CreatorEarningsController (dashboard, events, tax, disputes), CreatorRateCardController                            │
│ (3)           │                                                                                                                                                                                                                  │   
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Configs (3)   │ earnings.php, earnings_multipliers.php, creator_tiers.php                                                                                                                                                        │   
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Routes        │ New routes for /creators/rate-card, /users/me/earnings/*, /posts/{id}/earnings/events, /posts/{id}/discovery-mode                                                                                                │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Tests (3)     │ EarningsEngineTest (smoke), MultiplierEngineTest (7 unit tests), AbuseGuardTest (2 unit tests)                                                                                                                   │
├───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Docs (2)      │ CREATORS_FUND_HOOK_WIRING.md (Tasks 26-40 patches for 7 controllers), CREATORS_FUND_DEPLOY.md (Tasks 77, 83, 84)                                                                                                 │
└───────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   









┌─────┬──────────────────────────┬─────────────────────┬───────────────────────────────────────────────────────┐                                                                                                                       
│  #  │          Screen          │    Route / Entry    │                         Path                          │                                                                                                                       
├─────┼────────────────────────────────┼─────────────────────┼───────────────────────────────────────────────────────┤                                                                                                                 
│ 1   │ IncomeSourcesView              │ embedded            │ Profile → "Creator" tab                               │                                                                                                                 
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤                                                                                                                
│ 2   │ IncomeSourcesScreen            │ /creator             │ FCM deep-link, navigation                             │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 3   │ IncomeSourceDetailScreen       │ /creator/source/:id  │ IncomeSourcesView → tap source row                    │
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤                                                                                                                
│ 4   │ IncomeActivityScreen           │ /creator/activity    │ IncomeSourcesView → WalletHeroCard "Activity"         │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤                                                                                                                
│ 5   │ CreatorStatsScreen             │ (push)               │ NEW: IncomeSourcesView → "Stats" pill + AppBar action │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 6   │ CreatorDashboardSection        │ embedded             │ Inside CreatorStatsScreen                             │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 7   │ WeeklyReportScreen             │ /weekly-report/:id   │ dashboard_section button + FCM push                   │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 8   │ CreatorEarningsDashboardScreen │ /creator-earnings    │ NEW: IncomeSourcesView → "Fund" pill                  │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 9   │ EarningsProvenanceScreen       │ /earnings-provenance │ CreatorEarningsDashboardScreen → "View all events"    │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 10  │ CreatorTierScreen              │ /creator-tier        │ CreatorEarningsDashboardScreen → "Your tier"          │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 11  │ SponsoredPostsScreen           │ /sponsored-posts     │ NEW: IncomeSourcesView → "Sponsor" pill               │                                                                                                                
├─────┼────────────────────────────────┼──────────────────────┼───────────────────────────────────────────────────────┤
│ 12  │ PostEarningsScreen             │ (push)               │ post_detail_screen earnings strip                     │                                                                                                                
└─────┴────────────────────────────────┴──────────────────────┴───────────────────────────────────────────────────────┘ 


docs/post_earnings_tajiri_strategy.md 