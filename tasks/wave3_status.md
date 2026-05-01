# Wave 3 — Status

## ✅ Mounted this wave

**Partner inbox:** AutoPauseBanner (state-driven), WeeklyBenchmarkChip, PartnerAvailabilityModeSheet (busy/closed mode action).

**Consultation status:** LabReportPdfViewer (PDF attachments are clickable).

**Events:** PostEventBriefPage CTA on events home, RealEventsRail on events partner_product_detail, ContractSignaturePad+full backend signature flow on event_booking_detail.

**Reviews:** PerItemThumbsPicker on rate_partner_page (conditional on ≥2 lineItems param).

**Partner profile:** CannedMessagePicker action, SkillPauseToggle per skill (own-profile only), CrossPersonaDashboardPage action, StudioLayoutEditorPage action.

**Posting:** PhotoGuidelineCard cluster-aware on post_partner_product, ServiceTaxonomyPicker, BufferHorizonEditor, PhotoTierPicker (housing post).

**Bookings:** ScheduleModeToggle (food cart, mafundi req), RecurringBookingToggle (hair_nails), SpotPickerCanvas (class booking + studio editor).

**Service request:** IntakeFormRenderer, PartsPassThroughViewer, LiveEtaMap (Reverb-driven), GeofenceService start hook, partner-position broadcast service.

**Travel/events detail:** DepositBalanceCard, PerStopReviewSheet per itinerary day, MigrationSeasonCalendar on travel home.

**Settings:** SupportChatPage, data-deletion request flow.

**Property:** HousingFilterChipsBar with lens, PropertyTourRequestPage CTA from listing detail.

**Customer order:** AutoCreditService report-a-problem CTA on order detail.

**Engagement workspace:** DisputeMediationPage routed from banner, RetainerConfigPage from appbar, WorkDiaryPanel as Diary tab, TalentMatchBriefPage + QuestionnaireDesignerPage from appbar.

**Detail pages:** CancellationTierDisplay (PartnerProduct.cancellationPolicyTiers), SiteSurveyFeeDialog gate.

**Models extended:** PartnerProduct.{siteSurveyFeeTzs, cancellationPolicyTiers}, EventBooking.{customerSignatureUrl, partnerSignatureUrl, customerSignedAt, partnerSignedAt, paymentPlanInstallments}, Consultation.{clinicIntroHtml, parkingBlob, queuePosition}, TajirikaPartner.{weightedAvgRating, partnerRankingScore}.

**Backend new endpoints:** event-bookings/{id}/sign (signature multipart), service-requests/{id}/partner-position (Reverb broadcast).

## Surfaced backend-only
- #100 weightedAvgRating used as primary rating display on partner_profile (falls back to aggregateRating)
- #9 partnerRankingScore exposed on TajirikaPartner model (UI badge pending listing redesign)
- #65 data deletion → settings tile → backend endpoint

## Still orphan / unmounted (after this wave)
- #2 BookingTotalCalculator (booking sheet refactor needed)
- #7 PhotoQuality utility (passive — applied at upload time elsewhere)
- #8 lead-honesty dashboard surface (data exists; partner dashboard refactor needed)
- #29 BodyShopBidsService (partner-side bidding UI not built)
- #31 MultiStaffCart (group-booking UX not built)
- #35 SkinQuiz (skincare home not yet wired)
- #37 AppointmentWaitlistService (waitlist sheet not built)
- #43 MembershipService (purchase + credits UI not built)
- #44 HrmBleService (live class page not yet wired)
- #45 ClassStreamService (live + on-demand chip on session row not built)
- #47 TriageChatPage (doctor home action not added)
- #56 VisitNotesService partner-side (transcript-paste page not routed)
- #77 CommuteService overlay on listing detail (lens already shipped on search)
- #78 PolygonSearchPage (housing search appbar action not added)
- #90 TalaLicenseBadge (needs persona data join)
- #95 OnTourLivePage (no current-trip card to mount it on)
- #98 EventShowcaseModeration (admin-only per memory rule — skip)
- #16 DailyPayoutBadge (registration flow not edited)
- #19 surfaced as partner_inbox chip ✅

## Truly not done — 27 items
The full `❌` list from the audit remains. Each is a multi-step new feature.
