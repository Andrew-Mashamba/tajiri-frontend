# TAJIRI — Partnership & Auth API Follow-up List

> APIs and services requiring partnership agreements, merchant registration, or institutional access.
> Generated from API directory research, 2026-04-08.
> **Action required:** Business development team to follow up on each item.

---

## Priority 1: CRITICAL — Core Platform Functionality

These APIs are needed for core features that many TAJIRI modules depend on. Without them, multiple modules cannot function.

| # | Service/API | Provider | What It Unlocks | Contact/Apply | Type | Est. Cost | Action Required |
|---|-------------|----------|----------------|---------------|------|-----------|-----------------|
| 1 | M-Pesa Open API | Vodacom Tanzania | Mobile money payments across ALL modules (tajirika, ambulance, car_insurance, buy_car, fuel_delivery, service_garage, sell_car, rent_car, spare_parts, fungu_la_kumi, fee_status) | https://openapiportal.m-pesa.com + register at business.m-pesa.com | Merchant Registration | Transaction fees (no monthly fee) | Register business on M-Pesa Open API portal. Requires TZ business registration + TIN. Sandbox available for dev. |
| 2 | AzamPay API | AzamPay (Bakhresa Group) | Payment gateway for mobile money + cards. Used by tanesco, dawasco, and all payment modules. Has Flutter/Dart SDK on pub.dev. | https://developers.azampay.co.tz/ | Merchant Registration | Transaction fees | Register as merchant on AzamPay developer portal. Requires business documentation. |
| 3 | ClickPesa API | ClickPesa | Unified payment aggregation (M-Pesa, Tigo Pesa, Airtel Money, HaloPesa). Covers tanesco, dawasco, ofisi_mtaa, GePG integration. Bulk payouts for tajirika workers. | https://docs.clickpesa.com/ — contact sales | Merchant Registration | Transaction fees + custom pricing | Apply for merchant account. Contact ClickPesa sales team for API access and bulk payout terms. |
| 4 | GePG (Government e-Payment Gateway) | Ministry of Finance, Tanzania | Government service fee payments across brela, rita, ofisi_mtaa, nhif, nssf, land_office. Required for ANY government fee collection/payment. | https://www.gepg.go.tz/documents | Government MOU / Institutional Access | Free (institutional) | Formal application to Ministry of Finance for institutional integration. Requires SHA1withRSA digital signatures. Government partnership agreement needed. |
| 5 | Selcom Utility Payments API | Selcom | TANESCO LUKU token purchase, DAWASCO bill payments, TRA payments. Largest LUKU vending agent in TZ. | https://developers.selcommobile.com/ — contact info@selcom.net | Merchant Registration | Commission-based | Email info@selcom.net for API access. Requires merchant registration and business documentation. |
| 6 | NIDA Verification API | NIDA (National Identification Authority) | National ID verification for KYC across ALL modules requiring identity verification (tajirika, nida module, loans, insurance) | https://services.nida.go.tz/ | Government MOU | Unknown (institutional) | Restricted to authorized institutions (banks, telecoms, government). Apply formally to NIDA for API access. Alternative: use Smile ID as intermediary. |
| 7 | Smile ID | Smile Identity | Pan-African ID verification (covers Tanzania NIN, driver's license, passport). Used by nida, driving_licence, passport, tajirika modules. Intermediary for NIDA access. | https://docs.usesmileid.com — email partnerships | Partnership / Merchant Registration | Pay-per-verification (contact sales) | Email Smile ID partnerships team for pricing and merchant account setup. Covers 8,500+ ID types across 54 African countries. |

---

## Priority 2: HIGH — Major Module Enablers

These APIs unlock entire module categories or significant feature sets.

| # | Service/API | Provider | What It Unlocks | Contact/Apply | Type | Est. Cost | Action Required |
|---|-------------|----------|----------------|---------------|------|-----------|-----------------|
| 8 | Rescue.co / Flare | Rescue.co (Trek Medics) | Ambulance dispatch, GPS fleet tracking, clinical triage for ambulance module. 800+ ambulance providers already onboarded in TZ/KE/UG. | https://www.rescue.co/ — contact for API partnership | Partnership / B2B Contract | Custom pricing | Contact Rescue.co for API partnership. They operate in Tanzania with existing ambulance network. Requires B2B agreement. |
| 9 | BimaSokoni | BimaSokoni | Insurance comparison marketplace for car_insurance module. First TZ insurance aggregator — compare quotes from multiple insurers. | https://www.bimasokoni.co.tz/ — contact for API | Partnership | Custom pricing | Contact BimaSokoni for API access and partnership agreement. No public API documented. |
| 10 | AfricaBima API | AfricaBima | Insurance quotation, claims, policy management for car_insurance. Integrated with IPRS, NTSA, M-Pesa. | http://africabima.com/api.html | Partnership / B2B Contract | Custom pricing | Apply for B2B partnership. Covers quotations, claims processing, payments. |
| 11 | BE FORWARD | BE FORWARD Co., Ltd. | Used car listings from Japan for buy_car module. Dominant in TZ market. No public API exists. | https://www.beforward.jp/ — contact B2B sales | Partnership / B2B Contract | Custom pricing | No documented developer API. Contact BE FORWARD B2B team for partnership agreement or data feed access. May need to negotiate scraping permission. |
| 12 | SBT Japan | SBT Co., Ltd. | Used car listings from Japan for buy_car module. 13,000+ vehicles/month to 200+ countries. | https://www.sbtjapan.com/ — contact B2B | Partnership / B2B Contract | Custom pricing | Contact SBT Japan for B2B integration partnership. No public API — requires negotiated access. |
| 13 | TRA VFD API | Tanzania Revenue Authority | Virtual Fiscal Device integration, Z-reports, receipt verification for tra module. XML-based API. | https://tra-docs.netlify.app/guide/api/ | Government Registration | Free (for registered taxpayers) | Register with TRA using business TIN. One-time registration process. API uses XML (not REST/JSON). Token-based auth. |
| 14 | NHIF Verification API | NHIF (National Health Insurance Fund) | Member card status, verification code validity, payment status for nhif module. | https://verification.nhif.or.tz/ | Government MOU / Institutional Access | Unknown (institutional) | Formal partnership application to NHIF. API available only for institutional partners (universities, hospitals, healthcare providers). |
| 15 | Flutterwave API | Flutterwave | African payment processing (M-Pesa, cards, bank) for fungu_la_kumi (church giving) and fee_status (school fees). Supports TZS. | https://flutterwave.com/docs — merchant signup | Merchant Registration | ~1.4% local, 3.8% international | Register as merchant on Flutterwave dashboard. Requires business documentation and KYC verification. |
| 16 | ILMIS (Land Registry) | Ministry of Lands (MLHHSD) | Land title verification, cadastral management for land_office module. Contains 6.5M digitized documents, 80+ transaction types. | https://ilmis.lands.go.tz/ | Government MOU / Institutional Access | Unknown | Institutional access required. Apply formally to Ministry of Lands. Built on PostgreSQL/GeoServer, integrated with NIDA and GePG. |
| 17 | Booking.com Cars API | Booking Holdings | Car rental inventory (45K locations, 200+ suppliers, 150 countries) for rent_car module. | https://developers.booking.com/demand/docs/cars/overview | Partnership / Affiliate | Revenue share / affiliate commission | Apply for Booking.com affiliate partnership. Requires approval process. Real-time availability + pricing. |
| 18 | TecDoc Catalog API | TecAlliance | Industry-standard OEM + aftermarket parts catalog for spare_parts and service_garage modules. 1,000+ subscribers globally. | https://www.tecalliance.net/tecdoc-catalogue/ — contact sales | Enterprise License | $3K-50K+ integration fee | Contact TecAlliance sales for enterprise license. High cost but industry standard. 14 languages supported. |
| 19 | BrighterMonday TZ | BrighterMonday (Ringier One Africa Media) | Tanzania's #1 job board for career module. 276+ job offers. No public API. | https://www.brightermonday.co.tz/ — contact partnerships | Partnership / B2B Contract | Custom pricing | Contact Ringier One Africa Media / BrighterMonday for API partnership or data feed agreement. No public API exists. |
| 20 | Indeed Job Sync API | Indeed | Job search, salary data for career module. GraphQL API. | Apply via Indeed partner program | Partnership | Free for ATS partners | Apply for Indeed partner program. 6-week integration timeline. Requires formal partnership agreement. |

---

## Priority 3: MEDIUM — Feature Enhancement

These APIs enhance existing features or add significant value to specific modules.

| # | Service/API | Provider | What It Unlocks | Contact/Apply | Type | Est. Cost | Action Required |
|---|-------------|----------|----------------|---------------|------|-----------|-----------------|
| 21 | uqudo | uqudo | Tanzania KYC/AML, ID document verification for nida, tajirika modules. Web SDK, Mobile SDK (8MB), REST API. | https://docs.uqudo.com/ — contact for pricing | Partnership | Custom pricing | Contact uqudo sales for pricing and integration terms. Supports Tanzania ID documents. |
| 22 | Verified.Africa | Verified Africa | Identity verification, KYC for tajirika gig workers. Digital identity verification across Africa. | https://docs.verified.africa/ | Paid Subscription | Pay-per-verification | Apply for API access on Verified.Africa portal. Per-verification pricing. |
| 23 | CCLI SongSelect API | CCLI | Worship song lyrics, chord charts, sheet music for ibada (worship music) module. 100K+ songs. | Contact CCLI partnerships | Partnership / NDA Required | Paid (partnership required) | Requires CCLI partnership agreement. NDA may be required. Contact CCLI business development. |
| 24 | Tithe.ly API | Tithe.ly | Church giving, transactions, payment categories for fungu_la_kumi module. | Email support@tithe.ly for API access | Partnership / Paid Subscription | Church subscription required | Email support@tithe.ly requesting API access. Requires church to have active Tithe.ly subscription. Docs at tithelydev.com/api. |
| 25 | LinkedIn Job Posting API | LinkedIn/Microsoft | Job postings and applications for career module. | Apply via LinkedIn Talent Solutions | Enterprise License | Paid (Talent Solutions license) | Requires LinkedIn Talent Solutions subscription. Limited to approved partners. Contact LinkedIn sales. |
| 26 | JSTOR XML Gateway | JSTOR | Academic journal access for library module. Metasearch API. | Apply for JSTOR Metasearch License | Enterprise License | Institutional license required | Requires JSTOR Metasearch License Agreement. Not available for individual use. Apply through institutional channel. |
| 27 | Turnitin API | Turnitin | Plagiarism detection for assignments module. | Contact Turnitin institutional sales | Enterprise License | Paid (institutional license) | Apply for institutional integration license. Requires formal agreement with Turnitin. |
| 28 | FleetON API | FleetON | Fleet management, booking engine for rent_car module. Purpose-built for car rental businesses. | https://fleetonapp.com/products/api-integration/ | B2B Subscription | Monthly subscription | Contact FleetON for B2B subscription and API integration terms. |
| 29 | Easy Track Africa | Easy Track | GPS fleet tracking for fuel_delivery vehicles. LATRA-approved VTS provider in Tanzania. | https://easytrackafrica.com/ — contact sales | B2B Subscription | Monthly subscription | Contact Easy Track Africa for B2B subscription. LATRA-approved, important for regulatory compliance. |
| 30 | Smartcar API | Smartcar | Connected car data (fuel, odometer, location, lock/unlock) for my_cars and rent_car fleet management. 40+ automakers, 177M cars. | https://smartcar.com/docs/api/ | Paid Subscription | Freemium (tiered plans) | Register on Smartcar developer portal. Free tier available. OAuth 2.0 vehicle authorization model. |
| 31 | Emergency Dispatch Africa | Emergency Dispatch Africa | CAD (Computer-Aided Dispatch) for ambulance module. GPS tracking and priority-based routing. | https://www.emergencydispatchafrica.com/ | B2B Contract | Custom pricing | Contact for B2B partnership. Dispatch software with GPS tracking. |
| 32 | Qover API | Qover | White-label embedded insurance (motor, travel, liability) for car_insurance module. | https://www.qover.com/api | Partnership / Per-Policy | Per-policy fees | Contact Qover for embedded insurance partnership. RESTful API for quote, bind, claim. |
| 33 | Bolttech API | Bolttech | Embedded insurance distribution for car_insurance module. Insurance exchange connecting 200+ insurers. | https://bolttech.io/sales/embedded-insurance-api/ | Partnership / Per-Policy | Per-policy fees | Contact Bolttech sales for integration partnership. Motor insurance supported. |
| 34 | DPO Pay API | DPO Group (Network International) | Card + mobile money payments across Africa. Operates in 20+ African countries. | https://docs.dpopay.com/ — merchant registration | Merchant Registration | Transaction fees | Register as merchant on DPO Pay. Requires business documentation. Supports multiple African markets. |
| 35 | Beem Africa Payments API | Beem | Mobile money collection, utility payments for tanesco, dawasco. 22 country coverage. | https://beem.africa/mobile-payments-api/ | Merchant Registration | Tier-based pricing | Register on Beem Africa platform. Requires merchant account setup. |
| 36 | Laws.Africa Knowledge Base API (Commercial) | Laws.Africa | Legal data retrieval for legal_gpt module (commercial use). RAG/LLM agent workflows. | https://developers.laws.africa/ai-api/knowledge-bases | Paid Subscription (commercial use) | Free for non-commercial; paid for commercial | Contact Laws.Africa for commercial license terms. Free for non-commercial, but TAJIRI is commercial. |
| 37 | Waze for Cities | Waze/Google | Traffic data sharing for traffic module. | https://wazeforcities.com | Government Partnership | Free (for cities/government) | Requires government partnership. Apply as municipality or partner with local government. |
| 38 | SaferWatch API | SaferWatch | Panic alerts, incident reporting for neighbourhood_watch module. | https://saferwatchapp.com — contact enterprise sales | Enterprise License | Paid (enterprise) | Contact SaferWatch for enterprise API access. Used by communities and schools. |
| 39 | RapidSOS 911 API | RapidSOS | Emergency services integration for police module. | https://rapidsos.com/api — enterprise contact | Enterprise License | Paid (enterprise) | Contact RapidSOS for enterprise partnership. Currently US-focused — verify East Africa coverage. |

---

## Priority 4: LOW — Nice to Have / Future Phases

These APIs are for polish, future features, or have limited Tanzania applicability.

| # | Service/API | Provider | What It Unlocks | Contact/Apply | Type | Est. Cost | Action Required |
|---|-------------|----------|----------------|---------------|------|-----------|-----------------|
| 40 | Passport Index API | Arton Capital | Visa requirements, passport rankings for passport module. | https://discover.passportindex.org/api-request/ | Partnership | Contact for pricing | Submit API request form. Government agencies prioritized over commercial apps. |
| 41 | Checkr API | Checkr | Background checks for tajirika gig workers. International criminal search, 196 countries. | https://checkr.com/our-technology/background-check-api | Paid Subscription | Per-check pricing | Apply for API access on Checkr portal. Primarily US-focused but covers 196 countries. |
| 42 | Authenticate | Authenticate.com | ID authentication, background verification for tajirika. 7,500+ ID types, facial recognition + liveness detection. | https://authenticate.com/ | Paid Subscription | Per-check pricing | Apply on Authenticate.com portal. Global coverage but verify Tanzania support. |
| 43 | GlobalPetrolPrices API | GlobalPetrolPrices.com | Fuel prices for 135 countries for fuel_delivery module. | https://www.globalpetrolprices.com/data_access.php | Paid Subscription | Monthly subscription (2-week free trial) | Subscribe on GlobalPetrolPrices.com. XML data feed. Free trial available. |
| 44 | Schoology API | PowerSchool | K-12 course management for my_class module. | Contact PowerSchool sales | Enterprise License | Paid (institutional license) | Requires institutional license from PowerSchool. Primarily US K-12 market. |
| 45 | Google Classroom API | Google | LMS integration for my_class, assignments modules. | Requires Google Workspace admin approval | Enterprise / Institutional | Free (with Google Workspace for Education) | Requires Google Workspace for Education admin to approve API access. Need institutional relationship. |
| 46 | Canvas LMS REST API | Instructure | Full LMS for my_class, assignments modules. | Requires Canvas instance | Enterprise License | Free with Canvas instance; instance is paid | Need institutional Canvas LMS subscription. Contact Instructure for partnership. |
| 47 | Moodle Web Services API | Moodle | Course management for my_class, assignments. | Self-hosted — requires admin setup | Enterprise / Self-hosted | Free (self-hosted) | Need to host Moodle instance or partner with institution that has one. Admin must enable web services. |
| 48 | Cronofy Calendar API | Cronofy | Unified calendar access for timetable module. | https://www.cronofy.com — paid plans from $49/mo | Paid Subscription | Free tier: 5 users; $49/mo+ | Register on Cronofy. Free tier very limited (5 users). |
| 49 | Stream Chat API | Stream | Scalable chat with moderation for class_chat module. | https://getstream.io — contact sales | Paid Subscription | Free: 10K MAU; $399/mo+ | Register on Stream dashboard. Free tier for MVP. Contact sales for education pricing. |
| 50 | Halal Terminal API | Halal Terminal | Shariah screening, zakat calculation for zaka module. 58+ endpoints. | https://halalterminal.com — freemium signup | Paid Subscription | Freemium (paid for full access) | Register on Halal Terminal. Free tier available. 5 screening methodologies. |
| 51 | Zoya Shariah Compliance API | Zoya Finance | Stock/ETF screening, zakat calculation for zaka module. | https://zoya.finance/api — subscription | Paid Subscription | Monthly subscription | Subscribe on Zoya Finance platform. Per-company zakat calculation. |
| 52 | CityProtect | CityProtect (Motorola) | Public safety data for neighbourhood_watch module. | https://cityprotect.com — partner with law enforcement | Partnership (Law Enforcement) | Free (public portal) | Requires partnership with local law enforcement to access full API. Public portal available. |

---

## Government Systems — No Public API (Web Portal Only)

These Tanzania government systems have NO REST API and require either formal government partnerships, web scraping, or manual data entry workflows.

| # | System | Authority | Modules Affected | Portal URL | Action Required |
|---|--------|-----------|-----------------|------------|-----------------|
| G1 | TRA Motor Vehicle Registration (CMVRS) | Tanzania Revenue Authority | my_cars, buy_car, sell_car | https://www.tra.go.tz | Visit TRA office to discuss API partnership. Currently web portal + TRA mobile app only. |
| G2 | TRA Import Duty Calculator | Tanzania Revenue Authority | buy_car | https://www.tra.go.tz/index.php/90-calculators-tools | Web tool only. Build custom calculator using TRA duty schedules, or scrape web tool. |
| G3 | TRA E-Filing Portal | Tanzania Revenue Authority | tra | https://efiling.tra.go.tz | Web portal only with SMS verification. No programmatic access. |
| G4 | TRA CDLS (Driving Licence) | Tanzania Revenue Authority | driving_licence | Part of IDRAS initiative | Government portal only. Contact TRA for potential API partnership. |
| G5 | LATRA VTS | Land Transport Regulatory Authority | my_cars, rent_car | https://vts.latra.go.tz | Contact LATRA for GPS tracking integration. Required for commercial vehicles. |
| G6 | LATRA RRIMS | Land Transport Regulatory Authority | transport | https://rrims.latra.go.tz | Government portal. Contact LATRA for data access. |
| G7 | TIRA Verification | Tanzania Insurance Regulatory Authority | car_insurance | https://www.tira.go.tz | Web-based policy verification only. Contact TIRA for partnership. |
| G8 | EWURA Fuel Prices | EWURA | fuel_delivery | https://www.ewura.go.tz/publications/petroleum-price | Monthly PDF publications for 190+ locations. No API. Build PDF scraper or contact EWURA for data feed. |
| G9 | Tanzania Health Facility Registry | Ministry of Health | ambulance, doctor | https://hfrs.moh.go.tz | Master Facility List with GPS. No REST API. Contact Ministry of Health or scrape web portal. |
| G10 | Tanzania Police RTOC | Tanzania Police Force | traffic, police | https://tms.tpf.go.tz | Traffic management system. Contact TPF for potential integration. |
| G11 | eRITA (Civil Registration) | RITA | rita | https://erita.rita.go.tz | Birth/death/marriage certificates. Web portal only. Formal partnership agreement needed with RITA. |
| G12 | BRELA ORS | BRELA | brela | https://ors.brela.go.tz | Business registration. Web portal only (Java/PostgreSQL/GeoServer). Public name search at ors.brela.go.tz/orsreg/searchbusinesspublic. Formal agreement with BRELA needed for integration. |
| G13 | NSSF Portal | NSSF | nssf | https://portal.nssf.go.tz | Contribution tracking, claims. Portal + mobile app only. No developer API. Contact NSSF for partnership. |
| G14 | HESLB OLAS Portal | HESLB | fee_status | https://olas.heslb.go.tz | Student loan status/allocation. No API. Contact HESLB for data partnership. Allocated TZS 426.5B to 135,240 students in 2025/26. |
| G15 | NECTA Results | NECTA | results, past_papers | https://necta.go.tz / matokeo.necta.go.tz | No official API. Unofficial Python scraper exists (nectaapi on PyPI). Contact NECTA for official data partnership. |
| G16 | TCU Admissions | TCU | results, career | https://tcu.go.tz | University admission data. PDF guidebooks only. Contact TCU for partnership. |
| G17 | NACTE/NACTVET | NACTE | results | https://nacte.go.tz | Technical college results/accreditation. No API. Contact NACTE. |
| G18 | Ajira Portal | PSRS | career | https://ajira.go.tz | Government/public sector jobs. No API. Contact Public Service Recruitment Secretariat for data feed. |
| G19 | DAWASCO/DAWASA | DAWASA | dawasco | https://mportal.ega.go.tz/application/4 | Water utility. No developer API. Use payment aggregators (Selcom, AzamPay) for bill payments. |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Priority 1 (Critical) | 7 |
| Priority 2 (High) | 13 |
| Priority 3 (Medium) | 19 |
| Priority 4 (Low) | 13 |
| Government (No API) | 19 |
| **Total items** | **71** |

### By Type

| Type | Count |
|------|-------|
| Partnership / B2B Contract | 14 |
| Merchant Registration | 8 |
| Government MOU / Institutional Access | 8 |
| Enterprise License | 9 |
| Paid Subscription (contact required) | 13 |
| Government Portal (no API) | 19 |

### Recommended Approach Order

1. **Immediate (Week 1-2):** Register for M-Pesa, AzamPay, Selcom merchant accounts (#1, #2, #5) -- these unlock payments across all modules
2. **Short-term (Month 1):** Apply for Smile ID (#7), ClickPesa (#3), Flutterwave (#15), DPO Pay (#34) merchant accounts
3. **Medium-term (Month 2-3):** Initiate government partnerships -- GePG (#4), TRA VFD (#13), NIDA (#6), NHIF (#14)
4. **Long-term (Month 3-6):** Negotiate B2B partnerships -- Rescue.co (#8), BE FORWARD (#11), SBT Japan (#12), BimaSokoni (#9), BrighterMonday (#19)
5. **Ongoing:** Government portal integrations (G1-G19) -- these require persistent relationship building with Tanzania government agencies

---

*This document should be reviewed quarterly and updated as partnerships are established or new APIs become available.*
