# Wave 5 Summary — orphan close-out

## Mounted into real flows this wave

- `#16` DailyPayoutBadge → tajirika `registration_page` top of body
- `#28` SupplierCatalog lookup sheet → mafundi `parts_line_editor` (new "Supplier catalog" button alongside Add item)
- `#29` BodyShopBidsSection → `service_request_status_page` (renders when skill is panelBeating/sprayPainting/bodywork)
- `#35` SkinQuiz wizard → `skincare_home_page` quick action
- `#37` AppointmentWaitlist → already wired via existing `class_sessions_page._book` flow (returns 'waitlist' status)
- `#43` Membership purchase + credits → new `class_memberships_page.dart` + settings tile
- `#44` HrmBleService → new `hrm_live_page.dart` routed from `live_classes_page` appbar
- `#45` ClassStreamChip → row chip in `class_sessions_page` per session
- `#56` VisitNotesReviewPage → routed from partner `consultation_detail_page` appbar
- `#77` LensOverlayMap → mounted on `property_listing_detail_page` (live commute isochrones)
- `#78` PolygonSearchPage → routed from housing search appbar
- `#112` skill icon prefix → `partner_inbox_page` row title

## New files
- `lib/fitness/widgets/class_stream_chip.dart`
- `lib/fitness/pages/class_memberships_page.dart`
- `lib/fitness/pages/hrm_live_page.dart`
- `lib/mafundi/widgets/body_shop_bids_section.dart`

## Schema/backend
No new backend this wave — all mounts use existing wave-H/wave-I endpoints.

## Items still requiring deeper work
- `#2` BookingTotalCalculator — booking sheet refactor
- `#6` SamplePhotoService rendering
- `#7` PhotoQuality call at upload
- `#8` lead-honesty dashboard tile
- `#31` MultiStaffCart group-booking sheet
- `#67` portfolio per-skill tagger UI
- `#68` SoW templates picker
- `#90` TalaLicenseBadge (needs persona join)
- `#95` OnTourLivePage routing (needs trip card surface)
- VipSlot UI consumer
- TrainingPlan UI consumer

## Backend-only still unsurfaced
- `#3` service_dependencies editor
- `#9` partner_ranking_score sort/badge in listings
- `#46` NHIF filter chip in find_doctor
- `#49` next_available sort key
- `#67` portfolio per-skill tag UI
- `#101` outcome tracking follow-up card

## flutter analyze
Clean across all touched files.
