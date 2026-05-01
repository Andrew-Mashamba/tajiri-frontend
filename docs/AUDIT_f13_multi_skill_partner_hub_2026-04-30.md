# F13 — Multi-Skill Partner Hub Audit

**Date:** 2026-04-30  
**Auditor:** Kimi Code CLI  
**Scope:** #42 Persona-level public profiles + #43 AMC packages persona-specific

---

## ✅ Delivered

### Backend

| File | Change | Status |
|------|--------|--------|
| `app/Http/Controllers/Api/TajirikaController.php` | Added `publicBySlug(string $slug)` method | ✅ |
| `routes/api.php` | Added `GET /tajirika/partners/public/{slug}` | ✅ |

**`publicBySlug` logic:**
1. First queries `tajirika_partners.public_slug` → returns partner-level profile with `is_persona_profile: false`
2. Falls back to `partner_skill_personas.public_slug` joined with `tajirika_partners` + `users` → returns partner-shaped response with persona overlay fields and `is_persona_profile: true`
3. Returns 404 if neither slug exists

**Persona fields returned:**
- `persona_skill_category`
- `persona_pricing_band_low_tzs` / `high_tzs`
- `persona_tag_preset`
- `persona_auto_reply_text`
- `persona_tala_license_number` + `persona_tala_verified`
- `persona_credentials_url`
- `persona_status`

### Frontend

| File | Change | Status |
|------|--------|--------|
| `lib/tajirika/models/tajirika_models.dart` | Extended `TajirikaPartner` with 10 persona fields | ✅ |
| `lib/tajirika/pages/public_partner_profile_page.dart` | Persona view + AMC section + `SharePlus` fix | ✅ |

**Persona-specific UI additions:**
- `_buildPersonaInfoSection()` — pricing band, TALA license badge, credentials indicator, auto-reply text box, tag preset chips
- `_buildAmcSection()` — fetches AMC products via `PartnerProductService.listProducts(partnerId, skillCategory, kind: 'amc')` and renders cards with price, visit count, validity months
- `_buildSkillsSection()` — label changes to "Specializes in" for persona profiles
- `_loadAmc()` — called automatically when `_partner.isPersonaProfile == true`

**AMC rendering:**
- Shows product title, description, price badge (green), visit count / validity
- Hidden when no AMC products exist for the skill

### Verification

- `flutter analyze` on modified files — **No issues found**
- `php -l` on `TajirikaController.php` — **syntax clean**
- `php artisan route:list | grep partners/public` — **route registered**

---

## 🟡 Partial / Deferred

| Item | Reason | Next Step |
|------|--------|-----------|
| Web SSR route (`routes/web.php`) | Shell escaping issues corrupting the PHP file on remote edit; needs careful manual edit or deployment script | Fix via `sed` with escaped backslashes or deploy via SCP |
| `partner_profile.blade.php` persona view | Blade view currently only renders partner-level data; needs conditional persona rendering | Update Blade template to handle `$persona` variable |

---

## 🔴 Not in Scope

| Item | Reason |
|------|--------|
| Persona-specific portfolio filtering | Portfolio photos are partner-level (`portfolio_photos` on `tajirika_partners`); per-skill portfolio filtering would require new `portfolio_photos.skill_category` column |
| Persona-specific reviews | Reviews are partner-level in `partner_reviews`; per-skill review scoping would require `partner_reviews.skill_category` column |
| Persona-specific public slug uniqueness enforcement | Assumed handled by unique index on `partner_skill_personas.public_slug` already applied in migrations |

---

## Test Checklist

- [ ] Create a partner with `public_slug = "test-partner"` → visit `/p/test-partner` → should show partner-level profile
- [ ] Create a persona with `public_slug = "test-baker"` for partner → visit `/p/test-baker` → should show persona-level profile with single skill
- [ ] Create AMC product with `kind = amc`, `skill_category = baking` for partner → persona profile should show AMC card
- [ ] Verify `any_professional_mode` appointments auto-assign to partners with matching skill (F12 #40 regression)

---

## Files Modified

```
Backend:
  app/Http/Controllers/Api/TajirikaController.php
  routes/api.php

Frontend:
  lib/tajirika/models/tajirika_models.dart
  lib/tajirika/pages/public_partner_profile_page.dart

Docs:
  docs/plans/remaining_after_wave6.md
  docs/AUDIT_f13_multi_skill_partner_hub_2026-04-30.md (this file)
```
