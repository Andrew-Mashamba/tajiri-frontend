# TAJIRI Government & Legal Module API Directory

> Available APIs for Government & Legal modules. Researched 2026-04-07.
> Priority: Tanzania-specific > Africa-wide > Global

---

## 1. barozi_wangu (Councillor Data, Ward Boundaries, Elections)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| HDX Administrative Boundaries | UN OCHA (Humanitarian Data Exchange) | Tanzania ward/district/region boundary shapefiles (levels 0-3) | Free | https://data.humdata.org/dataset/cod-ab-tza — GeoJSON, Shapefile, KML formats |
| OpenStreetMap / Nominatim | OpenStreetMap Foundation | Geocoding, reverse geocoding, ward-level mapping for Tanzania | Free (1 req/sec limit on public instance) | https://nominatim.org/ — Self-hostable, full Tanzania coverage via WikiProject Tanzania |
| Tanzania Open Data Portal | Government of Tanzania / eGA | Government statistics, ward-level population data | Free | http://opendata.go.tz/ — CKAN-based, API access available |
| African Elections Database | Community | Historical election results for African countries | Free | https://africanelections.tripod.com/ — Static data, no REST API |
| Tanzania Data Portal | Open Data for Africa / AfDB | Census, demographic, economic indicators by region | Free | https://tanzania.opendataforafrica.org/ — API access via Open Data for Africa platform |
| World Bank Open Data API | World Bank | Development indicators for Tanzania (governance, demographics) | Free, no auth required | https://datahelpdesk.worldbank.org/knowledgebase/articles/889392 — REST API, ~16,000 indicators |

**Note:** No dedicated Tanzania election/councillor API exists publicly. Ward boundary data is best sourced from HDX shapefiles. Councillor data would need to be scraped from NEC (National Electoral Commission) or maintained locally.

---

## 2. ofisi_mtaa (Local Government Services)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Tanzania Open Data Portal | Government of Tanzania / eGA | Open government data across sectors (health, water, education) | Free | http://opendata.go.tz/ — CKAN API for programmatic access |
| GePG (Government e-Payment Gateway) | Ministry of Finance, Tanzania | Government service fee payments, control number generation | Institutional access | https://www.gepg.go.tz/ — API docs at gepg.go.tz/documents, SHA1withRSA digital signatures |
| eGA mPortal | e-Government Agency, Tanzania | Citizen portal for government mobile services | Free to citizens | https://mportal.ega.go.tz/ — Aggregates government apps |
| NBS Statistical Portal (TISP) | National Bureau of Statistics | Census data, DHS, SDG indicators by ward/district | Free | https://www.nbs.go.tz/portals — Multiple data portals including TNADA, TASIS |
| World Bank Open Data API | World Bank | Tanzania governance and development indicators | Free | https://data.worldbank.org/country/tanzania |

---

## 3. dc (District Commissioner / District Government)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Tanzania Open Data Portal | Government of Tanzania | District-level statistics and development data | Free | http://opendata.go.tz/ |
| NBS Data Portals | National Bureau of Statistics | District-disaggregated census, economic, social data | Free | https://www.nbs.go.tz/portals — Tanzania Statistical Information Service (TASIS) |
| HDX Administrative Boundaries | UN OCHA | District boundary shapefiles (admin level 2) | Free | https://data.humdata.org/dataset/cod-ab-tza |
| World Bank Projects API | World Bank | Development project data in Tanzania | Free | https://projects.worldbank.org/ — REST API for project tracking |
| Tanzania Data Portal | Open Data for Africa | District-level economic indicators | Free | https://tanzania.opendataforafrica.org/data/ |

---

## 4. rc (Regional Commissioner / Regional Government)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Tanzania Open Data Portal | Government of Tanzania | Regional statistics, development indicators | Free | http://opendata.go.tz/ |
| NBS Data Portals | National Bureau of Statistics | Regional census, demographic, health survey data | Free | https://www.nbs.go.tz/portals |
| HDX Administrative Boundaries | UN OCHA | Regional boundary shapefiles (admin level 1) | Free | https://data.humdata.org/dataset/cod-ab-tza — Includes Songwe region (TZ26) created 2016 |
| World Bank Open Data API | World Bank | Regional development indicators for Tanzania | Free | REST API, JSON/XML responses |
| Tanzania Data Portal | Open Data for Africa | Regional economic, social, demographic data | Free | https://tanzania.opendataforafrica.org/ |

---

## 5. katiba (Constitution & Legal Texts)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Laws.Africa Content API | Laws.Africa / Open Law Africa | Machine-readable African legislation in Akoma Ntoso XML | Free (non-commercial) | https://laws.africa/api/ — Covers Tanzania, structured legal data, supports RAG workflows |
| Laws.Africa Knowledge Base API | Laws.Africa | Legal data retrieval for RAG/LLM agent workflows | Free (non-commercial), paid for commercial | https://developers.laws.africa/ai-api/knowledge-bases |
| OpenLaws API | OpenLaws | US legislation data for legal tech and LLMs | Paid (contact for pricing) | https://openlaws.us/api/ — Primarily US law |
| CourtListener API | Free Law Project | US case law, dockets, court opinions | Free (non-profit) | https://www.courtlistener.com/help/api/ — US-focused, MCP server in development |
| SAFLII | Southern African Legal Information Institute | Legislation from 16 southern/eastern African countries | Free | https://www.saflii.org/ — Includes Tanzania case law |

**Note:** Laws.Africa is the strongest option for Tanzania-specific legal text. The Tanzania Constitution and key legislation are available in machine-readable format through their API.

---

## 6. legal_gpt (Legal AI Assistant)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Anthropic Claude API | Anthropic | LLM for legal document analysis, drafting, Q&A | Haiku: $1/$5, Sonnet: $3/$15, Opus: $5/$25 per 1M tokens | https://platform.claude.com/docs/ — 1M context window, batch API 50% off |
| OpenAI GPT API | OpenAI | LLM for legal analysis, summarization, extraction | GPT-4.1: $2/$8, Mini: $0.40/$1.60, Nano: $0.10/$0.40 per 1M tokens | https://platform.openai.com/docs/ — 1M context (GPT-4.1), batch API 50% off |
| Laws.Africa Knowledge Base API | Laws.Africa | Legal data retrieval for RAG pipelines | Free (non-commercial) | https://developers.laws.africa/ai-api/knowledge-bases — Purpose-built for legal AI |
| CourtListener API | Free Law Project | Case law data for legal AI training/retrieval | Free (means-based) | https://www.courtlistener.com/help/api/ |
| Fastcase Legal Data API | Fastcase | Comprehensive US legal data for AI integration | Paid (enterprise) | https://www.fastcase.com/solutions/legal-data-api/ |

**Recommended approach:** Use Claude or GPT API as the reasoning engine, Laws.Africa API for Tanzania legal corpus retrieval (RAG), and SAFLII for case law.

---

## 7. nida (National ID Verification)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| NIDA Verification API | NIDA (National Identification Authority), Tanzania | National ID verification, biometric matching | Government/institutional access | https://services.nida.go.tz/ — PIN-based verification, used by banks/telecoms |
| Smile ID | Smile Identity | ID verification across all 54 African countries, including Tanzania NIN | Pay-per-verification (contact sales) | https://docs.usesmileid.com — Supports Tanzania phone number verification, 8500+ ID types |
| uqudo | uqudo | Tanzania KYC/AML, ID document verification | Contact for pricing | https://docs.uqudo.com/ — Web SDK, Mobile SDK (8MB), REST API |
| Dojah | Dojah | Identity verification across 10+ African countries | Pay-per-verification | https://dojah.io/ — Passport, driver's license, TIN verification |
| ID Analyzer | ID Analyzer | Tanzania ID document scanning and validation | Freemium | https://www.idanalyzer.com/ — Supports TZ driver's license, passport |

**Note:** Direct NIDA API access is restricted to authorized institutions (banks, telecoms, government). For third-party apps, use Smile ID or uqudo as intermediaries that have NIDA integration.

---

## 8. rita (Civil Registration — Births, Deaths, Marriage)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| eRITA Online Services | RITA (Registration Insolvency and Trusteeship Agency), Tanzania | Birth/death certificate application, verification | Government portal (fees apply for certificates) | https://erita.rita.go.tz/ — No public REST API; web portal only |
| GePG | Ministry of Finance, Tanzania | Payment for RITA certificate fees via control numbers | Institutional integration | Used for RITA fee payments via mobile money/bank |

**Note:** RITA does not expose a public developer API. Certificate verification is done through the eRITA web portal. Integration would require either a partnership agreement with RITA or web automation (not recommended). Birth/death data for statistical purposes is available through NBS portals.

---

## 9. tra (Tax — TIN Verification, E-Filing)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| TRA VFD API | Tanzania Revenue Authority | Virtual Fiscal Device integration, Z-reports, receipt verification | Free (for registered taxpayers) | https://tra-docs.netlify.app/guide/api/ — XML-based (not REST), token auth, registration via TIN |
| TRA E-Filing Portal | Tanzania Revenue Authority | Electronic tax return filing | Free for taxpayers | https://efiling.tra.go.tz — Web portal, SMS verification |
| TRA CDLS | Tanzania Revenue Authority | Computerized Drivers License System (uses TIN) | Government service | Part of IDRAS initiative |
| TRA CMVRS | Tanzania Revenue Authority | Central Motor Vehicle Registration System | Government service | Uses TIN for vehicle registration |
| TaxDo TIN Validation | TaxDo | Tanzania TIN format validation (9 digits) | Free (validation rules) | https://taxdo.com/ — Format validation only, not live verification |

**Note:** TRA's VFD API is the primary developer-facing API. It uses XML (not JSON), requires one-time TIN registration, and uses token-based authentication. E-Filing is web-portal-only with no public REST API.

---

## 10. brela (Business Registration)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| BRELA ORS | BRELA (Business Registrations and Licensing Agency), Tanzania | Business name search, company registration, trademark, patent | Government fees apply | https://ors.brela.go.tz/ — Web portal, integrated with GePG for payments |
| GePG | Ministry of Finance, Tanzania | Payment processing for BRELA registration fees | Institutional | Integrated with BRELA ORS for control number payments |
| Tanzania Business Portal (TNBP) | Government of Tanzania | Business registration guidance and links | Free | https://business.go.tz/register-a-business |
| org-id.guide | Open Data Services | Tanzania business registration identifier lookup | Free | https://org-id.guide/list/TZ-BRLA — Identifier scheme reference |

**Note:** BRELA ORS is a web portal built by NRD Companies on Java/PostgreSQL/GeoServer. No public REST API exists. The system integrates with NIDA for identity verification and GePG for payments. Third-party integration would require a formal agreement with BRELA. Public business name search is available at https://ors.brela.go.tz/orsreg/searchbusinesspublic.

---

## 11. passport (Passport & Immigration)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Passport Index API | Arton Capital | Visa requirements between countries, passport rankings | Contact for API access | https://discover.passportindex.org/api-request/ — Government agencies prioritized |
| Travel Buddy Visa API | Travel Buddy AI | Visa requirements, entry rules, duration of stay | Freemium (free tier available) | https://rapidapi.com/TravelBuddyAI/api/visa-requirement — Daily updated, /v2/visa/check endpoint |
| VisaDB API | VisaDB | Visa, entry, vaccination, customs requirements per country | Freemium | https://visadb.io/api — 5 data categories per country |
| Passport Visa API (community) | Community / GitHub | Visa requirements matrix for 199 passports | Free (open source) | https://github.com/nickypangers/passport-visa-api — Community-maintained |
| passport-index-dataset | Community / GitHub | CSV datasets of visa requirements (ISO codes) | Free (open source) | https://github.com/ilyankou/passport-index-dataset — Updated regularly |

**Note:** Tanzania Immigration Department does not expose a public API. Passport application status is checked via the immigration portal. For visa requirement lookups, Travel Buddy or VisaDB APIs provide good coverage.

---

## 12. driving_licence (Driving Licence & Vehicle)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| TRA CDLS | Tanzania Revenue Authority | Digital driving licence issuance and verification | Government service | Part of IDRAS initiative, uses TIN, SMS/email notifications |
| LATRA RRIMS | LATRA (Land Transport Regulatory Authority) | Railway & road information management | Government portal | https://rrims.latra.go.tz/ — Regulatory data |
| ID Analyzer | ID Analyzer | Tanzania driver's license document scanning/validation | Freemium | https://www.idanalyzer.com/solutions/supported-documents/tz.html |
| Smile ID | Smile Identity | Driver's license verification across Africa | Pay-per-verification | https://usesmileid.com/supported-documents/ — Document verification |
| KYC Chain | KYC Chain | Tanzania driver's license, passport verification | Contact for pricing | https://kyc-chain.com/coverage/tanzania/ |

**Note:** TRA's CDLS handles digital licence issuance. The system is part of the Integrated Domestic Revenue Administration System (IDRAS). No public REST API; services are accessed via TRA portals using TIN authentication.

---

## 13. land_office (Land Registry & GIS)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| ILMIS | Ministry of Lands, Tanzania (MLHHSD) | Land title verification, cadastral management, CRO issuance | Government institutional access | https://ilmis.lands.go.tz/ — Built on PostgreSQL/GeoServer/QGIS, integrated with NIDA and GePG |
| OpenStreetMap / Nominatim | OpenStreetMap Foundation | Geocoding, address lookup, land parcel mapping | Free (1 req/sec public) | https://nominatim.org/ — Self-hostable, Tanzania coverage via Ramani Huria project |
| HDX Administrative Boundaries | UN OCHA | Ward/district/region boundary shapefiles | Free | https://data.humdata.org/dataset/cod-ab-tza |
| Google Maps Platform | Google | Geocoding, mapping, satellite imagery | $200/month free credit, then pay-per-use | https://developers.google.com/maps — Static Maps, Geocoding, Places APIs |
| Mapbox API | Mapbox | Custom maps, geocoding, satellite imagery | Free tier (50K map loads/mo), then pay-per-use | https://docs.mapbox.com/api/ — Good Africa coverage |

**Note:** ILMIS is the authoritative land registry system for Tanzania, built on open-source tech (PostgreSQL, GeoServer). It handles 80+ transaction types and contains 6.5M digitized documents. No public API; institutional access required. For mapping/GIS needs, use OpenStreetMap (Ramani Huria has detailed Dar es Salaam data) or Mapbox.

---

## 14. nhif (Health Insurance)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| NHIF Verification API | NHIF (National Health Insurance Fund), Tanzania | Member card status, verification code validity, payment status | Institutional access (universities, hospitals) | https://verification.nhif.or.tz/ — API available for institutional partners |
| NHIF Self-Service Portal | NHIF, Tanzania | Member registration, contribution checking, benefit status | Free for members | https://selfservice.nhif.or.tz/ — Web portal |
| GePG | Ministry of Finance, Tanzania | NHIF contribution payments via control numbers | Institutional | Government payment gateway |

**Note:** NHIF exposes APIs for institutional partners (universities, hospitals, healthcare providers) to verify member status, card validity, and payment status. Third-party app integration requires formal partnership with NHIF. Member self-service is available via the web portal.

---

## 15. nssf (Social Security)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| NSSF Portal | NSSF (National Social Security Fund), Tanzania | Contribution tracking, account statements, claims | Free for members | https://portal.nssf.go.tz/ — "One Portal, One Account" |
| NSSF Mobile App | NSSF, Tanzania | Real-time contribution tracking, statements, claims | Free | Available on Google Play and App Store |
| NSSF SMS Service | NSSF, Tanzania | Balance checking via SMS | Free (standard SMS rates) | Send "REGISTER" + membership number to 15747, then "SALIO" for balance |

**Note:** NSSF does not expose a public developer API. Services are available through their portal, mobile app, and SMS. Integration would require a formal partnership agreement with NSSF. For employer/payroll integrations, contact NSSF directly.

---

## 16. tanesco (Electricity — LUKU Prepaid Tokens)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Selcom Utility Payments API | Selcom | TANESCO LUKU token purchase via API | Commission-based (contact info@selcom.net) | https://developers.selcommobile.com/ — REST API, PHP/Java/Shell SDKs |
| AzamPay API | AzamPay (Bakhresa Group) | Mobile money payments including utility bills | Pay-per-transaction | https://azampay.com/developers — Dart SDK available on pub.dev (azampaytanzania) |
| ClickPesa BillPay API | ClickPesa | Utility bill payments with control number generation | Contact for pricing | https://docs.clickpesa.com/bill-pay/billpay-api-overview — Supports GePG control numbers |
| Beem Africa Payments API | Beem | Mobile money collection, utility payments | Tier-based pricing | https://beem.africa/mobile-payments-api/ — 22 country coverage |
| elipapower (community) | Community / GitHub | Prepaid electricity token integration reference | Free (open source) | https://github.com/jkikuyu/elipapower — Reference implementation |

**Recommended approach:** Use Selcom API (largest LUKU vending agent) or AzamPay (has Flutter/Dart SDK on pub.dev) for TANESCO LUKU token purchases. Both are established payment aggregators with direct TANESCO integration.

---

## 17. dawasco (Water Utility)

| API | Provider | Purpose | Pricing | Notes |
|-----|----------|---------|---------|-------|
| Selcom Utility Payments API | Selcom | DAWASCO bill payment via API | Commission-based (contact info@selcom.net) | https://developers.selcommobile.com/ — Supports utility bill payments |
| AzamPay API | AzamPay | Mobile money payments for water bills | Pay-per-transaction | https://azampay.com/developers — mobileCheckout and bankCheckout methods |
| ClickPesa BillPay API | ClickPesa | Bill payment with GePG control number support | Contact for pricing | https://docs.clickpesa.com/ — Automates control number generation |
| Beem Africa Payments API | Beem | Utility bill payments via mobile money | Tier-based pricing | https://beem.africa/ — USSD and API options |
| DAWASA App | DAWASA, Tanzania | View bills, report issues, apply for connections | Free for customers | https://mportal.ega.go.tz/application/4 — No public developer API |

**Note:** DAWASCO/DAWASA does not expose a public developer API. Bill payments are routed through payment aggregators (Selcom, AzamPay, ClickPesa) or mobile money (M-Pesa, Tigo Pesa, Airtel Money). For integration, use a payment aggregator that supports DAWASCO bill reference numbers.

---

## Cross-Cutting APIs (Used Across Multiple Modules)

| API | Provider | Purpose | Modules | Pricing |
|-----|----------|---------|---------|---------|
| Selcom API | Selcom | Payment aggregation, utility payments, mobile money | tanesco, dawasco, tra | Commission-based — https://developers.selcommobile.com/ |
| AzamPay API | AzamPay | Mobile money & card payments | tanesco, dawasco | Per-transaction — https://azampay.com/developers — **Has Dart/Flutter SDK** |
| ClickPesa API | ClickPesa | BillPay, GePG integration, payments | tanesco, dawasco, ofisi_mtaa | Contact — https://docs.clickpesa.com/ |
| GePG | Ministry of Finance | Government fee payments | brela, rita, ofisi_mtaa, nhif, nssf | Institutional — https://www.gepg.go.tz/ |
| Smile ID | Smile Identity | Pan-African ID verification | nida, driving_licence, passport | Per-verification — https://docs.usesmileid.com |
| Laws.Africa API | Laws.Africa | African legislation data | katiba, legal_gpt | Free (non-commercial) — https://laws.africa/api/ |
| OpenStreetMap / Nominatim | OSM Foundation | Mapping, geocoding | barozi_wangu, land_office, dc, rc | Free — https://nominatim.org/ |
| Tanzania Open Data Portal | Government of Tanzania | Government statistics | barozi_wangu, ofisi_mtaa, dc, rc | Free — http://opendata.go.tz/ |

---

## Integration Priority Matrix

### Tier 1 — APIs with public developer docs, ready to integrate
- **Selcom API** (utility payments) — REST API, documented
- **AzamPay API** (payments) — Has Dart/Flutter SDK on pub.dev
- **Laws.Africa API** (legal texts) — REST API, free for non-commercial
- **Claude / OpenAI API** (legal AI) — Well-documented, pay-per-token
- **OpenStreetMap / Nominatim** (mapping) — Free, self-hostable
- **World Bank API** (statistics) — Free, no auth
- **Travel Buddy / VisaDB API** (visa requirements) — Freemium

### Tier 2 — APIs available but require registration/partnership
- **Smile ID** (ID verification) — Requires merchant account
- **uqudo** (KYC/AML) — Requires partnership
- **ClickPesa API** (payments) — Requires merchant registration
- **TRA VFD API** (tax) — Requires taxpayer TIN registration
- **NHIF API** (health insurance) — Institutional partners only
- **GePG** (government payments) — Institutional integration

### Tier 3 — No public API, portal-only or partnership required
- **NIDA** (national ID) — Restricted to authorized institutions
- **RITA/eRITA** (civil registration) — Web portal only
- **BRELA ORS** (business registration) — Web portal, public search only
- **NSSF** (social security) — Portal + mobile app only
- **ILMIS** (land registry) — Institutional access
- **DAWASCO** (water) — No API, use payment aggregators
- **TRA E-Filing** (tax returns) — Web portal only
- **LATRA/CDLS** (driving licence) — Government portal only
