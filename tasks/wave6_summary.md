# Wave 6 — final close-out (push_to_the_end.md)

Each item touched real product surfaces, not scaffolds. Backend changes deployed via SSH (172.240.241.180 → /var/www/tajiri.zimasystems.com).

## Items closed

### #95 OnTourLivePage CTA on event_booking_detail
- `lib/tajirika/pages/event_booking_detail_page.dart` — added `_liveTripCta` blue card + `_openOnTourLive` opening `OnTourLivePage` with mapped `ItineraryDay` → `TripStop` list when `b.status == EventBookingStatus.dayOf`.

### #3 service_dependencies editor on post_partner_product
- DB: `partner_products.requires_patch_test BOOLEAN DEFAULT FALSE` (already existed).
- Backend: `PartnerProductController` store/update validate + persist `requires_patch_test`. `shapeRow` exposes via `(array)$r`.
- `lib/tajirika/models/partner_product.dart` — `requiresPatchTest` field + JSON parse.
- `lib/tajirika/services/partner_product_service.dart` — new `requiresPatchTest` parameter on createProduct/updateProduct.
- `lib/tajirika/pages/post_partner_product_page.dart` — `_patchTestToggle` SwitchListTile gated on `_supportsPatchTest` (hair_nails / skincare).

### #101 outcome tracking on consultation
- DB: `consultation_outcomes` table (appointment_id, patient_id, doctor_id, follow_up_window_days, status enum, notes, created_at) + indices.
- Backend: `ConsultationController.recordOutcome` POST + `listOutcomes` GET; routes mounted under `/consultations/{id}/outcome[s]`.
- `lib/doctor/models/doctor_models.dart` — `ConsultationOutcome` model.
- `lib/doctor/services/doctor_service.dart` — `recordOutcome` + `listOutcomes`.
- `lib/doctor/pages/consultation_page.dart` — `_outcomeCard` rendered when status is completed; surfaces 14- and 30-day check-in CTAs that open a status sheet (improved/resolved/same/worse + notes).

### #8 lead-honesty dashboard tile on partner profile
- Backend `TajirikaController.stats()` now computes `lead_time_honesty_score` from declared `partner_products.lead_time_hours` vs actual `created_at→completed_at` delta on completed `partner_product_orders`. Returns null until ≥3 samples.
- `lib/tajirika/models/tajirika_models.dart` — `PartnerStats.leadTimeHonestyScore` + `leadTimeHonestySamples`.
- `lib/tajirika/pages/tajirika_home_page.dart` — `_buildLeadHonestyTile` mounted between stats row and tier progress, with progress bar + Excellent/Needs work/Poor band.

### #68 SoW templates picker on propose_engagement
- `lib/tajirika/pages/propose_engagement_page.dart` — loads `SowTemplateService.list()` on init, renders horizontal `ActionChip` row above the contract type field, applying schema → `_titleCtrl`/`_scopeCtrl`/`_milestones` on tap.

### #7 PhotoQuality at upload
- `lib/tajirika/pages/post_partner_product_page.dart` — `_addPhoto` now calls `PhotoQuality.evaluate(file)` before upload and surfaces a soft-block dialog (blur / dim / small / corrupt) with "Use anyway" override.

### #2 BookingTotalCalculator mount
- DB: `partner_products.add_ons JSONB DEFAULT '[]'`.
- Backend: `PartnerProductController` store/update validate + JSON-encode `add_ons`. `shapeRow` decodes for the client.
- `lib/tajirika/models/partner_product.dart` — `addOns: List<Map<String,dynamic>>` + `allowedModes` extension getter.
- `lib/tajirika/widgets/partner_product_booking_sheet.dart` — mounts `BookingTotalCalculator` above the existing total breakdown when add-ons exist; adds `_selectedAddOns` and `_addOnsTzs` getter; `_total` now includes add-on deltas.

### #6 SamplePhotoService rendering on cluster home
- `lib/tajirika/widgets/photo_guideline_card.dart` — converted to StatefulWidget; `_loadSamples` calls `SamplePhotoService.show(cluster)` on init/cluster change; renders a horizontal carousel of reference images below the tip bullets.

### #31 MultiStaffCart group-booking sheet on hair_nails
- `lib/hair_nails/widgets/group_booking_sheet.dart` (new) — modal bottom sheet that captures partner_id, block date/time, duration, and ≥2 named participants (each with service_id + optional staff_id). Calls `MultiStaffCartService.create`.
- `lib/hair_nails/pages/hair_nails_home_page.dart` — second Quick Action row with Group entry that opens the sheet and surfaces the returned cart_id via SnackBar.

### #67 portfolio per-skill tagger UI
- `lib/tajirika/pages/portfolio_manager_page.dart` — `_filterSkill` state + `_filteredItems` + `_availableSkills` + `_skillFilterRow` ChoiceChip row above the grid (rebuilt as SliverGrid). Existing per-item DropdownButtonFormField on upload remains; this is the per-skill *filter*. Items show a category chip (already shipped on `PortfolioItemCard`).

### #49 next_available sort option (F7 #124 "Available today / tomorrow / this week")
- `lib/doctor/services/doctor_service.dart` — `findDoctors` now accepts `sort` param and forwards as `sort=…`.
- `lib/doctor/pages/find_doctor_page.dart` — adds a chip row of mutually-exclusive `available_today` / `available_tomorrow` / `available_this_week` ChoiceChips above the existing online/NHIF/specialty filter row.

## Schema deltas this wave
- `partner_products.requires_patch_test BOOLEAN DEFAULT FALSE` (idempotent ADD COLUMN IF NOT EXISTS)
- `partner_products.add_ons JSONB DEFAULT '[]'`
- `consultation_outcomes` (new table) with FK-shaped columns + 2 indices

## Known unrelated breakage
Pre-existing compile errors in `lib/hair_nails/services/hair_nails_cache_service.dart`, `hair_nails_integrations.dart`, `hair_nails_notification_helper.dart`, `widgets/hair_try_on_viewport.dart`, and `pages/virtual_hair_try_on_page.dart` are not introduced by Wave 6 and were present before this session.
