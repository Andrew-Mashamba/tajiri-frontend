# TAJIRI Travel Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current tourism-destination travel module with a transport-first platform supporting bus, flight, train, and ferry search & booking across Tanzania and internationally.

**Architecture:** Single unified search endpoint fans out to multiple transport providers (Otapp buses, Amadeus flights, internal SGR/ferry schedules, BuuPass cross-border). Frontend sends origin + destination + date, gets back normalized TransportOption results across all modes. Full booking and payment within TAJIRI.

**Tech Stack:** Flutter/Dart frontend, Laravel 12 backend (PHP 8.3, PostgreSQL 16, Redis 7), external APIs (Otapp, Amadeus, BuuPass, WeatherAPI.com)

**Spec:** `docs/superpowers/specs/2026-04-07-travel-module-design.md`

**Backend server:** SSH `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`, project at `/var/www/tajiri.zimasystems.com`

---

## File Map

### Frontend (17 files — all in `lib/travel/`)

| File | Responsibility |
|---|---|
| `travel_module.dart` | Entry point StatelessWidget wrapping TravelHomePage |
| `models/travel_models.dart` | All models, enums, result wrappers, parse helpers |
| `services/travel_service.dart` | All API calls to `/api/travel/*` endpoints |
| `pages/travel_home_page.dart` | Search bar, recent searches, popular routes, upcoming trips |
| `pages/search_results_page.dart` | Results list with mode filters, sort, badges |
| `pages/transport_detail_page.dart` | Option detail with amenities, class selection |
| `pages/passenger_info_page.dart` | Passenger forms with ID validation |
| `pages/checkout_page.dart` | Summary, price breakdown, payment selection |
| `pages/booking_confirmation_page.dart` | Success screen with reference number |
| `pages/my_bookings_page.dart` | Upcoming/Past tabs with booking cards |
| `pages/ticket_page.dart` | E-ticket with QR code, share button |
| `widgets/transport_option_card.dart` | Search result card (mode icon, times, price) |
| `widgets/route_card.dart` | Popular route card for home page |
| `widgets/booking_card.dart` | My bookings list card |
| `widgets/mode_icon.dart` | Bus/plane/train/ferry icon helper |
| `widgets/city_search_field.dart` | Autocomplete city picker with debounce |

### Backend (Laravel — via SSH)

| File | Responsibility |
|---|---|
| `database/migrations/xxxx_create_transport_tables.php` | 8 tables: providers, cities, schedules, inventory, bookings, passengers, tickets, search_cache |
| `app/Models/Travel/TransportProvider.php` | Provider registry model |
| `app/Models/Travel/TransportCity.php` | City/station directory model |
| `app/Models/Travel/TransportSchedule.php` | Internal schedule model (SGR, ferries) |
| `app/Models/Travel/TransportInventory.php` | Per-date seat availability model |
| `app/Models/Travel/TransportBooking.php` | User booking model |
| `app/Models/Travel/TransportPassenger.php` | Passenger manifest model |
| `app/Models/Travel/TransportTicket.php` | E-ticket model |
| `app/Http/Controllers/Api/TransportSearchController.php` | Search + cities + weather endpoints |
| `app/Http/Controllers/Api/TransportBookingController.php` | Booking CRUD + cancel |
| `app/Http/Controllers/Api/TransportTicketController.php` | Ticket retrieval + QR |
| `app/Services/Travel/TravelSearchService.php` | Provider fan-out orchestrator |
| `app/Services/Travel/Providers/TransportProviderInterface.php` | Provider contract |
| `app/Services/Travel/Providers/InternalProvider.php` | SGR + ferry from our DB |
| `app/Services/Travel/Providers/OtappProvider.php` | Otapp bus API integration |
| `app/Services/Travel/Providers/AmadeusProvider.php` | Amadeus flight API integration |
| `app/Services/Travel/Providers/BuuPassProvider.php` | BuuPass cross-border bus API |
| `routes/api.php` | Add transport route group |
| `database/seeders/TransportCitySeeder.php` | Seed Tanzania + East Africa cities |
| `database/seeders/TransportScheduleSeeder.php` | Seed SGR + ferry schedules |

---

## Task 1: Backend — Database Migration

**Files:**
- Create: `database/migrations/2026_04_07_100000_create_transport_tables.php`

- [ ] **Step 1: SSH into backend server**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180
cd /var/www/tajiri.zimasystems.com
```

- [ ] **Step 2: Create the migration file**

```bash
php artisan make:migration create_transport_tables
```

Then write the migration content:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transport_providers', function (Blueprint $table) {
            $table->id();
            $table->string('name');          // Otapp, Amadeus, Internal, BuuPass
            $table->string('code')->unique(); // otapp, amadeus, internal, buupass
            $table->string('api_base_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->json('config')->nullable(); // provider-specific config
            $table->timestamps();
        });

        Schema::create('transport_cities', function (Blueprint $table) {
            $table->id();
            $table->string('name');           // Dar es Salaam
            $table->string('code')->unique(); // DAR
            $table->string('region')->nullable(); // Dar es Salaam Region
            $table->string('country')->default('TZ');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->boolean('has_airport')->default(false);
            $table->boolean('has_bus_terminal')->default(false);
            $table->boolean('has_train_station')->default(false);
            $table->boolean('has_ferry_terminal')->default(false);
            $table->integer('search_count')->default(0); // for popular routes
            $table->timestamps();
        });

        Schema::create('transport_schedules', function (Blueprint $table) {
            $table->id();
            $table->string('mode');           // train, ferry
            $table->string('operator');       // SGR, TRC, Azam Marine
            $table->string('operator_code')->nullable();
            $table->unsignedBigInteger('origin_city_id');
            $table->unsignedBigInteger('destination_city_id');
            $table->time('departure_time');
            $table->time('arrival_time');
            $table->integer('duration_minutes');
            $table->json('days_of_week');     // [1,2,3,4,5] = Mon-Fri
            $table->string('class');          // economy, business, vip
            $table->decimal('price', 12, 2);
            $table->string('currency')->default('TZS');
            $table->integer('seats_total');
            $table->string('vehicle_info')->nullable(); // train number, vessel name
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('origin_city_id')->references('id')->on('transport_cities');
            $table->foreign('destination_city_id')->references('id')->on('transport_cities');
        });

        Schema::create('transport_inventory', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('schedule_id');
            $table->date('date');
            $table->integer('seats_booked')->default(0);
            $table->string('status')->default('available'); // available, full, cancelled
            $table->timestamps();

            $table->foreign('schedule_id')->references('id')->on('transport_schedules');
            $table->unique(['schedule_id', 'date']);
        });

        Schema::create('transport_bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('booking_reference')->unique();
            $table->string('provider_code');  // otapp, amadeus, internal, buupass
            $table->string('provider_booking_id')->nullable(); // external booking ID
            $table->string('mode');           // bus, flight, train, ferry
            $table->string('operator');
            $table->string('origin_city');
            $table->string('destination_city');
            $table->dateTime('departure');
            $table->dateTime('arrival');
            $table->integer('duration_minutes');
            $table->string('class')->nullable();
            $table->integer('passenger_count');
            $table->decimal('unit_price', 12, 2);
            $table->decimal('total_amount', 12, 2);
            $table->string('currency')->default('TZS');
            $table->string('status')->default('pending'); // pending, confirmed, cancelled, completed
            $table->string('payment_method')->nullable();  // wallet, mpesa, tigopesa, airtelmoney
            $table->string('payment_status')->default('pending'); // pending, paid, refunded
            $table->string('payment_phone')->nullable();
            $table->json('option_snapshot')->nullable(); // full TransportOption at time of booking
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
            $table->index(['user_id', 'status']);
        });

        Schema::create('transport_passengers', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('booking_id');
            $table->string('name');
            $table->string('phone')->nullable();
            $table->string('id_type')->nullable(); // nida, passport
            $table->string('id_number')->nullable();
            $table->boolean('is_lead')->default(false);
            $table->timestamps();

            $table->foreign('booking_id')->references('id')->on('transport_bookings')->onDelete('cascade');
        });

        Schema::create('transport_tickets', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('booking_id');
            $table->string('ticket_number')->unique();
            $table->string('qr_data');        // data encoded in QR
            $table->string('status')->default('active'); // active, used, cancelled
            $table->json('boarding_info')->nullable(); // gate, seat, platform, etc.
            $table->timestamps();

            $table->foreign('booking_id')->references('id')->on('transport_bookings')->onDelete('cascade');
        });

        Schema::create('transport_search_cache', function (Blueprint $table) {
            $table->id();
            $table->string('cache_key')->unique(); // origin:destination:date
            $table->json('results');
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transport_search_cache');
        Schema::dropIfExists('transport_tickets');
        Schema::dropIfExists('transport_passengers');
        Schema::dropIfExists('transport_bookings');
        Schema::dropIfExists('transport_inventory');
        Schema::dropIfExists('transport_schedules');
        Schema::dropIfExists('transport_cities');
        Schema::dropIfExists('transport_providers');
    }
};
```

- [ ] **Step 3: Run the migration**

```bash
php artisan migrate
```

Expected: 8 tables created successfully.

- [ ] **Step 4: Verify tables exist**

```bash
php artisan tinker --execute="echo implode(', ', Schema::getTableListing());"
```

Expected: `transport_providers`, `transport_cities`, `transport_schedules`, `transport_inventory`, `transport_bookings`, `transport_passengers`, `transport_tickets`, `transport_search_cache` all present.

---

## Task 2: Backend — Eloquent Models

**Files:**
- Create: `app/Models/Travel/TransportProvider.php`
- Create: `app/Models/Travel/TransportCity.php`
- Create: `app/Models/Travel/TransportSchedule.php`
- Create: `app/Models/Travel/TransportInventory.php`
- Create: `app/Models/Travel/TransportBooking.php`
- Create: `app/Models/Travel/TransportPassenger.php`
- Create: `app/Models/Travel/TransportTicket.php`

- [ ] **Step 1: Create the Travel models directory**

```bash
mkdir -p app/Models/Travel
```

- [ ] **Step 2: Create TransportProvider model**

```php
<?php
// app/Models/Travel/TransportProvider.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;

class TransportProvider extends Model
{
    protected $fillable = ['name', 'code', 'api_base_url', 'is_active', 'config'];

    protected $casts = [
        'is_active' => 'boolean',
        'config' => 'array',
    ];
}
```

- [ ] **Step 3: Create TransportCity model**

```php
<?php
// app/Models/Travel/TransportCity.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;

class TransportCity extends Model
{
    protected $fillable = [
        'name', 'code', 'region', 'country', 'latitude', 'longitude',
        'has_airport', 'has_bus_terminal', 'has_train_station', 'has_ferry_terminal',
        'search_count',
    ];

    protected $casts = [
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'has_airport' => 'boolean',
        'has_bus_terminal' => 'boolean',
        'has_train_station' => 'boolean',
        'has_ferry_terminal' => 'boolean',
    ];
}
```

- [ ] **Step 4: Create TransportSchedule model**

```php
<?php
// app/Models/Travel/TransportSchedule.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TransportSchedule extends Model
{
    protected $fillable = [
        'mode', 'operator', 'operator_code', 'origin_city_id', 'destination_city_id',
        'departure_time', 'arrival_time', 'duration_minutes', 'days_of_week',
        'class', 'price', 'currency', 'seats_total', 'vehicle_info', 'is_active',
    ];

    protected $casts = [
        'days_of_week' => 'array',
        'price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function originCity(): BelongsTo
    {
        return $this->belongsTo(TransportCity::class, 'origin_city_id');
    }

    public function destinationCity(): BelongsTo
    {
        return $this->belongsTo(TransportCity::class, 'destination_city_id');
    }

    public function inventory(): HasMany
    {
        return $this->hasMany(TransportInventory::class, 'schedule_id');
    }

    public function runsOn(int $dayOfWeek): bool
    {
        return in_array($dayOfWeek, $this->days_of_week ?? []);
    }
}
```

- [ ] **Step 5: Create TransportInventory model**

```php
<?php
// app/Models/Travel/TransportInventory.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransportInventory extends Model
{
    protected $table = 'transport_inventory';

    protected $fillable = ['schedule_id', 'date', 'seats_booked', 'status'];

    protected $casts = [
        'date' => 'date',
    ];

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(TransportSchedule::class, 'schedule_id');
    }

    public function seatsAvailable(): int
    {
        return $this->schedule->seats_total - $this->seats_booked;
    }
}
```

- [ ] **Step 6: Create TransportBooking model**

```php
<?php
// app/Models/Travel/TransportBooking.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class TransportBooking extends Model
{
    protected $fillable = [
        'user_id', 'booking_reference', 'provider_code', 'provider_booking_id',
        'mode', 'operator', 'origin_city', 'destination_city',
        'departure', 'arrival', 'duration_minutes', 'class',
        'passenger_count', 'unit_price', 'total_amount', 'currency',
        'status', 'payment_method', 'payment_status', 'payment_phone',
        'option_snapshot',
    ];

    protected $casts = [
        'departure' => 'datetime',
        'arrival' => 'datetime',
        'unit_price' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'option_snapshot' => 'array',
    ];

    public function passengers(): HasMany
    {
        return $this->hasMany(TransportPassenger::class, 'booking_id');
    }

    public function ticket(): HasOne
    {
        return $this->hasOne(TransportTicket::class, 'booking_id');
    }

    public function isUpcoming(): bool
    {
        return $this->departure->isFuture() && $this->status !== 'cancelled';
    }

    public static function generateReference(): string
    {
        return 'TJ-' . strtoupper(substr(md5(uniqid()), 0, 8));
    }
}
```

- [ ] **Step 7: Create TransportPassenger model**

```php
<?php
// app/Models/Travel/TransportPassenger.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransportPassenger extends Model
{
    protected $fillable = ['booking_id', 'name', 'phone', 'id_type', 'id_number', 'is_lead'];

    protected $casts = [
        'is_lead' => 'boolean',
    ];

    public function booking(): BelongsTo
    {
        return $this->belongsTo(TransportBooking::class, 'booking_id');
    }
}
```

- [ ] **Step 8: Create TransportTicket model**

```php
<?php
// app/Models/Travel/TransportTicket.php

namespace App\Models\Travel;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransportTicket extends Model
{
    protected $fillable = ['booking_id', 'ticket_number', 'qr_data', 'status', 'boarding_info'];

    protected $casts = [
        'boarding_info' => 'array',
    ];

    public function booking(): BelongsTo
    {
        return $this->belongsTo(TransportBooking::class, 'booking_id');
    }

    public static function generateTicketNumber(): string
    {
        return 'TKT-' . strtoupper(substr(md5(uniqid()), 0, 10));
    }
}
```

- [ ] **Step 9: Verify models load correctly**

```bash
php artisan tinker --execute="new App\Models\Travel\TransportBooking; echo 'Models OK';"
```

Expected: `Models OK`

---

## Task 3: Backend — City & Schedule Seeders

**Files:**
- Create: `database/seeders/TransportCitySeeder.php`
- Create: `database/seeders/TransportScheduleSeeder.php`

- [ ] **Step 1: Create city seeder with Tanzania + East Africa cities**

```php
<?php
// database/seeders/TransportCitySeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Travel\TransportCity;

class TransportCitySeeder extends Seeder
{
    public function run(): void
    {
        $cities = [
            // Tanzania major cities
            ['name' => 'Dar es Salaam', 'code' => 'DAR', 'region' => 'Dar es Salaam', 'country' => 'TZ', 'latitude' => -6.7924, 'longitude' => 39.2083, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => true],
            ['name' => 'Dodoma', 'code' => 'DOD', 'region' => 'Dodoma', 'country' => 'TZ', 'latitude' => -6.1630, 'longitude' => 35.7516, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Arusha', 'code' => 'ARK', 'region' => 'Arusha', 'country' => 'TZ', 'latitude' => -3.3869, 'longitude' => 36.6830, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Mwanza', 'code' => 'MWZ', 'region' => 'Mwanza', 'country' => 'TZ', 'latitude' => -2.5164, 'longitude' => 32.9175, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => true],
            ['name' => 'Mbeya', 'code' => 'MBY', 'region' => 'Mbeya', 'country' => 'TZ', 'latitude' => -8.9000, 'longitude' => 33.4500, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Morogoro', 'code' => 'MOR', 'region' => 'Morogoro', 'country' => 'TZ', 'latitude' => -6.8235, 'longitude' => 37.6614, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Tanga', 'code' => 'TGT', 'region' => 'Tanga', 'country' => 'TZ', 'latitude' => -5.0689, 'longitude' => 39.0985, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Zanzibar', 'code' => 'ZNZ', 'region' => 'Zanzibar', 'country' => 'TZ', 'latitude' => -6.1659, 'longitude' => 39.2026, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Moshi', 'code' => 'MSH', 'region' => 'Kilimanjaro', 'country' => 'TZ', 'latitude' => -3.3353, 'longitude' => 37.3408, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Iringa', 'code' => 'IRI', 'region' => 'Iringa', 'country' => 'TZ', 'latitude' => -7.7700, 'longitude' => 35.6900, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Kigoma', 'code' => 'TKQ', 'region' => 'Kigoma', 'country' => 'TZ', 'latitude' => -4.8769, 'longitude' => 29.6266, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => true],
            ['name' => 'Tabora', 'code' => 'TBO', 'region' => 'Tabora', 'country' => 'TZ', 'latitude' => -5.0167, 'longitude' => 32.8000, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Songea', 'code' => 'SGX', 'region' => 'Ruvuma', 'country' => 'TZ', 'latitude' => -10.6816, 'longitude' => 35.6500, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Lindi', 'code' => 'LDI', 'region' => 'Lindi', 'country' => 'TZ', 'latitude' => -9.9991, 'longitude' => 39.7141, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Mtwara', 'code' => 'MYW', 'region' => 'Mtwara', 'country' => 'TZ', 'latitude' => -10.3390, 'longitude' => 40.1749, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Singida', 'code' => 'SID', 'region' => 'Singida', 'country' => 'TZ', 'latitude' => -4.8163, 'longitude' => 34.7438, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Shinyanga', 'code' => 'SHY', 'region' => 'Shinyanga', 'country' => 'TZ', 'latitude' => -3.6614, 'longitude' => 33.4213, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Bukoba', 'code' => 'BKZ', 'region' => 'Kagera', 'country' => 'TZ', 'latitude' => -1.3317, 'longitude' => 31.8125, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Musoma', 'code' => 'MUZ', 'region' => 'Mara', 'country' => 'TZ', 'latitude' => -1.4997, 'longitude' => 33.8021, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Pemba', 'code' => 'PMA', 'region' => 'Pemba', 'country' => 'TZ', 'latitude' => -5.2295, 'longitude' => 39.8107, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Sumbawanga', 'code' => 'SUT', 'region' => 'Rukwa', 'country' => 'TZ', 'latitude' => -7.9667, 'longitude' => 31.6167, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Mpanda', 'code' => 'MPD', 'region' => 'Katavi', 'country' => 'TZ', 'latitude' => -6.3500, 'longitude' => 31.0667, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Babati', 'code' => 'BBT', 'region' => 'Manyara', 'country' => 'TZ', 'latitude' => -4.2131, 'longitude' => 35.7467, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Njombe', 'code' => 'NJO', 'region' => 'Njombe', 'country' => 'TZ', 'latitude' => -9.3379, 'longitude' => 34.7761, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Geita', 'code' => 'GIT', 'region' => 'Geita', 'country' => 'TZ', 'latitude' => -2.8714, 'longitude' => 32.2311, 'has_airport' => false, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Kilimanjaro', 'code' => 'JRO', 'region' => 'Kilimanjaro', 'country' => 'TZ', 'latitude' => -3.4294, 'longitude' => 37.0742, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => false],

            // East Africa cross-border
            ['name' => 'Nairobi', 'code' => 'NBO', 'region' => 'Nairobi', 'country' => 'KE', 'latitude' => -1.2921, 'longitude' => 36.8219, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Mombasa', 'code' => 'MBA', 'region' => 'Coast', 'country' => 'KE', 'latitude' => -4.0435, 'longitude' => 39.6682, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => true],
            ['name' => 'Kampala', 'code' => 'KLA', 'region' => 'Central', 'country' => 'UG', 'latitude' => 0.3476, 'longitude' => 32.5825, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Kigali', 'code' => 'KGL', 'region' => 'Kigali', 'country' => 'RW', 'latitude' => -1.9403, 'longitude' => 29.8739, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Bujumbura', 'code' => 'BJM', 'region' => 'Bujumbura Mairie', 'country' => 'BI', 'latitude' => -3.3614, 'longitude' => 29.3599, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => true],
            ['name' => 'Lusaka', 'code' => 'LUN', 'region' => 'Lusaka', 'country' => 'ZM', 'latitude' => -15.3875, 'longitude' => 28.3228, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Lilongwe', 'code' => 'LLW', 'region' => 'Central', 'country' => 'MW', 'latitude' => -13.9626, 'longitude' => 33.7741, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],

            // International hubs
            ['name' => 'Dubai', 'code' => 'DXB', 'region' => 'Dubai', 'country' => 'AE', 'latitude' => 25.2048, 'longitude' => 55.2708, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Johannesburg', 'code' => 'JNB', 'region' => 'Gauteng', 'country' => 'ZA', 'latitude' => -26.2041, 'longitude' => 28.0473, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => true, 'has_ferry_terminal' => false],
            ['name' => 'Addis Ababa', 'code' => 'ADD', 'region' => 'Addis Ababa', 'country' => 'ET', 'latitude' => 9.0250, 'longitude' => 38.7469, 'has_airport' => true, 'has_bus_terminal' => true, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Mumbai', 'code' => 'BOM', 'region' => 'Maharashtra', 'country' => 'IN', 'latitude' => 19.0760, 'longitude' => 72.8777, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'Istanbul', 'code' => 'IST', 'region' => 'Istanbul', 'country' => 'TR', 'latitude' => 41.0082, 'longitude' => 28.9784, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => false],
            ['name' => 'London', 'code' => 'LHR', 'region' => 'England', 'country' => 'GB', 'latitude' => 51.5074, 'longitude' => -0.1278, 'has_airport' => true, 'has_bus_terminal' => false, 'has_train_station' => false, 'has_ferry_terminal' => false],
        ];

        foreach ($cities as $city) {
            TransportCity::updateOrCreate(['code' => $city['code']], $city);
        }
    }
}
```

- [ ] **Step 2: Create schedule seeder with SGR and ferry data**

```php
<?php
// database/seeders/TransportScheduleSeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Travel\TransportCity;
use App\Models\Travel\TransportSchedule;

class TransportScheduleSeeder extends Seeder
{
    public function run(): void
    {
        $dar = TransportCity::where('code', 'DAR')->first()->id;
        $mor = TransportCity::where('code', 'MOR')->first()->id;
        $dod = TransportCity::where('code', 'DOD')->first()->id;
        $znz = TransportCity::where('code', 'ZNZ')->first()->id;
        $pma = TransportCity::where('code', 'PMA')->first()->id;
        $tgt = TransportCity::where('code', 'TGT')->first()->id;

        $schedules = [
            // SGR Express: Dar → Dodoma
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $dar, 'destination_city_id' => $dod, 'departure_time' => '06:00', 'arrival_time' => '09:42', 'duration_minutes' => 222, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 12000, 'currency' => 'TZS', 'seats_total' => 500, 'vehicle_info' => 'SGR Express'],
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $dar, 'destination_city_id' => $dod, 'departure_time' => '06:00', 'arrival_time' => '09:42', 'duration_minutes' => 222, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'business', 'price' => 23000, 'currency' => 'TZS', 'seats_total' => 100, 'vehicle_info' => 'SGR Express'],

            // SGR Express: Dodoma → Dar
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $dod, 'destination_city_id' => $dar, 'departure_time' => '14:00', 'arrival_time' => '17:42', 'duration_minutes' => 222, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 12000, 'currency' => 'TZS', 'seats_total' => 500, 'vehicle_info' => 'SGR Express'],
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $dod, 'destination_city_id' => $dar, 'departure_time' => '14:00', 'arrival_time' => '17:42', 'duration_minutes' => 222, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'business', 'price' => 23000, 'currency' => 'TZS', 'seats_total' => 100, 'vehicle_info' => 'SGR Express'],

            // SGR EMU: Dar → Morogoro
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $dar, 'destination_city_id' => $mor, 'departure_time' => '08:00', 'arrival_time' => '10:30', 'duration_minutes' => 150, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 7000, 'currency' => 'TZS', 'seats_total' => 600, 'vehicle_info' => 'SGR EMU Mchongoko'],
            ['mode' => 'train', 'operator' => 'SGR', 'operator_code' => 'SGR', 'origin_city_id' => $mor, 'destination_city_id' => $dar, 'departure_time' => '15:00', 'arrival_time' => '17:30', 'duration_minutes' => 150, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 7000, 'currency' => 'TZS', 'seats_total' => 600, 'vehicle_info' => 'SGR EMU Mchongoko'],

            // Azam Marine: Dar → Zanzibar
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $dar, 'destination_city_id' => $znz, 'departure_time' => '07:00', 'arrival_time' => '08:45', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro VI'],
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $dar, 'destination_city_id' => $znz, 'departure_time' => '07:00', 'arrival_time' => '08:45', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'vip', 'price' => 60000, 'currency' => 'TZS', 'seats_total' => 80, 'vehicle_info' => 'Kilimanjaro VI'],
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $dar, 'destination_city_id' => $znz, 'departure_time' => '12:30', 'arrival_time' => '14:15', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro VII'],
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $dar, 'destination_city_id' => $znz, 'departure_time' => '15:30', 'arrival_time' => '17:15', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro V'],

            // Azam Marine: Zanzibar → Dar
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $znz, 'destination_city_id' => $dar, 'departure_time' => '07:00', 'arrival_time' => '08:45', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro VI'],
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $znz, 'destination_city_id' => $dar, 'departure_time' => '10:00', 'arrival_time' => '11:45', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro VII'],
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $znz, 'destination_city_id' => $dar, 'departure_time' => '16:00', 'arrival_time' => '17:45', 'duration_minutes' => 105, 'days_of_week' => [1,2,3,4,5,6,7], 'class' => 'economy', 'price' => 40000, 'currency' => 'TZS', 'seats_total' => 400, 'vehicle_info' => 'Kilimanjaro V'],

            // Azam Marine: Dar → Pemba (via Zanzibar)
            ['mode' => 'ferry', 'operator' => 'Azam Marine', 'operator_code' => 'AZAM', 'origin_city_id' => $dar, 'destination_city_id' => $pma, 'departure_time' => '07:00', 'arrival_time' => '11:30', 'duration_minutes' => 270, 'days_of_week' => [1,3,5], 'class' => 'economy', 'price' => 85000, 'currency' => 'TZS', 'seats_total' => 200, 'vehicle_info' => 'Kilimanjaro IV'],
        ];

        foreach ($schedules as $schedule) {
            TransportSchedule::create($schedule);
        }
    }
}
```

- [ ] **Step 3: Run the seeders**

```bash
php artisan db:seed --class=TransportCitySeeder
php artisan db:seed --class=TransportScheduleSeeder
```

- [ ] **Step 4: Verify seeded data**

```bash
php artisan tinker --execute="echo 'Cities: ' . App\Models\Travel\TransportCity::count() . ', Schedules: ' . App\Models\Travel\TransportSchedule::count();"
```

Expected: `Cities: 39, Schedules: 17` (approximately)

---

## Task 4: Backend — Internal Provider & Search Service

**Files:**
- Create: `app/Services/Travel/Providers/TransportProviderInterface.php`
- Create: `app/Services/Travel/Providers/InternalProvider.php`
- Create: `app/Services/Travel/TravelSearchService.php`

- [ ] **Step 1: Create Travel services directory structure**

```bash
mkdir -p app/Services/Travel/Providers
```

- [ ] **Step 2: Create the provider interface**

```php
<?php
// app/Services/Travel/Providers/TransportProviderInterface.php

namespace App\Services\Travel\Providers;

use Illuminate\Support\Collection;

interface TransportProviderInterface
{
    /**
     * Search for transport options.
     *
     * @param string $originCode    City code (e.g., 'DAR')
     * @param string $destCode      City code (e.g., 'ZNZ')
     * @param string $date          Date string 'Y-m-d'
     * @param int    $passengers    Number of passengers
     * @return Collection           Collection of associative arrays (TransportOption shape)
     */
    public function search(string $originCode, string $destCode, string $date, int $passengers): Collection;

    /**
     * Get the provider code identifier.
     */
    public function code(): string;
}
```

- [ ] **Step 3: Create the InternalProvider (SGR trains + ferries from our DB)**

```php
<?php
// app/Services/Travel/Providers/InternalProvider.php

namespace App\Services\Travel\Providers;

use App\Models\Travel\TransportCity;
use App\Models\Travel\TransportSchedule;
use App\Models\Travel\TransportInventory;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class InternalProvider implements TransportProviderInterface
{
    public function code(): string
    {
        return 'internal';
    }

    public function search(string $originCode, string $destCode, string $date, int $passengers): Collection
    {
        $origin = TransportCity::where('code', $originCode)->first();
        $dest = TransportCity::where('code', $destCode)->first();

        if (!$origin || !$dest) {
            return collect();
        }

        $dateObj = Carbon::parse($date);
        $dayOfWeek = $dateObj->dayOfWeekIso; // 1=Mon ... 7=Sun

        $schedules = TransportSchedule::where('origin_city_id', $origin->id)
            ->where('destination_city_id', $dest->id)
            ->where('is_active', true)
            ->get()
            ->filter(fn ($s) => $s->runsOn($dayOfWeek));

        return $schedules->map(function (TransportSchedule $schedule) use ($origin, $dest, $dateObj, $passengers) {
            // Check or create inventory for this date
            $inventory = TransportInventory::firstOrCreate(
                ['schedule_id' => $schedule->id, 'date' => $dateObj->toDateString()],
                ['seats_booked' => 0, 'status' => 'available']
            );

            $seatsAvailable = $schedule->seats_total - $inventory->seats_booked;
            if ($seatsAvailable < $passengers || $inventory->status !== 'available') {
                return null;
            }

            $departure = $dateObj->copy()->setTimeFromTimeString($schedule->departure_time);
            $arrival = $dateObj->copy()->setTimeFromTimeString($schedule->arrival_time);
            // Handle overnight arrivals
            if ($arrival->lt($departure)) {
                $arrival->addDay();
            }

            return [
                'id' => 'int_' . $schedule->id . '_' . $dateObj->format('Ymd'),
                'mode' => $schedule->mode,
                'operator' => [
                    'name' => $schedule->operator,
                    'code' => $schedule->operator_code,
                    'logo' => null,
                ],
                'origin' => [
                    'city' => $origin->name,
                    'station' => $schedule->mode === 'train' ? $origin->name . ' Station' : $origin->name . ' Terminal',
                    'code' => $origin->code,
                ],
                'destination' => [
                    'city' => $dest->name,
                    'station' => $schedule->mode === 'train' ? $dest->name . ' Station' : $dest->name . ' Terminal',
                    'code' => $dest->code,
                ],
                'departure' => $departure->toIso8601String(),
                'arrival' => $arrival->toIso8601String(),
                'duration' => $schedule->duration_minutes,
                'price' => [
                    'amount' => (float) $schedule->price,
                    'currency' => $schedule->currency,
                ],
                'class' => $schedule->class,
                'seats_available' => $seatsAvailable,
                'provider' => 'internal',
                'schedule_id' => $schedule->id,
                'vehicle_info' => $schedule->vehicle_info,
            ];
        })->filter()->values();
    }
}
```

- [ ] **Step 4: Create the TravelSearchService orchestrator**

```php
<?php
// app/Services/Travel/TravelSearchService.php

namespace App\Services\Travel;

use App\Services\Travel\Providers\TransportProviderInterface;
use App\Services\Travel\Providers\InternalProvider;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

class TravelSearchService
{
    /** @var TransportProviderInterface[] */
    protected array $providers;

    public function __construct()
    {
        $this->providers = [
            new InternalProvider(),
            // Future: new OtappProvider(), new AmadeusProvider(), new BuuPassProvider()
        ];
    }

    public function search(string $originCode, string $destCode, string $date, int $passengers, ?string $preferredMode = null): Collection
    {
        $cacheKey = "transport_search:{$originCode}:{$destCode}:{$date}:{$passengers}";

        return Cache::remember($cacheKey, now()->addMinutes(15), function () use ($originCode, $destCode, $date, $passengers, $preferredMode) {
            $results = collect();

            foreach ($this->providers as $provider) {
                try {
                    $providerResults = $provider->search($originCode, $destCode, $date, $passengers);
                    $results = $results->merge($providerResults);
                } catch (\Exception $e) {
                    \Log::warning("Transport provider {$provider->code()} failed: " . $e->getMessage());
                }
            }

            // Filter by preferred mode if specified
            if ($preferredMode) {
                $results = $results->filter(fn ($r) => $r['mode'] === $preferredMode);
            }

            // Sort by price ascending
            return $results->sortBy(fn ($r) => $r['price']['amount'])->values();
        });
    }

    public function getOption(string $optionId): ?array
    {
        // For internal options, parse the ID and fetch from schedule
        if (str_starts_with($optionId, 'int_')) {
            $parts = explode('_', $optionId);
            if (count($parts) >= 3) {
                $scheduleId = $parts[1];
                $dateStr = substr($parts[2], 0, 4) . '-' . substr($parts[2], 4, 2) . '-' . substr($parts[2], 6, 2);
                $provider = new InternalProvider();
                $schedule = \App\Models\Travel\TransportSchedule::with(['originCity', 'destinationCity'])->find($scheduleId);
                if ($schedule) {
                    $results = $provider->search(
                        $schedule->originCity->code,
                        $schedule->destinationCity->code,
                        $dateStr,
                        1
                    );
                    return $results->firstWhere('id', $optionId);
                }
            }
        }
        return null;
    }

    public function clearCache(string $originCode, string $destCode, string $date): void
    {
        $pattern = "transport_search:{$originCode}:{$destCode}:{$date}:*";
        // Simple approach: clear specific known passenger counts
        for ($p = 1; $p <= 9; $p++) {
            Cache::forget("transport_search:{$originCode}:{$destCode}:{$date}:{$p}");
        }
    }
}
```

- [ ] **Step 5: Verify the services work via tinker**

```bash
php artisan tinker --execute="
    \$s = new App\Services\Travel\TravelSearchService();
    \$r = \$s->search('DAR', 'DOD', date('Y-m-d', strtotime('+1 day')), 1);
    echo 'Results: ' . \$r->count();
"
```

Expected: `Results: 2` (economy + business SGR Express)

---

## Task 5: Backend — Controllers & Routes

**Files:**
- Create: `app/Http/Controllers/Api/TransportSearchController.php`
- Create: `app/Http/Controllers/Api/TransportBookingController.php`
- Create: `app/Http/Controllers/Api/TransportTicketController.php`
- Modify: `routes/api.php`

- [ ] **Step 1: Create TransportSearchController**

```php
<?php
// app/Http/Controllers/Api/TransportSearchController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Travel\TransportCity;
use App\Services\Travel\TravelSearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class TransportSearchController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'origin' => 'required|string',
            'destination' => 'required|string',
            'date' => 'required|date|after_or_equal:today',
            'passengers' => 'integer|min:1|max:9',
            'preferred_mode' => 'nullable|string|in:bus,flight,train,ferry',
        ]);

        $service = new TravelSearchService();
        $results = $service->search(
            $request->origin,
            $request->destination,
            $request->date,
            $request->integer('passengers', 1),
            $request->preferred_mode,
        );

        // Increment search count for cities
        TransportCity::where('code', $request->origin)->increment('search_count');
        TransportCity::where('code', $request->destination)->increment('search_count');

        return response()->json([
            'success' => true,
            'data' => $results->all(),
        ]);
    }

    public function option(string $id): JsonResponse
    {
        $service = new TravelSearchService();
        $option = $service->getOption($id);

        if (!$option) {
            return response()->json([
                'success' => false,
                'message' => 'Transport option not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $option,
        ]);
    }

    public function cities(Request $request): JsonResponse
    {
        $query = TransportCity::query();

        if ($request->has('q') && strlen($request->q) >= 1) {
            $query->where('name', 'ilike', '%' . $request->q . '%');
        }

        $cities = $query->orderByRaw("country = 'TZ' DESC")
            ->orderBy('search_count', 'desc')
            ->orderBy('name')
            ->limit(30)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $cities,
        ]);
    }

    public function popularRoutes(): JsonResponse
    {
        // Top routes based on city search counts
        $cities = TransportCity::where('search_count', '>', 0)
            ->orderBy('search_count', 'desc')
            ->limit(10)
            ->get();

        $routes = [];
        $dar = TransportCity::where('code', 'DAR')->first();
        if ($dar) {
            foreach ($cities->take(6) as $city) {
                if ($city->code === 'DAR') continue;
                $routes[] = [
                    'origin' => ['name' => $dar->name, 'code' => $dar->code],
                    'destination' => ['name' => $city->name, 'code' => $city->code],
                    'modes' => array_filter([
                        $city->has_bus_terminal ? 'bus' : null,
                        $city->has_airport ? 'flight' : null,
                        $city->has_train_station ? 'train' : null,
                        $city->has_ferry_terminal ? 'ferry' : null,
                    ]),
                ];
            }
        }

        return response()->json([
            'success' => true,
            'data' => $routes,
        ]);
    }

    public function weather(string $code): JsonResponse
    {
        $city = TransportCity::where('code', $code)->first();
        if (!$city) {
            return response()->json(['success' => false, 'message' => 'City not found'], 404);
        }

        $apiKey = config('services.weather.key', env('WEATHER_API_KEY'));
        if (!$apiKey) {
            return response()->json(['success' => false, 'message' => 'Weather service not configured'], 503);
        }

        try {
            $response = Http::get("https://api.weatherapi.com/v1/current.json", [
                'key' => $apiKey,
                'q' => "{$city->latitude},{$city->longitude}",
            ]);

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'data' => $response->json(),
                ]);
            }
        } catch (\Exception $e) {
            \Log::warning("Weather API failed for {$code}: " . $e->getMessage());
        }

        return response()->json(['success' => false, 'message' => 'Weather data unavailable'], 503);
    }
}
```

- [ ] **Step 2: Create TransportBookingController**

```php
<?php
// app/Http/Controllers/Api/TransportBookingController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Travel\TransportBooking;
use App\Models\Travel\TransportPassenger;
use App\Models\Travel\TransportTicket;
use App\Models\Travel\TransportInventory;
use App\Services\Travel\TravelSearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransportBookingController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'option_id' => 'required|string',
            'passengers' => 'required|array|min:1|max:9',
            'passengers.*.name' => 'required|string',
            'passengers.*.phone' => 'nullable|string',
            'passengers.*.id_type' => 'nullable|string|in:nida,passport',
            'passengers.*.id_number' => 'nullable|string',
            'payment_method' => 'required|string|in:wallet,mpesa,tigopesa,airtelmoney',
            'payment_phone' => 'nullable|string',
            'user_id' => 'required|integer',
        ]);

        // Fetch the transport option
        $service = new TravelSearchService();
        $option = $service->getOption($request->option_id);

        if (!$option) {
            return response()->json([
                'success' => false,
                'message' => 'Chaguo la usafiri halipo tena. Tafadhali tafuta upya.',
            ], 404);
        }

        $passengerCount = count($request->passengers);

        // Check seat availability
        if (isset($option['seats_available']) && $option['seats_available'] < $passengerCount) {
            return response()->json([
                'success' => false,
                'message' => 'Viti havitoshi. Viti vilivyobaki: ' . $option['seats_available'],
            ], 422);
        }

        // Create booking
        $booking = TransportBooking::create([
            'user_id' => $request->user_id,
            'booking_reference' => TransportBooking::generateReference(),
            'provider_code' => $option['provider'],
            'mode' => $option['mode'],
            'operator' => $option['operator']['name'],
            'origin_city' => $option['origin']['city'],
            'destination_city' => $option['destination']['city'],
            'departure' => $option['departure'],
            'arrival' => $option['arrival'],
            'duration_minutes' => $option['duration'],
            'class' => $option['class'] ?? null,
            'passenger_count' => $passengerCount,
            'unit_price' => $option['price']['amount'],
            'total_amount' => $option['price']['amount'] * $passengerCount,
            'currency' => $option['price']['currency'] ?? 'TZS',
            'status' => 'confirmed', // simplified: skip payment flow for now
            'payment_method' => $request->payment_method,
            'payment_status' => 'paid', // simplified
            'payment_phone' => $request->payment_phone,
            'option_snapshot' => $option,
        ]);

        // Create passengers
        foreach ($request->passengers as $i => $pax) {
            TransportPassenger::create([
                'booking_id' => $booking->id,
                'name' => $pax['name'],
                'phone' => $pax['phone'] ?? null,
                'id_type' => $pax['id_type'] ?? null,
                'id_number' => $pax['id_number'] ?? null,
                'is_lead' => $i === 0,
            ]);
        }

        // Update inventory for internal bookings
        if ($option['provider'] === 'internal' && isset($option['schedule_id'])) {
            $dateStr = date('Y-m-d', strtotime($option['departure']));
            TransportInventory::where('schedule_id', $option['schedule_id'])
                ->where('date', $dateStr)
                ->increment('seats_booked', $passengerCount);

            // Clear search cache for this route/date
            $service->clearCache(
                $option['origin']['code'],
                $option['destination']['code'],
                $dateStr
            );
        }

        // Generate ticket
        $ticket = TransportTicket::create([
            'booking_id' => $booking->id,
            'ticket_number' => TransportTicket::generateTicketNumber(),
            'qr_data' => json_encode([
                'ref' => $booking->booking_reference,
                'route' => $booking->origin_city . ' → ' . $booking->destination_city,
                'date' => $booking->departure->format('Y-m-d H:i'),
                'pax' => $passengerCount,
            ]),
            'status' => 'active',
            'boarding_info' => [
                'operator' => $booking->operator,
                'class' => $booking->class,
                'vehicle' => $option['vehicle_info'] ?? null,
            ],
        ]);

        $booking->load(['passengers', 'ticket']);

        return response()->json([
            'success' => true,
            'data' => $booking,
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $bookings = TransportBooking::where('user_id', $request->user_id)
            ->with(['passengers', 'ticket'])
            ->orderBy('departure', 'desc')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $bookings->items(),
            'meta' => [
                'total' => $bookings->total(),
                'current_page' => $bookings->currentPage(),
                'last_page' => $bookings->lastPage(),
            ],
        ]);
    }

    public function cancel(int $id): JsonResponse
    {
        $booking = TransportBooking::find($id);

        if (!$booking) {
            return response()->json(['success' => false, 'message' => 'Booking not found'], 404);
        }

        if ($booking->status === 'cancelled') {
            return response()->json(['success' => false, 'message' => 'Tayari imeghairiwa'], 422);
        }

        if ($booking->departure->isPast()) {
            return response()->json(['success' => false, 'message' => 'Haiwezekani kughairi safari iliyopita'], 422);
        }

        // Restore inventory for internal bookings
        if ($booking->provider_code === 'internal') {
            $snapshot = $booking->option_snapshot;
            if (isset($snapshot['schedule_id'])) {
                TransportInventory::where('schedule_id', $snapshot['schedule_id'])
                    ->where('date', $booking->departure->format('Y-m-d'))
                    ->decrement('seats_booked', $booking->passenger_count);
            }
        }

        $booking->update([
            'status' => 'cancelled',
            'payment_status' => 'refunded',
        ]);

        if ($booking->ticket) {
            $booking->ticket->update(['status' => 'cancelled']);
        }

        $booking->load(['passengers', 'ticket']);

        return response()->json([
            'success' => true,
            'data' => $booking,
        ]);
    }
}
```

- [ ] **Step 3: Create TransportTicketController**

```php
<?php
// app/Http/Controllers/Api/TransportTicketController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Travel\TransportTicket;
use Illuminate\Http\JsonResponse;

class TransportTicketController extends Controller
{
    public function show(int $bookingId): JsonResponse
    {
        $ticket = TransportTicket::where('booking_id', $bookingId)
            ->with(['booking.passengers'])
            ->first();

        if (!$ticket) {
            return response()->json(['success' => false, 'message' => 'Ticket not found'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $ticket,
        ]);
    }
}
```

- [ ] **Step 4: Add routes to `routes/api.php`**

Append at the end of the file:

```php
// Transport (new travel module)
Route::prefix('transport')->group(function () {
    Route::post('/search', [App\Http\Controllers\Api\TransportSearchController::class, 'search']);
    Route::get('/option/{id}', [App\Http\Controllers\Api\TransportSearchController::class, 'option']);
    Route::get('/cities', [App\Http\Controllers\Api\TransportSearchController::class, 'cities']);
    Route::get('/popular-routes', [App\Http\Controllers\Api\TransportSearchController::class, 'popularRoutes']);
    Route::get('/cities/{code}/weather', [App\Http\Controllers\Api\TransportSearchController::class, 'weather']);

    Route::post('/bookings', [App\Http\Controllers\Api\TransportBookingController::class, 'store']);
    Route::get('/bookings', [App\Http\Controllers\Api\TransportBookingController::class, 'index']);
    Route::post('/bookings/{id}/cancel', [App\Http\Controllers\Api\TransportBookingController::class, 'cancel']);

    Route::get('/tickets/{bookingId}', [App\Http\Controllers\Api\TransportTicketController::class, 'show']);
});
```

- [ ] **Step 5: Verify routes are registered**

```bash
php artisan route:list --path=transport
```

Expected: 9 routes listed under `/api/transport/*`

- [ ] **Step 6: Test search endpoint with curl**

```bash
curl -s -X POST http://localhost/api/transport/search \
  -H 'Content-Type: application/json' \
  -d '{"origin":"DAR","destination":"DOD","date":"'$(date -d "+1 day" +%Y-%m-%d)'","passengers":1}' | python3 -m json.tool | head -20
```

Expected: JSON with `success: true` and SGR results in `data` array.

---

## Task 6: Frontend — Models & Enums

**Files:**
- Create: `lib/travel/models/travel_models.dart` (replace existing)

- [ ] **Step 1: Write the complete models file**

```dart
// lib/travel/models/travel_models.dart

// ─── Enums ────────────────────────────────────────────────────

enum TransportMode {
  bus, flight, train, ferry;

  String get displayName {
    switch (this) {
      case TransportMode.bus: return 'Basi';
      case TransportMode.flight: return 'Ndege';
      case TransportMode.train: return 'Treni';
      case TransportMode.ferry: return 'Feri';
    }
  }

  String get subtitle {
    switch (this) {
      case TransportMode.bus: return 'Bus';
      case TransportMode.flight: return 'Flight';
      case TransportMode.train: return 'Train';
      case TransportMode.ferry: return 'Ferry';
    }
  }

  static TransportMode fromString(String? s) {
    final v = s?.toLowerCase() ?? '';
    for (final m in TransportMode.values) {
      if (m.name == v) return m;
    }
    return TransportMode.bus;
  }
}

enum BookingStatus {
  pending, confirmed, cancelled, completed;

  String get displayName {
    switch (this) {
      case BookingStatus.pending: return 'Inasubiri';
      case BookingStatus.confirmed: return 'Imethibitishwa';
      case BookingStatus.cancelled: return 'Imeghairiwa';
      case BookingStatus.completed: return 'Imekamilika';
    }
  }

  static BookingStatus fromString(String? s) {
    final v = s?.toLowerCase() ?? '';
    for (final b in BookingStatus.values) {
      if (b.name == v) return b;
    }
    return BookingStatus.pending;
  }
}

enum PaymentMethod {
  wallet, mpesa, tigopesa, airtelmoney;

  String get displayName {
    switch (this) {
      case PaymentMethod.wallet: return 'TAJIRI Wallet';
      case PaymentMethod.mpesa: return 'M-Pesa';
      case PaymentMethod.tigopesa: return 'Tigo Pesa';
      case PaymentMethod.airtelmoney: return 'Airtel Money';
    }
  }
}

// ─── Models ───────────────────────────────────────────────────

class TransportOperator {
  final String name;
  final String? code;
  final String? logo;

  const TransportOperator({required this.name, this.code, this.logo});

  factory TransportOperator.fromJson(Map<String, dynamic> json) {
    return TransportOperator(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

class TransportStop {
  final String city;
  final String? station;
  final String code;

  const TransportStop({required this.city, this.station, required this.code});

  factory TransportStop.fromJson(Map<String, dynamic> json) {
    return TransportStop(
      city: json['city']?.toString() ?? '',
      station: json['station']?.toString(),
      code: json['code']?.toString() ?? '',
    );
  }
}

class TransportPrice {
  final double amount;
  final String currency;

  const TransportPrice({required this.amount, this.currency = 'TZS'});

  factory TransportPrice.fromJson(Map<String, dynamic> json) {
    return TransportPrice(
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
    );
  }

  String get formatted {
    if (amount >= 1000) {
      return '${currency} ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    }
    return '$currency ${amount.toStringAsFixed(0)}';
  }
}

class TransportOption {
  final String id;
  final TransportMode mode;
  final TransportOperator operator;
  final TransportStop origin;
  final TransportStop destination;
  final DateTime departure;
  final DateTime arrival;
  final int duration; // minutes
  final TransportPrice price;
  final String? transportClass;
  final int seatsAvailable;
  final String provider;

  // Mode-specific
  final String? flightNumber;
  final int? stops;
  final int? baggageKg;
  final String? busType;
  final List<String> amenities;
  final String? trainNumber;
  final String? trainType;
  final String? vesselName;
  final String? vehicleInfo;

  const TransportOption({
    required this.id,
    required this.mode,
    required this.operator,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    this.transportClass,
    this.seatsAvailable = 0,
    this.provider = '',
    this.flightNumber,
    this.stops,
    this.baggageKg,
    this.busType,
    this.amenities = const [],
    this.trainNumber,
    this.trainType,
    this.vesselName,
    this.vehicleInfo,
  });

  String get durationFormatted {
    final h = duration ~/ 60;
    final m = duration % 60;
    if (h == 0) return '${m}dk';
    if (m == 0) return '${h}sa';
    return '${h}sa ${m}dk';
  }

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      id: json['id']?.toString() ?? '',
      mode: TransportMode.fromString(json['mode']?.toString()),
      operator: TransportOperator.fromJson(json['operator'] as Map<String, dynamic>? ?? {}),
      origin: TransportStop.fromJson(json['origin'] as Map<String, dynamic>? ?? {}),
      destination: TransportStop.fromJson(json['destination'] as Map<String, dynamic>? ?? {}),
      departure: DateTime.tryParse(json['departure']?.toString() ?? '') ?? DateTime.now(),
      arrival: DateTime.tryParse(json['arrival']?.toString() ?? '') ?? DateTime.now(),
      duration: _parseInt(json['duration']),
      price: TransportPrice.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
      transportClass: json['class']?.toString(),
      seatsAvailable: _parseInt(json['seats_available']),
      provider: json['provider']?.toString() ?? '',
      flightNumber: json['flight_number']?.toString(),
      stops: json['stops'] != null ? _parseInt(json['stops']) : null,
      baggageKg: json['baggage_kg'] != null ? _parseInt(json['baggage_kg']) : null,
      busType: json['bus_type']?.toString(),
      amenities: _parseStringList(json['amenities']),
      trainNumber: json['train_number']?.toString(),
      trainType: json['train_type']?.toString(),
      vesselName: json['vessel_name']?.toString(),
      vehicleInfo: json['vehicle_info']?.toString(),
    );
  }
}

class City {
  final int id;
  final String name;
  final String code;
  final String? region;
  final String country;
  final bool hasAirport;
  final bool hasBusTerminal;
  final bool hasTrainStation;
  final bool hasFerryTerminal;

  const City({
    required this.id,
    required this.name,
    required this.code,
    this.region,
    this.country = 'TZ',
    this.hasAirport = false,
    this.hasBusTerminal = false,
    this.hasTrainStation = false,
    this.hasFerryTerminal = false,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      region: json['region']?.toString(),
      country: json['country']?.toString() ?? 'TZ',
      hasAirport: _parseBool(json['has_airport']),
      hasBusTerminal: _parseBool(json['has_bus_terminal']),
      hasTrainStation: _parseBool(json['has_train_station']),
      hasFerryTerminal: _parseBool(json['has_ferry_terminal']),
    );
  }
}

class PopularRoute {
  final TransportStop origin;
  final TransportStop destination;
  final List<String> modes;

  const PopularRoute({required this.origin, required this.destination, this.modes = const []});

  factory PopularRoute.fromJson(Map<String, dynamic> json) {
    return PopularRoute(
      origin: TransportStop.fromJson(json['origin'] as Map<String, dynamic>? ?? {}),
      destination: TransportStop.fromJson(json['destination'] as Map<String, dynamic>? ?? {}),
      modes: _parseStringList(json['modes']),
    );
  }
}

class Passenger {
  String name;
  String? phone;
  String? idType;  // nida, passport
  String? idNumber;

  Passenger({this.name = '', this.phone, this.idType, this.idNumber});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (idType != null) 'id_type': idType,
    if (idNumber != null && idNumber!.isNotEmpty) 'id_number': idNumber,
  };
}

class TransportBooking {
  final int id;
  final int userId;
  final String bookingReference;
  final String providerCode;
  final TransportMode mode;
  final String operator;
  final String originCity;
  final String destinationCity;
  final DateTime departure;
  final DateTime arrival;
  final int durationMinutes;
  final String? transportClass;
  final int passengerCount;
  final double unitPrice;
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final String? paymentMethod;
  final String? paymentStatus;
  final List<TransportPassenger> passengers;
  final TransportTicket? ticket;

  const TransportBooking({
    required this.id,
    required this.userId,
    required this.bookingReference,
    required this.providerCode,
    required this.mode,
    required this.operator,
    required this.originCity,
    required this.destinationCity,
    required this.departure,
    required this.arrival,
    required this.durationMinutes,
    this.transportClass,
    required this.passengerCount,
    required this.unitPrice,
    required this.totalAmount,
    this.currency = 'TZS',
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.passengers = const [],
    this.ticket,
  });

  bool get isUpcoming => departure.isAfter(DateTime.now()) && status != BookingStatus.cancelled;
  bool get isPast => departure.isBefore(DateTime.now()) || status == BookingStatus.completed;
  bool get canCancel => isUpcoming && status == BookingStatus.confirmed;

  factory TransportBooking.fromJson(Map<String, dynamic> json) {
    final paxList = json['passengers'] as List?;
    final ticketData = json['ticket'] as Map<String, dynamic>?;
    return TransportBooking(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      bookingReference: json['booking_reference']?.toString() ?? '',
      providerCode: json['provider_code']?.toString() ?? '',
      mode: TransportMode.fromString(json['mode']?.toString()),
      operator: json['operator']?.toString() ?? '',
      originCity: json['origin_city']?.toString() ?? '',
      destinationCity: json['destination_city']?.toString() ?? '',
      departure: DateTime.tryParse(json['departure']?.toString() ?? '') ?? DateTime.now(),
      arrival: DateTime.tryParse(json['arrival']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: _parseInt(json['duration_minutes']),
      transportClass: json['class']?.toString(),
      passengerCount: _parseInt(json['passenger_count']),
      unitPrice: _parseDouble(json['unit_price']),
      totalAmount: _parseDouble(json['total_amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      status: BookingStatus.fromString(json['status']?.toString()),
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      passengers: paxList?.map((p) => TransportPassenger.fromJson(p)).toList() ?? [],
      ticket: ticketData != null ? TransportTicket.fromJson(ticketData) : null,
    );
  }
}

class TransportPassenger {
  final int id;
  final String name;
  final String? phone;
  final String? idType;
  final String? idNumber;
  final bool isLead;

  const TransportPassenger({
    required this.id,
    required this.name,
    this.phone,
    this.idType,
    this.idNumber,
    this.isLead = false,
  });

  factory TransportPassenger.fromJson(Map<String, dynamic> json) {
    return TransportPassenger(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      idType: json['id_type']?.toString(),
      idNumber: json['id_number']?.toString(),
      isLead: _parseBool(json['is_lead']),
    );
  }
}

class TransportTicket {
  final int id;
  final int bookingId;
  final String ticketNumber;
  final String qrData;
  final String status;
  final Map<String, dynamic>? boardingInfo;

  const TransportTicket({
    required this.id,
    required this.bookingId,
    required this.ticketNumber,
    required this.qrData,
    this.status = 'active',
    this.boardingInfo,
  });

  factory TransportTicket.fromJson(Map<String, dynamic> json) {
    return TransportTicket(
      id: _parseInt(json['id']),
      bookingId: _parseInt(json['booking_id']),
      ticketNumber: json['ticket_number']?.toString() ?? '',
      qrData: json['qr_data']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      boardingInfo: json['boarding_info'] as Map<String, dynamic>?,
    );
  }
}

// ─── Result Wrappers ──────────────────────────────────────────

class TransportResult<T> {
  final bool success;
  final T? data;
  final String? message;

  TransportResult({required this.success, this.data, this.message});
}

class TransportListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  TransportListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse Helpers ────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
```

- [ ] **Step 2: Delete old models file and write new one**

Delete `lib/travel/models/travel_models.dart` and replace with the content above.

---

## Task 7: Frontend — Service Layer

**Files:**
- Create: `lib/travel/services/travel_service.dart` (replace existing)

- [ ] **Step 1: Write the complete service file**

```dart
// lib/travel/services/travel_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/travel_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TravelService {

  // ─── Search ─────────────────────────────────────────────────

  Future<TransportListResult<TransportOption>> search({
    required String origin,
    required String destination,
    required String date,
    int passengers = 1,
    String? preferredMode,
  }) async {
    try {
      final body = <String, dynamic>{
        'origin': origin,
        'destination': destination,
        'date': date,
        'passengers': passengers,
      };
      if (preferredMode != null) body['preferred_mode'] = preferredMode;

      final response = await http.post(
        Uri.parse('$_baseUrl/transport/search'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => TransportOption.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kutafuta safari');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Option Detail ──────────────────────────────────────────

  Future<TransportResult<TransportOption>> getOption(String optionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/option/$optionId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportOption.fromJson(data['data']),
          );
        }
      }
      return TransportResult(success: false, message: 'Imeshindwa kupakia chaguo');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Cities ─────────────────────────────────────────────────

  Future<TransportListResult<City>> getCities({String? query}) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['q'] = query;

      final uri = Uri.parse('$_baseUrl/transport/cities')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => City.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia miji');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Popular Routes ─────────────────────────────────────────

  Future<TransportListResult<PopularRoute>> getPopularRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/popular-routes'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => PopularRoute.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia njia maarufu');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Booking ────────────────────────────────────────────────

  Future<TransportResult<TransportBooking>> createBooking({
    required String optionId,
    required int userId,
    required List<Passenger> passengers,
    required PaymentMethod paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/bookings'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'option_id': optionId,
          'user_id': userId,
          'passengers': passengers.map((p) => p.toJson()).toList(),
          'payment_method': paymentMethod.name,
          if (paymentPhone != null && paymentPhone.isNotEmpty)
            'payment_phone': paymentPhone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportBooking.fromJson(data['data']),
          );
        }
        return TransportResult(success: false, message: data['message']?.toString());
      }

      // Try to extract error message from response
      try {
        final data = jsonDecode(response.body);
        return TransportResult(success: false, message: data['message']?.toString() ?? 'Imeshindwa kubuking');
      } catch (_) {
        return TransportResult(success: false, message: 'Imeshindwa kubuking');
      }
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── My Bookings ────────────────────────────────────────────

  Future<TransportListResult<TransportBooking>> getBookings(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/transport/bookings')
          .replace(queryParameters: {'user_id': '$userId'});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => TransportBooking.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia safari zako');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Cancel Booking ─────────────────────────────────────────

  Future<TransportResult<TransportBooking>> cancelBooking(int bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/bookings/$bookingId/cancel'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportBooking.fromJson(data['data']),
          );
        }
        return TransportResult(success: false, message: data['message']?.toString());
      }
      return TransportResult(success: false, message: 'Imeshindwa kughairi');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Ticket ─────────────────────────────────────────────────

  Future<TransportResult<TransportTicket>> getTicket(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/tickets/$bookingId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportTicket.fromJson(data['data']),
          );
        }
      }
      return TransportResult(success: false, message: 'Imeshindwa kupakia tiketi');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Weather ────────────────────────────────────────────────

  Future<TransportResult<Map<String, dynamic>>> getWeather(String cityCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/cities/$cityCode/weather'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(success: true, data: data['data'] as Map<String, dynamic>);
        }
      }
      return TransportResult(success: false, message: 'Hali ya hewa haipatikani');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }
}
```

**Note:** There is a bug in `createBooking` — the JSON body has `'if': null` which should be removed. The correct body construction:

```dart
body: jsonEncode({
  'option_id': optionId,
  'user_id': userId,
  'passengers': passengers.map((p) => p.toJson()).toList(),
  'payment_method': paymentMethod.name,
  if (paymentPhone != null && paymentPhone.isNotEmpty)
    'payment_phone': paymentPhone,
}),
```

---

## Task 8: Frontend — Module Entry, Widgets & ModeIcon

**Files:**
- Create: `lib/travel/travel_module.dart` (replace existing)
- Create: `lib/travel/widgets/mode_icon.dart`
- Create: `lib/travel/widgets/transport_option_card.dart`
- Create: `lib/travel/widgets/route_card.dart`
- Create: `lib/travel/widgets/booking_card.dart`
- Create: `lib/travel/widgets/city_search_field.dart`

This task creates the module entry point and all 5 reusable widgets. Due to the plan length limit, the full code for each widget is provided inline. Each widget follows the exact TAJIRI pattern: `_kPrimary = Color(0xFF1A1A1A)`, `_kSecondary = Color(0xFF666666)`, StatelessWidget with `onTap` callback, Material 3 styling.

- [ ] **Step 1: Replace travel_module.dart**

```dart
// lib/travel/travel_module.dart

import 'package:flutter/material.dart';
import 'pages/travel_home_page.dart';

class TravelModule extends StatelessWidget {
  final int userId;
  const TravelModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TravelHomePage(userId: userId);
  }
}
```

- [ ] **Step 2: Create mode_icon.dart**

```dart
// lib/travel/widgets/mode_icon.dart

import 'package:flutter/material.dart';
import '../models/travel_models.dart';

class ModeIcon extends StatelessWidget {
  final TransportMode mode;
  final double size;
  final Color? color;

  const ModeIcon({super.key, required this.mode, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(_iconFor(mode), size: size, color: color ?? const Color(0xFF666666));
  }

  static IconData _iconFor(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus: return Icons.directions_bus_rounded;
      case TransportMode.flight: return Icons.flight_rounded;
      case TransportMode.train: return Icons.train_rounded;
      case TransportMode.ferry: return Icons.directions_boat_rounded;
    }
  }

  /// Small row of mode icons for route cards
  static Widget modeRow(List<String> modes, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: modes.map((m) {
        final mode = TransportMode.fromString(m);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(_iconFor(mode), size: size, color: const Color(0xFF666666)),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 3: Create transport_option_card.dart**

```dart
// lib/travel/widgets/transport_option_card.dart

import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import 'mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TransportOptionCard extends StatelessWidget {
  final TransportOption option;
  final VoidCallback? onTap;
  final bool isCheapest;
  final bool isFastest;

  const TransportOptionCard({
    super.key,
    required this.option,
    this.onTap,
    this.isCheapest = false,
    this.isFastest = false,
  });

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            if (isCheapest || isFastest)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isCheapest) _Badge('Bei nafuu', Colors.green.shade700),
                    if (isCheapest && isFastest) const SizedBox(width: 6),
                    if (isFastest) _Badge('Haraka zaidi', Colors.blue.shade700),
                  ],
                ),
              ),
            // Operator + mode row
            Row(
              children: [
                ModeIcon(mode: option.mode, size: 22, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.operator.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${option.mode.displayName} • ${option.transportClass ?? 'Economy'}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      option.price.formatted,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    Text(
                      'kwa mtu',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Time row: departure → duration → arrival
            Row(
              children: [
                Text(
                  _fmtTime(option.departure),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        option.durationFormatted,
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                      const Divider(height: 4, thickness: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _fmtTime(option.arrival),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Origin → Destination text + seats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${option.origin.code} → ${option.destination.code}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                Text(
                  'Viti ${option.seatsAvailable}',
                  style: TextStyle(
                    fontSize: 12,
                    color: option.seatsAvailable < 5 ? Colors.red.shade400 : _kSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
```

- [ ] **Step 4: Create route_card.dart**

```dart
// lib/travel/widgets/route_card.dart

import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import 'mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class RouteCard extends StatelessWidget {
  final PopularRoute route;
  final VoidCallback? onTap;

  const RouteCard({super.key, required this.route, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              route.origin.city,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    route.destination.city,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (route.modes.isNotEmpty) ModeIcon.modeRow(route.modes),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create booking_card.dart**

```dart
// lib/travel/widgets/booking_card.dart

import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import 'mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BookingCard extends StatelessWidget {
  final TransportBooking booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.confirmed: return const Color(0xFF4CAF50);
      case BookingStatus.cancelled: return Colors.red;
      case BookingStatus.completed: return _kSecondary;
      case BookingStatus.pending: return Colors.orange;
    }
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ago','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Date box
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${booking.departure.day}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  Text(
                    ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ago','Sep','Okt','Nov','Des'][booking.departure.month - 1],
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ModeIcon(mode: booking.mode, size: 16, color: _kPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${booking.originCity} → ${booking.destinationCity}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.operator} • ${_fmtTime(booking.departure)}',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  Text(
                    '${booking.passengerCount} abiria • ${booking.bookingReference}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.status.displayName,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Create city_search_field.dart**

```dart
// lib/travel/widgets/city_search_field.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CitySearchField {
  static Future<City?> show(BuildContext context, {String title = 'Chagua mji'}) async {
    return showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CitySearchSheet(title: title),
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  final String title;
  const _CitySearchSheet({required this.title});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _controller = TextEditingController();
  final _service = TravelService();
  Timer? _debounce;
  List<City> _cities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadCities(query: query);
    });
  }

  Future<void> _loadCities({String? query}) async {
    setState(() => _isLoading = true);
    final result = await _service.getCities(query: query);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _cities = result.items;
      });
    }
  }

  String _countryFlag(String code) {
    switch (code) {
      case 'TZ': return '🇹🇿';
      case 'KE': return '🇰🇪';
      case 'UG': return '🇺🇬';
      case 'RW': return '🇷🇼';
      case 'BI': return '🇧🇮';
      case 'ZM': return '🇿🇲';
      case 'MW': return '🇲🇼';
      case 'AE': return '🇦🇪';
      case 'ZA': return '🇿🇦';
      case 'ET': return '🇪🇹';
      case 'IN': return '🇮🇳';
      case 'TR': return '🇹🇷';
      case 'GB': return '🇬🇧';
      default: return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tafuta mji...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _cities.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final city = _cities[i];
                  return ListTile(
                    leading: Text(_countryFlag(city.country), style: const TextStyle(fontSize: 24)),
                    title: Text(
                      city.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimary),
                    ),
                    subtitle: Text(
                      '${city.code} • ${city.region ?? city.country}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (city.hasAirport) const Icon(Icons.flight_rounded, size: 14, color: _kSecondary),
                        if (city.hasBusTerminal) const Icon(Icons.directions_bus_rounded, size: 14, color: _kSecondary),
                        if (city.hasTrainStation) const Icon(Icons.train_rounded, size: 14, color: _kSecondary),
                        if (city.hasFerryTerminal) const Icon(Icons.directions_boat_rounded, size: 14, color: _kSecondary),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Task 9: Frontend — Home Page

**Files:**
- Create: `lib/travel/pages/travel_home_page.dart` (replace existing)

This is the main entry screen with search bar, recent searches, popular routes, and upcoming bookings. Full implementation following the Events home page pattern with `_loadData()`, `Future.wait()`, `mounted` checks, `RefreshIndicator`, and the standard header container.

- [ ] **Step 1: Write travel_home_page.dart**

The home page contains: search form (origin, destination, date, passengers), recent searches chips, popular routes horizontal scroll, upcoming bookings section. Opens `SearchResultsPage` on search, `MyBookingsPage` on "Safiri Zangu" tap. Uses `CitySearchField.show()` for city selection, `showDatePicker()` for date.

*(Due to plan length, this page follows the exact pattern shown in the Events home page exploration. Key state: `_originCity`, `_destCity`, `_date`, `_passengers`, `_popularRoutes`, `_upcomingBookings`, `_isLoading`. Build method: header container with search form → recent searches → popular routes horizontal ListView → upcoming bookings list → "View All" button.)*

---

## Task 10: Frontend — Search Results Page

**Files:**
- Create: `lib/travel/pages/search_results_page.dart`

Receives search parameters, calls `TravelService.search()`, displays results as `TransportOptionCard` list with mode filter chips (All/Bus/Flight/Train/Ferry) and sort options (Price/Duration/Departure). Marks cheapest and fastest results with badges. Handles empty state with suggestions.

---

## Task 11: Frontend — Transport Detail Page

**Files:**
- Create: `lib/travel/pages/transport_detail_page.dart`

Receives `TransportOption`, shows full detail using `CustomScrollView` + `SliverAppBar` pattern. Operator info, departure → arrival timeline, class/tier, amenities list, vehicle info, cancellation policy text. Bottom button "Buking / Book" navigates to `PassengerInfoPage`.

---

## Task 12: Frontend — Passenger Info Page

**Files:**
- Create: `lib/travel/pages/passenger_info_page.dart`

Form page with `GlobalKey<FormState>`. Creates `Passenger` objects for each traveler. Lead passenger auto-filled. Fields: name (required), phone, ID type dropdown (Kitambulisho/Passport), ID number. "Continue" button validates and navigates to `CheckoutPage`.

---

## Task 13: Frontend — Checkout Page

**Files:**
- Create: `lib/travel/pages/checkout_page.dart`

Shows booking summary (route, time, passengers), price breakdown (unit × count + fees), payment method radio buttons (TAJIRI Wallet, M-Pesa, Tigo Pesa, Airtel Money), phone input for mobile money. "Confirm & Pay" calls `TravelService.createBooking()`, navigates to `BookingConfirmationPage` on success.

---

## Task 14: Frontend — Booking Confirmation, My Bookings & Ticket Pages

**Files:**
- Create: `lib/travel/pages/booking_confirmation_page.dart`
- Create: `lib/travel/pages/my_bookings_page.dart`
- Create: `lib/travel/pages/ticket_page.dart`

**Confirmation:** Success icon, booking reference, summary, two buttons (View Ticket, Back to Home).

**My Bookings:** Two tabs (Upcoming/Past) using the Events my_tickets pattern. Lists `BookingCard` widgets. Tap opens ticket or booking detail. Pull-to-refresh.

**Ticket:** Full e-ticket layout with QR code (using `qr_flutter` package or simple placeholder), booking reference, route/time/passengers/class, operator info, "Share" button.

---

## Task 15: Frontend — Delete Old Files & Wire Up

**Files:**
- Delete old pages: `lib/travel/pages/search_page.dart`, `destination_page.dart`, `book_trip_page.dart`, `my_trips_page.dart`
- Delete old widgets: `lib/travel/widgets/destination_card.dart`, `trip_card.dart`

- [ ] **Step 1: Delete old travel files that are no longer needed**

```bash
rm lib/travel/pages/search_page.dart
rm lib/travel/pages/destination_page.dart
rm lib/travel/pages/book_trip_page.dart
rm lib/travel/pages/my_trips_page.dart
rm lib/travel/widgets/destination_card.dart
rm lib/travel/widgets/trip_card.dart
```

- [ ] **Step 2: Verify the profile tab still wires correctly**

The `_ProfileTabPage._buildContent()` in `profile_screen.dart` already has `case 'travel': return TravelModule(userId: userId);` and the import points to `../../travel/travel_module.dart`. Since we kept the same module entry point signature (`TravelModule({required this.userId})`), no changes needed in profile_screen.dart.

- [ ] **Step 3: Run flutter analyze to check for errors**

```bash
flutter analyze lib/travel/
```

Expected: No errors. Warnings about unused imports from deleted files should not appear since we replaced all files.

---

## Task 16: Backend — Provider Stubs (Otapp, Amadeus, BuuPass)

**Files:**
- Create: `app/Services/Travel/Providers/OtappProvider.php`
- Create: `app/Services/Travel/Providers/AmadeusProvider.php`
- Create: `app/Services/Travel/Providers/BuuPassProvider.php`

These are stub implementations that return empty results for now. They implement `TransportProviderInterface` so they can be registered in `TravelSearchService` and activated once API keys are configured.

- [ ] **Step 1: Create OtappProvider stub**

```php
<?php
// app/Services/Travel/Providers/OtappProvider.php

namespace App\Services\Travel\Providers;

use Illuminate\Support\Collection;

class OtappProvider implements TransportProviderInterface
{
    public function code(): string { return 'otapp'; }

    public function search(string $originCode, string $destCode, string $date, int $passengers): Collection
    {
        // TODO: Integrate with Otapp API once API key is obtained
        // API docs: contact otapp.co.tz for API access
        if (!config('services.otapp.key')) {
            return collect();
        }

        return collect();
    }
}
```

- [ ] **Step 2: Create AmadeusProvider stub**

```php
<?php
// app/Services/Travel/Providers/AmadeusProvider.php

namespace App\Services\Travel\Providers;

use Illuminate\Support\Collection;

class AmadeusProvider implements TransportProviderInterface
{
    public function code(): string { return 'amadeus'; }

    public function search(string $originCode, string $destCode, string $date, int $passengers): Collection
    {
        // TODO: Integrate with Amadeus Self-Service API
        // Free tier: 2,000 calls/month
        // Docs: developers.amadeus.com
        if (!config('services.amadeus.client_id')) {
            return collect();
        }

        return collect();
    }
}
```

- [ ] **Step 3: Create BuuPassProvider stub**

```php
<?php
// app/Services/Travel/Providers/BuuPassProvider.php

namespace App\Services\Travel\Providers;

use Illuminate\Support\Collection;

class BuuPassProvider implements TransportProviderInterface
{
    public function code(): string { return 'buupass'; }

    public function search(string $originCode, string $destCode, string $date, int $passengers): Collection
    {
        // TODO: Integrate with BuuPass Partner API
        // Cross-border East Africa buses
        // Contact: buupass.com for API partnership
        if (!config('services.buupass.key')) {
            return collect();
        }

        return collect();
    }
}
```

- [ ] **Step 4: Register all providers in TravelSearchService**

Update the constructor in `app/Services/Travel/TravelSearchService.php`:

```php
public function __construct()
{
    $this->providers = [
        new InternalProvider(),
        new OtappProvider(),
        new AmadeusProvider(),
        new BuuPassProvider(),
    ];
}
```

Add imports at top:
```php
use App\Services\Travel\Providers\OtappProvider;
use App\Services\Travel\Providers\AmadeusProvider;
use App\Services\Travel\Providers\BuuPassProvider;
```

---

## Task 17: Seed Provider Registry & Add Env Variables

- [ ] **Step 1: Seed provider records**

```bash
php artisan tinker --execute="
    App\Models\Travel\TransportProvider::updateOrCreate(['code' => 'internal'], ['name' => 'Internal (SGR/Ferry)', 'is_active' => true]);
    App\Models\Travel\TransportProvider::updateOrCreate(['code' => 'otapp'], ['name' => 'Otapp', 'api_base_url' => 'https://api.otapp.co.tz', 'is_active' => false]);
    App\Models\Travel\TransportProvider::updateOrCreate(['code' => 'amadeus'], ['name' => 'Amadeus', 'api_base_url' => 'https://api.amadeus.com', 'is_active' => false]);
    App\Models\Travel\TransportProvider::updateOrCreate(['code' => 'buupass'], ['name' => 'BuuPass', 'api_base_url' => 'https://api.buupass.com', 'is_active' => false]);
    echo 'Providers seeded: ' . App\Models\Travel\TransportProvider::count();
"
```

- [ ] **Step 2: Add environment variable placeholders to .env**

```bash
cat >> /var/www/tajiri.zimasystems.com/.env << 'EOF'

# Transport Provider API Keys
OTAPP_API_KEY=
OTAPP_API_URL=https://api.otapp.co.tz
AMADEUS_CLIENT_ID=
AMADEUS_CLIENT_SECRET=
BUUPASS_API_KEY=
BUUPASS_API_URL=https://api.buupass.com
WEATHER_API_KEY=
EOF
```

- [ ] **Step 3: Add service config to config/services.php**

Add to the `return` array in `config/services.php`:

```php
'otapp' => [
    'key' => env('OTAPP_API_KEY'),
    'url' => env('OTAPP_API_URL'),
],
'amadeus' => [
    'client_id' => env('AMADEUS_CLIENT_ID'),
    'client_secret' => env('AMADEUS_CLIENT_SECRET'),
],
'buupass' => [
    'key' => env('BUUPASS_API_KEY'),
    'url' => env('BUUPASS_API_URL'),
],
'weather' => [
    'key' => env('WEATHER_API_KEY'),
],
```

---

## Verification Checklist

After all tasks complete:

- [ ] Backend: `php artisan route:list --path=transport` shows 9 routes
- [ ] Backend: `curl POST /api/transport/search {origin:DAR, destination:DOD, date:tomorrow}` returns SGR results
- [ ] Backend: `curl GET /api/transport/cities?q=Dar` returns Dar es Salaam
- [ ] Backend: `curl POST /api/transport/bookings` creates booking with ticket
- [ ] Frontend: `flutter analyze lib/travel/` — zero errors
- [ ] Frontend: TravelModule opens from profile tab
- [ ] Frontend: City search bottom sheet works with debounce
- [ ] Frontend: Search returns and displays transport options
- [ ] Frontend: Full booking flow: search → detail → passengers → checkout → confirmation → ticket
- [ ] Frontend: My Bookings shows upcoming/past tabs
