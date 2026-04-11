# TAJIRI Module API Directory

> Available APIs for enhancing TAJIRI modules. Researched 2026-04-08.
>
> Legend: TZ = Tanzania-specific, AF = Africa-wide, GL = Global

---

## Cross-Module: Payment Processing

These payment APIs are shared across multiple modules (tajirika, ambulance, car_insurance, buy_car, fuel_delivery, service_garage, sell_car, rent_car, spare_parts).

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Mobile money payments (C2B, B2C, B2B) | Transaction fees | TZ | Fintech 2.0 platform launched Apr 2026. 1,000+ TPS capacity. Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for mobile money + cards | Transaction fees | TZ | Supports mobileCheckout + bankCheckout. Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection + disbursement | Transaction fees | TZ | Aggregates M-Pesa, Tigo Pesa (Mixx by Yas), Airtel Money, HaloPesa. Bulk payouts supported |
| [Mixx by Yas (Tigo Pesa)](https://clickpesa.com/payment-gateway/payment-and-payout-methods/mixx-by-yas-tigo-pesa-api-integration-guide/) | Yas Tanzania (Axian Group) | Mobile money via USSD push | Transaction fees | TZ | Best accessed via ClickPesa aggregator rather than direct integration |
| [DPO Pay API](https://docs.dpopay.com/api/index.html) | DPO Group (Network International) | Card + mobile money payments across Africa | Transaction fees | AF | Operates in 20+ African countries. XML/PHP primary. Mobile SDK available |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS, USSD, Voice, Airtime distribution | Pay-as-you-go | AF | 150K+ developer community. Supports Vodacom, Tigo, Airtel in TZ. Great for USSD payment flows |

---

## Cross-Module: Maps, Location & Routing

Used by ambulance, fuel_delivery, service_garage, rent_car, and other location-dependent modules.

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Google Maps Platform](https://developers.google.com/maps) | Google | Geocoding, Directions, Places, Distance Matrix | Freemium (10K free/month per Essentials SKU, then $2-7/1K) | GL | New 2025 per-SKU billing model. Routes API replaces legacy Directions API |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, Directions, Geocoding, Navigation SDK | Freemium (100K free directions/month, 100K geocoding) | GL | Generous free tier. $2/1K directions after free tier. Mobile Navigation SDK available |
| [OpenRouteService](https://openrouteservice.org/) | HeiGIT / Heidelberg University | Routing, Isochrones, Matrix, Geocoding | Free (open source, self-hostable) | GL | Uses OpenStreetMap data. Car, bicycle, walking, wheelchair routing. Can self-host via Docker |

---

## Cross-Module: Communication

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Twilio SMS/WhatsApp](https://www.twilio.com/en-us/sms/pricing/tz) | Twilio | SMS and WhatsApp messaging | Pay-as-you-go ($0.005/WhatsApp msg + Meta fees) | GL | Tanzania SMS supported. WhatsApp 24hr service window is free of Meta charges |
| [Africa's Talking SMS](https://developers.africastalking.com/docs/sms/overview) | Africa's Talking | SMS, USSD, Voice for Africa | Pay-as-you-go | AF | Better TZ carrier coverage than Twilio. Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Push notifications | Free | GL | Already integrated in TAJIRI app |

---

## 1. tajirika (Partnership / Gig Economy Program)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Verified.Africa](https://docs.verified.africa/) | Verified Africa | Identity verification, KYC for gig workers | Paid (per-verification) | AF | Digital identity verification across Africa. API-first |
| [VerifyMe](https://verifyme.ng/) | VerifyMe Nigeria | Background checks, ID verification, facial recognition | Paid (per-check) | AF | KYC + facial recognition via "Pluto" product. Expanding beyond Nigeria |
| [Checkr API](https://checkr.com/our-technology/background-check-api) | Checkr | Background checks, employment verification | Paid (per-check) | GL | International criminal search, education + employment verification. 196 countries |
| [Authenticate](https://authenticate.com/) | Authenticate.com | ID authentication, background verification | Paid | GL | 7,500+ ID types from 196 countries. Facial recognition + liveness detection |
| M-Pesa / AzamPay / ClickPesa | (See Cross-Module) | Worker payments, escrow, disbursements | Transaction fees | TZ | Use ClickPesa for bulk worker payouts to multiple mobile money wallets |

---

## 2. ambulance (Emergency Services)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Rescue.co / Flare](https://www.rescue.co/) | Rescue.co (Trek Medics) | Ambulance dispatch, GPS fleet tracking, clinical triage | Partnership / B2B | AF | Operates in Kenya, Uganda, Tanzania. 800+ ambulance providers onboarded. Proprietary dispatch platform with real-time GPS. Contact for API partnership |
| [Emergency Dispatch Africa](https://www.emergencydispatchafrica.com/) | Emergency Dispatch Africa | CAD (Computer-Aided Dispatch) for emergency services | B2B | AF | Dispatch software with GPS tracking and priority-based routing |
| [Tanzania Health Facility Registry](https://hfrs.moh.go.tz/) | Tanzania Ministry of Health | Hospital/clinic database, facility locations, GPS coordinates | Free (government) | TZ | Master Facility List for all TZ health facilities. Web-based, may need scraping — no public REST API documented |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Route optimization, ETA calculation, hospital search | Freemium | GL | Places API for finding nearby hospitals. Routes API for ambulance routing |
| [OpenRouteService](https://openrouteservice.org/) | HeiGIT | Isochrone maps (reachability areas), routing | Free / open source | GL | Isochrones show which areas an ambulance can reach in X minutes |

---

## 3. my_cars (Vehicle Management)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [TRA Motor Vehicle Registration](https://www.tra.go.tz/index.php/motor-vehicles-registration) | Tanzania Revenue Authority | Vehicle registration lookup | Government portal | TZ | No public API documented. Web portal + TRA mobile app available. May need partnership agreement |
| [LATRA VTS](https://vts.latra.go.tz/) | Land Transport Regulatory Authority | Commercial vehicle tracking, compliance | Government system | TZ | GPS-based vehicle tracking for intercity buses. Contact LATRA for integration |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding (make, model, year, specs) | Free | GL | Best free VIN decoder. REST/JSON. Works for vehicles manufactured for any market |
| [Vincario](https://vincario.com/vin-decoder/) | Vincario | Global VIN decoding + vehicle history | Paid (per-query) | GL | Supports European, Asian, African market vehicles. Bulk VIN decode |
| [CarMD API](https://www.carmd.com/api/) | CarMD | OBD-II diagnostics, repair estimates, maintenance schedules | Paid (tiered plans) | GL | Diagnostic code interpretation, repair cost estimates, parts lists. 1996+ vehicles |
| [Smartcar API](https://smartcar.com/docs/api/) | Smartcar | Connected car data (fuel, odometer, location, lock/unlock) | Freemium (tiered plans) | GL | OAuth 2.0 vehicle auth. 40+ automakers, 177M cars. No OBD hardware needed |

---

## 4. car_insurance (Insurance)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [BimaSokoni](https://www.bimasokoni.co.tz/) | BimaSokoni | Insurance comparison marketplace for Tanzania | Partnership | TZ | First TZ insurance aggregator. Compare quotes from multiple insurers. Contact for API access |
| [TIRA Verification](https://www.tira.go.tz/) | Tanzania Insurance Regulatory Authority | Insurance policy verification | Government portal | TZ | Verify active policies online. No public REST API — web-based verification |
| [AfricaBima API](http://africabima.com/api.html) | AfricaBima | Insurance quotation, claims, policy management | B2B partnership | AF | Digital insurance gateway. Integrated with IPRS, NTSA, M-Pesa. Supports quotations, claims processing, payments |
| [Qover API](https://www.qover.com/api) | Qover | Embedded insurance (motor, travel, liability) | Per-policy fees | GL | White-label embedded insurance. RESTful API for quote, bind, claim |
| [Bolttech API](https://bolttech.io/sales/embedded-insurance-api/) | Bolttech | Embedded insurance distribution platform | Per-policy fees | GL | Insurance exchange connecting 200+ insurers. Motor insurance supported |

---

## 5. buy_car (Car Marketplace)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [BE FORWARD](https://www.beforward.jp/) | BE FORWARD Co., Ltd. | Used car listings from Japan (largest exporter to Africa) | No public API | GL/AF | No documented developer API. Dominant in TZ market. Would need web scraping or partnership agreement |
| [SBT Japan](https://www.sbtjapan.com/) | SBT Co., Ltd. | Used car listings from Japan, car tracking | No public API | GL/AF | 13,000+ vehicles/month to 200+ countries. Marketplace at kaitore.com. Contact for B2B integration |
| [TRA Import Duty Calculator](https://www.tra.go.tz/index.php/90-calculators-tools) | Tanzania Revenue Authority | Vehicle import duty estimation | Free (government tool) | TZ | Calculates CIF-based duties (25-50% depending on engine/age). Web tool, no REST API |
| [MarketCheck Cars API](https://www.marketcheck.com/apis/cars/) | MarketCheck | Vehicle listings aggregation, pricing analytics | Paid (tiered) | GL | Active + historical listings data. Pricing analytics and market trends |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding for imported vehicles | Free | GL | Decode VIN before purchase to verify vehicle specs |
| [Vindecoder.eu API](https://vindecoder.eu/api/) | Vindecoder.eu | European + global VIN decoding | Paid (per-query) | GL | Covers cars, trucks, buses, motorcycles, tractors worldwide |
| [Vehicle Databases Market Value API](https://vehicledatabases.com/api/vehicle-market-value) | Vehicle Databases | Car valuation by VIN or make/model/year | Paid (subscription) | GL | Retail, private party, and trade-in values. Alternative to KBB |

---

## 6. fuel_delivery (Fuel Services)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [EWURA Cap Prices](https://www.ewura.go.tz/publications/petroleum-price) | EWURA (Tanzania) | Official fuel cap prices for 190+ TZ locations | Free (government) | TZ | Monthly PDF publications. No REST API — would need scraping or scheduled data extraction |
| [GlobalPetrolPrices API](https://www.globalpetrolprices.com/data_access.php) | GlobalPetrolPrices.com | Fuel prices for 135 countries including Tanzania | Paid (subscription, 2-week free trial) | GL | XML data feed. Historical data + forecasts. Includes Brent/WTI crude prices |
| [HERE Fuel Prices API](https://developer.here.com/documentation/fuel-prices/dev_guide/topics/overview.html) | HERE Technologies | Fuel station locations + real-time prices | Freemium | GL | REST API with JSON/XML. Station search by location. Coverage varies by country |
| [TomTom Fuel Prices API](https://developer.tomtom.com/fuel-prices-api/documentation/product-information/introduction) | TomTom | Fuel station prices and locations | Freemium | GL | Part of TomTom's location services suite |
| [Google Maps Places API](https://developers.google.com/maps/documentation/places) | Google | Find nearby fuel stations | Freemium | GL | Search for gas stations by location. Returns ratings, hours, contact info |
| [Easy Track Africa](https://easytrackafrica.com/) | Easy Track | GPS fleet tracking for fuel delivery vehicles | B2B subscription | AF | LATRA-approved VTS provider in Tanzania. Real-time vehicle tracking |

---

## 7. service_garage (Auto Repair)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [CarMD API](https://www.carmd.com/api/) | CarMD | OBD-II diagnostics, repair estimates, maintenance alerts | Paid (tiered) | GL | Check engine light diagnosis, repair cost estimates with parts + labor breakdown, maintenance schedules |
| [TecDoc Catalog API](https://www.tecalliance.net/tecdoc-catalogue/) | TecAlliance | OEM + aftermarket parts catalog, compatibility data | Paid (enterprise, $3K-50K+ integration) | GL | 1,000+ subscribers. Industry-standard parts database. 14 languages |
| [Car Databases Auto Parts API](https://cardatabases.com/api/auto-parts) | Car Databases | OEM part numbers, cross-reference, fitment | Paid (subscription) | GL | ACES/PIES standards. OEM-to-aftermarket cross-reference |
| [Vehicle Databases Services API](https://vehicledatabases.com/vehicle-services-api) | Vehicle Databases | Service schedules, recall data, repair info | Paid (subscription) | GL | Maintenance schedules by VIN. Recall notifications |
| [Levam OEM Parts API](https://levam.net/) | Levam Automotive | OEM parts catalog with visual diagrams | Paid | GL | VIN-based parts lookup. Embeddable widget + API. Visual parts diagrams |

---

## 8. sell_car (Vehicle Sales)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Vehicle Databases Market Value API](https://vehicledatabases.com/api/vehicle-market-value) | Vehicle Databases | Market value estimation (retail, private, trade-in) | Paid (subscription) | GL | Valuation by VIN or make/model/year. State/city-level pricing |
| [Auto.dev Vehicle Listings API](https://www.auto.dev/listings) | Auto.dev | Vehicle listing creation + syndication | Freemium (1,000 free/month) | GL | List vehicles for sale. 1,000 free API calls/month |
| [CarAPI](https://carapi.app/) | CarAPI | Vehicle specs database (90K+ vehicles) | Freemium | GL | REST + JSON. Specs from 1900-present. Free tier available |
| [Auto-Data.net API](https://api.auto-data.net/) | Auto-Data.net | Vehicle technical specifications (54K+ entries) | Paid (tiered) | GL | 14 languages. Detailed specs for pricing context |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decode for listing accuracy | Free | GL | Verify vehicle details before listing |

---

## 9. rent_car (Car Rental)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [Amadeus Car & Transfers API](https://developers.amadeus.com/) | Amadeus | Car rental search, booking, availability (69+ providers) | Freemium (200-10K free/month, then EUR 0.001-0.025/call) | GL | Self-service API. 37+ car rental brands in 40K locations. Test environment included |
| [Booking.com Cars API](https://developers.booking.com/demand/docs/cars/overview) | Booking Holdings | Car rental inventory (45K locations, 200+ suppliers, 150 countries) | Partnership / affiliate | GL | Requires affiliate partnership. Real-time availability + pricing |
| [Smartcar API](https://smartcar.com/docs/api/) | Smartcar | Remote fleet management (lock/unlock, location, fuel level) | Freemium (tiered) | GL | Track rental fleet vehicles remotely. OAuth 2.0 vehicle authorization |
| [FleetON API](https://fleetonapp.com/products/api-integration/) | FleetON | Fleet management, booking engine, availability | B2B subscription | GL | Purpose-built for car rental businesses. API integration for fleet ops |
| Google Maps / Mapbox | (See Cross-Module) | Vehicle location tracking, route display | Freemium | GL | Track rental vehicles on map |

---

## 10. owners_club (Automotive Community)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [CarAPI](https://carapi.app/) | CarAPI | Vehicle specs database, make/model/trim data | Freemium | GL | 90K+ vehicles. REST + JSON. Good for car profiles in community |
| [CarQuery API](https://www.carqueryapi.com/) | CarQuery | Vehicle year/make/model/trim specifications | Free | GL | JSON API. Good for community car profiles and spec comparisons |
| [Auto-Data.net API](https://api.auto-data.net/) | Auto-Data.net | Detailed technical specs (54K+ vehicles, 14 languages) | Paid (tiered) | GL | Engine, performance, dimensions data for car spec pages |
| [Car Database API](https://cardatabaseapi.com/) | Car Database API | Makes, models, generations, trims, body types, engines | Paid | GL | Comprehensive car data for enthusiast profiles |
| [NHTSA Recalls API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | Vehicle recall notifications | Free | GL | Alert club members about recalls affecting their vehicles |
| Firebase / Firestore | Google | Real-time community features (chat, forums, events) | Freemium | GL | Already integrated in TAJIRI. Use for club chat and event coordination |

---

## 11. spare_parts (Parts Marketplace)

| API | Provider | Purpose | Pricing | Scope | Notes |
|-----|----------|---------|---------|-------|-------|
| [TecDoc Catalog API](https://www.tecalliance.net/tecdoc-catalogue/) | TecAlliance | Industry-standard parts catalog, OEM + aftermarket | Paid (enterprise) | GL | 1,000+ companies use it. OEM-to-aftermarket cross-reference. Fitment data by vehicle |
| [Car Databases Auto Parts API](https://cardatabases.com/api/auto-parts) | Car Databases | Part numbers, cross-reference, pricing, fitment | Paid (subscription) | GL | ACES/PIES standards. Interchange data for finding compatible parts |
| [Levam OEM Parts API](https://levam.net/) | Levam Automotive | OEM parts catalogs with visual diagrams | Paid | GL | VIN-based lookup. Visual parts explosion diagrams. Embeddable widget |
| [7zap Parts Catalog](https://7zap.com/en/) | 7zap | OEM + aftermarket parts with AI assistant | Paid | GL | Visual diagrams from brand/model to exact part number. AI-powered search |
| [Auto Parts Catalog (RapidAPI)](https://rapidapi.com/makingdatameaningful/api/auto-parts-catalog) | Making Data Meaningful | TecDoc alternative for parts lookup | Freemium (via RapidAPI) | GL | Available on RapidAPI marketplace. Easier onboarding than direct TecDoc |
| [Vehicle Databases Auto Parts API](https://vehicledatabases.com/auto-parts) | Vehicle Databases | OEM parts catalogs by VIN | Paid (subscription) | GL | Part names, numbers, and drawings by VIN |

---

## Tanzania-Specific Government Systems (No Public APIs)

These government systems are relevant but lack documented REST APIs. Integration would require partnership agreements, web scraping, or manual data entry.

| System | Authority | Relevance | URL |
|--------|-----------|-----------|-----|
| TRA Motor Vehicle Registration | Tanzania Revenue Authority | Vehicle registration, ownership transfer | https://www.tra.go.tz |
| TRA Import Duty Calculator | Tanzania Revenue Authority | Car import duty estimation | https://www.tra.go.tz/index.php/90-calculators-tools |
| LATRA VTS | Land Transport Regulatory Authority | Commercial vehicle GPS tracking | https://vts.latra.go.tz |
| LATRA RRIMS | Land Transport Regulatory Authority | Railway & Road Information Management | https://rrims.latra.go.tz |
| TIRA | Tanzania Insurance Regulatory Authority | Insurance policy verification | https://www.tira.go.tz |
| EWURA | Energy & Water Utilities Regulatory Authority | Monthly fuel cap prices (190+ locations) | https://www.ewura.go.tz |
| Health Facility Registry | Ministry of Health | Hospital/clinic database with GPS | https://hfrs.moh.go.tz |
| Tanzania Police RTOC | Tanzania Police Force | Traffic management system | https://tms.tpf.go.tz |

---

## Recommended Integration Priority

### Phase 1 (Quick wins with existing Flutter support)
1. **M-Pesa Open API** via `mpesa_sdk` Dart package (payments across all modules)
2. **AzamPay** via `azampaytanzania` Dart package (additional payment option)
3. **NHTSA vPIC API** (free VIN decoding for my_cars, buy_car, sell_car)
4. **Google Maps / Mapbox** (already partially integrated; extend for ambulance, fuel_delivery)
5. **Firebase FCM** (already integrated; extend for ambulance alerts, service reminders)

### Phase 2 (High-value integrations)
6. **ClickPesa** (unified payment aggregator covering all TZ mobile money)
7. **CarMD API** (diagnostics for my_cars, service_garage)
8. **Africa's Talking** (SMS/USSD for ambulance emergency dispatch)
9. **Rescue.co / Flare** (ambulance dispatch partnership for TZ)
10. **EWURA data** (fuel prices for fuel_delivery — scrape monthly PDFs)

### Phase 3 (Premium features)
11. **TecDoc / Auto Parts APIs** (spare_parts catalog)
12. **AfricaBima API** (car_insurance quotes and claims)
13. **Amadeus Self-Service API** (rent_car booking)
14. **Smartcar API** (connected car features for my_cars, rent_car fleet)
15. **GlobalPetrolPrices API** (fuel price data feed)

### Phase 4 (Partnership-dependent)
16. **BE FORWARD / SBT Japan** (buy_car listings — requires B2B partnership)
17. **BimaSokoni** (insurance comparison — requires partnership)
18. **TRA / LATRA systems** (vehicle registration — requires government partnership)
19. **Verified.Africa** (tajirika worker verification)
