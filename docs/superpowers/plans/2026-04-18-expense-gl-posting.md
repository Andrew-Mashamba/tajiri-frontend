# Expense GL Posting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire every money-out event in TAJIRI to correct double-entry GL postings — fixing the RETAINED_EARNINGS hack in shop buyer posting and adding automatic GL entries for manually recorded business expenses.

**Architecture:** Backend-first: all GL logic lives server-side in `WalletLedgerService` and new `ExpenseJournalService`. A new COA account 1840 (ADVANCE PAYMENTS — APP PURCHASES) serves as the prepayment clearing asset for deferred-delivery flows (shop, food, fuel). Manual expenses post a single entry: Dr expense account → Cr WALLET_CASH (1010). Flutter only adds `journalEntryId` to the Expense model and a "In Ledger" badge on expense cards.

**Tech Stack:** Laravel 12 / PHP 8.3 (backend on 172.240.241.180), Flutter/Dart 3 (frontend). Backend accessed via `sshpass -p "ZimaBlueApps" ssh root@172.240.241.180`. Backend project root: `/var/www/tajiri.zimasystems.com`.

---

## File Map

**Backend — create:**
- `database/migrations/2026_04_18_000001_add_coa_1840_advance_payments.php`
- `database/migrations/2026_04_18_000002_add_journal_entry_id_to_expenses.php`
- `app/Services/Accounting/ExpenseJournalService.php`

**Backend — modify:**
- `app/Services/Accounting/CoaAccountCodes.php` — add 13 new constants
- `app/Services/Accounting/WalletLedgerService.php` — fix `postShopPurchase`, `postShopBuyerSpendAllocation`, `postShopRefund`
- `app/Http/Controllers/Api/MyBusinessController.php` — wire GL in `storeExpense`, return full row

**Frontend — modify:**
- `lib/business/models/business_models.dart` — add `journalEntryId` to `Expense`
- `lib/expenses/pages/expenses_page.dart` — Swahili labels, posted badge, mounted guard

---

## Task 1: Add COA definition 1840 to the database

**Files:**
- Create: `/var/www/tajiri.zimasystems.com/database/migrations/2026_04_18_000001_add_coa_1840_advance_payments.php`

Context: `coa_definitions` rows have columns `code`, `name`, `major_code`, `category_code`, `subcategory_code`. `BookProvisioner::provision()` reads ALL `coa_definitions` rows and creates a `book_accounts` row for each one — so inserting this row is enough to make 1840 available in all future books. Existing books need a backfill (Step 4).

- [ ] **Step 1: Create the migration file on the server**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/database/migrations/2026_04_18_000001_add_coa_1840_advance_payments.php << 'MIGRATION'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Insert COA definition for ADVANCE PAYMENTS — APP PURCHASES (1840)
        // Category 1800 = PREPAID EXPENSES (existing). This is the professional
        // prepayment/advance-payment treatment: buyer paid, goods not yet received = asset.
        if (DB::table('coa_definitions')->where('code', '1840')->doesntExist()) {
            DB::table('coa_definitions')->insert([
                'code'             => '1840',
                'name'             => 'ADVANCE PAYMENTS — APP PURCHASES',
                'major_code'       => '1000',
                'category_code'    => '1800',
                'subcategory_code' => '1840',
                'created_at'       => now(),
                'updated_at'       => now(),
            ]);
        }

        // Backfill: add book_accounts row for 1840 in every existing book
        \$def = DB::table('coa_definitions')->where('code', '1840')->first();
        if (\$def === null) return;

        \$books = DB::table('accounting_books')->pluck('id');
        foreach (\$books as \$bookId) {
            if (DB::table('book_accounts')->where('book_id', \$bookId)->where('coa_definition_id', \$def->id)->doesntExist()) {
                DB::table('book_accounts')->insert([
                    'book_id'           => \$bookId,
                    'coa_definition_id' => \$def->id,
                    'balance'           => 0,
                    'currency'          => 'TZS',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        \$def = DB::table('coa_definitions')->where('code', '1840')->first();
        if (\$def) {
            DB::table('book_accounts')->where('coa_definition_id', \$def->id)->delete();
            DB::table('coa_definitions')->where('code', '1840')->delete();
        }
    }
};
MIGRATION"
```

- [ ] **Step 2: Run the migration**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan migrate --path=database/migrations/2026_04_18_000001_add_coa_1840_advance_payments.php"
```

Expected output: `Running migrations... 2026_04_18_000001_add_coa_1840_advance_payments ........... DONE`

- [ ] **Step 3: Verify the row exists**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute='echo json_encode(DB::table(\"coa_definitions\")->where(\"code\",\"1840\")->first());'"
```

Expected: `{"id":...,"code":"1840","name":"ADVANCE PAYMENTS \u2014 APP PURCHASES","major_code":"1000","category_code":"1800","subcategory_code":"1840",...}`

- [ ] **Step 4: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add database/migrations/2026_04_18_000001_add_coa_1840_advance_payments.php && git commit -m 'feat(accounting): add COA 1840 ADVANCE PAYMENTS — APP PURCHASES'"
```

---

## Task 2: Add journal_entry_id column to user_business_expenses

**Files:**
- Create: `/var/www/tajiri.zimasystems.com/database/migrations/2026_04_18_000002_add_journal_entry_id_to_expenses.php`

- [ ] **Step 1: Create the migration**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/database/migrations/2026_04_18_000002_add_journal_entry_id_to_expenses.php << 'MIGRATION'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_business_expenses', function (Blueprint \$table) {
            \$table->unsignedBigInteger('journal_entry_id')->nullable()->after('notes');
        });
    }

    public function down(): void
    {
        Schema::table('user_business_expenses', function (Blueprint \$table) {
            \$table->dropColumn('journal_entry_id');
        });
    }
};
MIGRATION"
```

- [ ] **Step 2: Run the migration**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan migrate --path=database/migrations/2026_04_18_000002_add_journal_entry_id_to_expenses.php"
```

Expected: `2026_04_18_000002_add_journal_entry_id_to_expenses ........... DONE`

- [ ] **Step 3: Verify column exists**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute='echo implode(\", \", array_keys((array)DB::table(\"user_business_expenses\")->first()));'"
```

Expected output includes `journal_entry_id` in the column list.

- [ ] **Step 4: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add database/migrations/2026_04_18_000002_add_journal_entry_id_to_expenses.php && git commit -m 'feat(expenses): add journal_entry_id to user_business_expenses'"
```

---

## Task 3: Add CoaAccountCodes constants

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Services/Accounting/CoaAccountCodes.php`

Context: The current file has ~15 constants. All constants referenced by `ExpenseJournalService` (Task 6) and updated `WalletLedgerService` (Tasks 4–6) must exist here first.

- [ ] **Step 1: Read current file to find insertion point**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "tail -10 /var/www/tajiri.zimasystems.com/app/Services/Accounting/CoaAccountCodes.php"
```

Expected: file ends with `public const BANK_CHARGES = '5010';` then closing brace `}`.

- [ ] **Step 2: Append new constants before the closing brace**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && sed -i 's/    public const BANK_CHARGES = .5010.;/    public const BANK_CHARGES = '\''5010'\'';\n\n    \/** Prepayment clearing — buyer paid but goods not yet received (asset 1800). *\/\n    public const ADVANCE_PAYMENTS_APP = '\''1840'\'';\n\n    \/** Manual expense category accounts — used by ExpenseJournalService. *\/\n    public const RENTAL_PAYMENTS        = '\''5710'\'';\n    public const UTILITY_EXPENSES       = '\''5720'\'';\n    public const BASE_SALARIES          = '\''5110'\'';\n    public const TRANSPORTATION         = '\''5242'\'';\n    public const OFFICE_SUPPLIES        = '\''5616'\'';\n    public const OTHER_OPERATIONAL      = '\''5328'\'';\n    public const MEALS                  = '\''5860'\'';\n    public const TELEPHONE_EXPENSES     = '\''5610'\'';\n    public const MAINTENANCE_COSTS      = '\''5730'\'';\n    public const PROPERTY_TAXES         = '\''5320'\'';\n    public const INSURANCE_PREMIUMS_EXP = '\''5326'\'';\n    public const OTHER_CHARGES          = '\''5880'\'';/' app/Services/Accounting/CoaAccountCodes.php"
```

- [ ] **Step 2 (alternative if sed fails): Write the full file directly**

If the sed above fails due to escaping, write the complete file:

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/app/Services/Accounting/CoaAccountCodes.php << 'PHP'
<?php

namespace App\Services\Accounting;

/**
 * Leaf codes from docs/chart-of-accounts.md used in automated postings.
 */
final class CoaAccountCodes
{
    /** Cash / operating account — wallet balance must equal this account per user book. */
    public const WALLET_CASH = '1010';

    /**
     * Self-serve advertising prepaid balance (maps to wallets.ad_balance).
     * Chart: 1020 PETTY CASH FUND — used as dedicated ad wallet asset per user book.
     */
    public const AD_WALLET = '1020';

    /** Member deposits / regular savings — user wallet liability. */
    public const MEMBER_DEPOSITS = '2110';

    /** Output VAT on shop sales — liability to remit (seller book). */
    public const OUTPUT_VAT_PAYABLE = '2525';

    /** Input VAT recoverable — shop buyer spend; seller commission on marketplace fees. */
    public const INPUT_VAT_RECOVERABLE = '1535';

    /** Suspense — clearing / mobile money in transit. */
    public const SUSPENSE_BANK = '1009';

    /** Service fees — P2P / transfer fee revenue (platform). */
    public const TRANSACTION_FEES_REVENUE = '4215';

    /** Miscellaneous income — marketplace seller net-of-VAT sales & platform ad revenue. */
    public const MISCELLANEOUS_INCOME = '4520';

    /** Seller: platform commission on marketplace order. */
    public const MARKETPLACE_COMMISSION_EXPENSE = '5342';

    /** User advertising spend (operating expense line). */
    public const AD_SPEND_EXPENSE = '5328';

    /** Shop — buyer-side expense lines when order completes (goods, delivery, fee). */
    public const SHOP_BUYER_GOODS_EXPENSE = '5330';
    public const SHOP_BUYER_DELIVERY_EXPENSE = '5332';
    public const SHOP_BUYER_MARKETPLACE_FEE_EXPENSE = '5334';

    /**
     * Retained earnings — kept for backward compat only.
     * No new code should use this for purchase flows; use ADVANCE_PAYMENTS_APP instead.
     */
    public const RETAINED_EARNINGS_UNAPPROPRIATED = '3140';

    /** Bank charges — user-paid fees on deposit/withdrawal. */
    public const BANK_CHARGES = '5010';

    /**
     * Prepayment clearing — buyer paid but goods not yet received (asset 1800 category).
     * Professional treatment: prepayment is an asset (right to receive goods/services).
     * Debited at payment, credited at fulfilment or refund. Balance = 0 after settlement.
     */
    public const ADVANCE_PAYMENTS_APP = '1840';

    /** Manual expense category accounts — used by ExpenseJournalService. */
    public const RENTAL_PAYMENTS        = '5710';
    public const UTILITY_EXPENSES       = '5720';
    public const BASE_SALARIES          = '5110';
    public const TRANSPORTATION         = '5242';
    public const OFFICE_SUPPLIES        = '5616';
    public const OTHER_OPERATIONAL      = '5328';
    public const MEALS                  = '5860';
    public const TELEPHONE_EXPENSES     = '5610';
    public const MAINTENANCE_COSTS      = '5730';
    public const PROPERTY_TAXES         = '5320';
    public const INSURANCE_PREMIUMS_EXP = '5326';
    public const OTHER_CHARGES          = '5880';
}
PHP"
```

- [ ] **Step 3: Verify the file parses without errors**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Services/Accounting/CoaAccountCodes.php"
```

Expected: `No syntax errors detected`

- [ ] **Step 4: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Services/Accounting/CoaAccountCodes.php && git commit -m 'feat(accounting): add ADVANCE_PAYMENTS_APP and expense category COA constants'"
```

---

## Task 4: Fix WalletLedgerService — postShopPurchase

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php`

Context: Current `postShopPurchase` calls `postOutboundTotal()` which does Dr MEMBER_DEPOSITS (2110) / Cr WALLET_CASH (1010). Professional accounting requires: Dr ADVANCE_PAYMENTS_APP (1840) / Cr WALLET_CASH (1010) because the buyer now holds a prepayment asset (right to receive goods), not a reduced liability.

- [ ] **Step 1: Replace postShopPurchase**

Find the current method (around line 225 in WalletLedgerService.php):
```php
public function postShopPurchase(int $buyerId, float $total, WalletTransaction $txn): void
{
    $this->postOutboundTotal($buyerId, round($total, 2), $txn);
}
```

Replace with:
```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php -r \"
\\\$file = file_get_contents('app/Services/Accounting/WalletLedgerService.php');
\\\$old = 'public function postShopPurchase(int \\\\\\\$buyerId, float \\\\\\\$total, WalletTransaction \\\\\\\$txn): void
    {
        \\\\\\\$this->postOutboundTotal(\\\\\\\$buyerId, round(\\\\\\\$total, 2), \\\\\\\$txn);
    }';
echo (str_contains(\\\$file, 'postOutboundTotal') ? 'FOUND' : 'NOT FOUND');
\""
```

If FOUND, write the replacement using the server's editor:

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && python3 -c \"
import re, sys
f = open('app/Services/Accounting/WalletLedgerService.php').read()
old = '''public function postShopPurchase(int \\\$buyerId, float \\\$total, WalletTransaction \\\$txn): void
    {
        \\\$this->postOutboundTotal(\\\$buyerId, round(\\\$total, 2), \\\$txn);
    }'''
new = '''public function postShopPurchase(int \\\$buyerId, float \\\$total, WalletTransaction \\\$txn): void
    {
        \\\$total = round(\\\$total, 2);
        DB::transaction(function () use (\\\$buyerId, \\\$total, \\\$txn) {
            \\\$book = \\\$this->ensureUserBook(\\\$buyerId);
            \\\$entry = \\\$this->journal->post(
                \\\$book,
                [
                    ['code' => CoaAccountCodes::ADVANCE_PAYMENTS_APP, 'debit' => \\\$total, 'credit' => 0],
                    ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => 0, 'credit' => \\\$total],
                ],
                WalletTransaction::class,
                \\\$txn->id,
                'Shop payment — advance for goods not yet received',
            );
            \\\$txn->update(['journal_entry_id' => \\\$entry->id]);
            \\\$this->syncWalletBalanceFromLedger(\\\$buyerId);
        });
    }'''
if old not in f:
    print('PATTERN NOT FOUND — check whitespace')
    sys.exit(1)
open('app/Services/Accounting/WalletLedgerService.php', 'w').write(f.replace(old, new, 1))
print('OK')
\""
```

- [ ] **Step 2: Verify file parses**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php"
```

Expected: `No syntax errors detected`

- [ ] **Step 3: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Services/Accounting/WalletLedgerService.php && git commit -m 'fix(accounting): postShopPurchase uses ADVANCE_PAYMENTS_APP clearing instead of MEMBER_DEPOSITS'"
```

---

## Task 5: Fix WalletLedgerService — postShopBuyerSpendAllocation

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php`

Context: The last line of `postShopBuyerSpendAllocation` currently credits RETAINED_EARNINGS_UNAPPROPRIATED (3140). This is semantically wrong — retained earnings should not be touched for purchase allocation. Change the credit to ADVANCE_PAYMENTS_APP (1840), which clears the prepayment asset created in Task 4.

- [ ] **Step 1: Replace the RETAINED_EARNINGS credit line**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && python3 -c \"
f = open('app/Services/Accounting/WalletLedgerService.php').read()
old = \"CoaAccountCodes::RETAINED_EARNINGS_UNAPPROPRIATED,\"
new = \"CoaAccountCodes::ADVANCE_PAYMENTS_APP,\"
if old not in f:
    print('PATTERN NOT FOUND')
else:
    open('app/Services/Accounting/WalletLedgerService.php', 'w').write(f.replace(old, new, 1))
    print('OK — replaced 1 occurrence')
\""
```

Expected: `OK — replaced 1 occurrence`

- [ ] **Step 2: Verify**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php && grep -n 'ADVANCE_PAYMENTS_APP\|RETAINED_EARNINGS' /var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php"
```

Expected: syntax OK; `ADVANCE_PAYMENTS_APP` appears in both `postShopPurchase` and `postShopBuyerSpendAllocation`; `RETAINED_EARNINGS` no longer appears.

- [ ] **Step 3: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Services/Accounting/WalletLedgerService.php && git commit -m 'fix(accounting): postShopBuyerSpendAllocation credits ADVANCE_PAYMENTS_APP instead of RETAINED_EARNINGS'"
```

---

## Task 6: Fix WalletLedgerService — postShopRefund

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php`

Context: `postShopRefund` currently does Dr WALLET_CASH (1010) / Cr MEMBER_DEPOSITS (2110). After Task 4, the payment created Dr ADVANCE_PAYMENTS_APP (1840) / Cr WALLET_CASH (1010). The refund must reverse that: Dr WALLET_CASH (1010) / Cr ADVANCE_PAYMENTS_APP (1840). Using MEMBER_DEPOSITS (2110) here would leave 1840 open with a non-zero balance.

- [ ] **Step 1: Replace the MEMBER_DEPOSITS credit in postShopRefund**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && python3 -c \"
f = open('app/Services/Accounting/WalletLedgerService.php').read()

old = \"'Shop refund',\"
# Find postShopRefund and replace its MEMBER_DEPOSITS with ADVANCE_PAYMENTS_APP
# The refund block is: WALLET_CASH debit + MEMBER_DEPOSITS credit
old_block = \"                    ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => \\\$total, 'credit' => 0],\n                    ['code' => CoaAccountCodes::MEMBER_DEPOSITS, 'debit' => 0, 'credit' => \\\$total],\n                ],\n                WalletTransaction::class,\n                \\\$txn->id,\n                'Shop refund',\"
new_block = \"                    ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => \\\$total, 'credit' => 0],\n                    ['code' => CoaAccountCodes::ADVANCE_PAYMENTS_APP, 'debit' => 0, 'credit' => \\\$total],\n                ],\n                WalletTransaction::class,\n                \\\$txn->id,\n                'Shop refund — advance payment reversed',\"
if old_block not in f:
    print('PATTERN NOT FOUND')
else:
    open('app/Services/Accounting/WalletLedgerService.php', 'w').write(f.replace(old_block, new_block, 1))
    print('OK')
\""
```

If the pattern matching fails due to whitespace differences, open the file in nano and manually edit `postShopRefund`:

The method should look like this after the edit:
```php
public function postShopRefund(int $buyerId, float $total, WalletTransaction $txn): void
{
    $total = round($total, 2);
    DB::transaction(function () use ($buyerId, $total, $txn) {
        $book = $this->ensureUserBook($buyerId);
        $entry = $this->journal->post(
            $book,
            [
                ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => $total, 'credit' => 0],
                ['code' => CoaAccountCodes::ADVANCE_PAYMENTS_APP, 'debit' => 0, 'credit' => $total],
            ],
            WalletTransaction::class,
            $txn->id,
            'Shop refund — advance payment reversed',
        );
        $txn->update(['journal_entry_id' => $entry->id]);
        $this->syncWalletBalanceFromLedger($buyerId);
    });
}
```

- [ ] **Step 2: Verify**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php && grep -n 'Shop refund' /var/www/tajiri.zimasystems.com/app/Services/Accounting/WalletLedgerService.php"
```

Expected: syntax OK; grep shows `'Shop refund — advance payment reversed'`.

- [ ] **Step 3: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Services/Accounting/WalletLedgerService.php && git commit -m 'fix(accounting): postShopRefund clears ADVANCE_PAYMENTS_APP instead of MEMBER_DEPOSITS'"
```

---

## Task 7: Create ExpenseJournalService

**Files:**
- Create: `/var/www/tajiri.zimasystems.com/app/Services/Accounting/ExpenseJournalService.php`

Context: This service handles GL posting for manually recorded business expenses. It maps the `category` string to the correct 5000-series COA code and posts Dr expense / Cr WALLET_CASH. It uses `WalletLedgerService::ensureUserBook()` to auto-create the user's personal accounting book if one doesn't exist yet.

- [ ] **Step 1: Create the service file**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/app/Services/Accounting/ExpenseJournalService.php << 'PHP'
<?php

namespace App\Services\Accounting;

use App\Models\JournalEntry;
use Illuminate\Support\Facades\DB;

class ExpenseJournalService
{
    private static array $categoryMap = [
        'rent'          => CoaAccountCodes::RENTAL_PAYMENTS,
        'utilities'     => CoaAccountCodes::UTILITY_EXPENSES,
        'salary'        => CoaAccountCodes::BASE_SALARIES,
        'transport'     => CoaAccountCodes::TRANSPORTATION,
        'supplies'      => CoaAccountCodes::OFFICE_SUPPLIES,
        'marketing'     => CoaAccountCodes::OTHER_OPERATIONAL,
        'food'          => CoaAccountCodes::MEALS,
        'communication' => CoaAccountCodes::TELEPHONE_EXPENSES,
        'maintenance'   => CoaAccountCodes::MAINTENANCE_COSTS,
        'tax'           => CoaAccountCodes::PROPERTY_TAXES,
        'insurance'     => CoaAccountCodes::INSURANCE_PREMIUMS_EXP,
        'other'         => CoaAccountCodes::OTHER_CHARGES,
    ];

    public function __construct(
        private readonly JournalPostingService $journal,
        private readonly WalletLedgerService $wallet,
    ) {}

    /**
     * Post a single manual expense entry:
     *   Dr <expense COA>  amount
     *   Cr WALLET_CASH    amount
     *
     * @param  int    \$userProfileId  The user_profiles.id of the expense owner.
     * @param  float  \$amount         Expense amount in TZS.
     * @param  string \$category       Category slug (rent, utilities, salary, etc.).
     * @param  int    \$expenseId      The user_business_expenses.id (used as source_id).
     */
    public function postManualExpense(
        int $userProfileId,
        float $amount,
        string $category,
        int $expenseId
    ): JournalEntry {
        $amount = round($amount, 2);
        $expenseCode = self::$categoryMap[strtolower($category)] ?? CoaAccountCodes::OTHER_CHARGES;

        return DB::transaction(function () use ($userProfileId, $amount, $expenseCode, $category, $expenseId) {
            $book = $this->wallet->ensureUserBook($userProfileId);
            return $this->journal->post(
                $book,
                [
                    ['code' => $expenseCode, 'debit' => $amount, 'credit' => 0],
                    ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => 0, 'credit' => $amount],
                ],
                'user_business_expense',
                $expenseId,
                'Manual expense: '.ucfirst($category),
            );
        });
    }
}
PHP"
```

- [ ] **Step 2: Verify the file parses**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Services/Accounting/ExpenseJournalService.php"
```

Expected: `No syntax errors detected`

- [ ] **Step 3: Verify the service can be resolved by the container**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute='app(App\Services\Accounting\ExpenseJournalService::class); echo \"OK\";'"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Services/Accounting/ExpenseJournalService.php && git commit -m 'feat(accounting): add ExpenseJournalService for manual expense GL posting'"
```

---

## Task 8: Wire ExpenseJournalService into storeExpense

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/MyBusinessController.php` (around line 836)

Context: `storeExpense` inserts a row into `user_business_expenses` and currently returns just `{'success':true,'data':{'id':$id}}`. We need to (1) call `ExpenseJournalService::postManualExpense()` after insert, (2) save the returned `journal_entry_id`, (3) return the full expense row so the Flutter app can show the posted badge. GL posting failure must NOT block expense creation — wrap in try/catch and log.

- [ ] **Step 1: Add the import for ExpenseJournalService at the top of MyBusinessController**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && python3 -c \"
f = open('app/Http/Controllers/Api/MyBusinessController.php').read()
old = 'use App\Services\IncomeSummaryService;'
new = 'use App\Services\IncomeSummaryService;\nuse App\Services\Accounting\ExpenseJournalService;'
if old not in f:
    print('IMPORT LINE NOT FOUND — check exact line')
else:
    open('app/Http/Controllers/Api/MyBusinessController.php', 'w').write(f.replace(old, new, 1))
    print('OK')
\""
```

If the import line differs, find it first:
```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "grep -n 'use App.Services' /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/MyBusinessController.php | head -5"
```
Then add the import after any existing `use App\Services\...` line.

- [ ] **Step 2: Replace the storeExpense return statement**

Find the current return line in `storeExpense`:
```php
return response()->json(['success' => true, 'data' => ['id' => $id]], 201);
```

Replace with the GL wiring + full-row response:

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && python3 -c \"
f = open('app/Http/Controllers/Api/MyBusinessController.php').read()
old = \"        return response()->json(['success' => true, 'data' => ['id' => \\\$id]], 201);
    }

    public function uploadExpenseReceipt\"
new = \"        // Post to GL — failure must not break expense creation
        try {
            \\\$entry = app(ExpenseJournalService::class)->postManualExpense(
                (int) \\\$r->input('user_id'),
                (float) \\\$r->input('amount'),
                \\\$r->input('category', 'other'),
                \\\$id
            );
            DB::table('user_business_expenses')->where('id', \\\$id)->update([
                'journal_entry_id' => \\\$entry->id,
                'updated_at'       => now(),
            ]);
        } catch (\\\Throwable \\\$e) {
            \\\Log::warning('ExpenseJournalService failed for expense '.\\\$id.': '.\\\$e->getMessage());
        }

        \\\$expense = DB::table('user_business_expenses')->where('id', \\\$id)->first();
        return response()->json(['success' => true, 'data' => \\\$expense], 201);
    }

    public function uploadExpenseReceipt\"
if old not in f:
    print('PATTERN NOT FOUND — check whitespace carefully')
else:
    open('app/Http/Controllers/Api/MyBusinessController.php', 'w').write(f.replace(old, new, 1))
    print('OK')
\""
```

- [ ] **Step 3: Verify the file parses**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "php -l /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/MyBusinessController.php"
```

Expected: `No syntax errors detected`

- [ ] **Step 4: End-to-end test — post a manual expense via curl**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "curl -s -X POST 'http://localhost/api/v1/business/1/expenses' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{\"user_id\":5,\"amount\":50000,\"category\":\"rent\",\"description\":\"Office rent April\",\"date\":\"2026-04-18\"}' | python3 -m json.tool"
```

Replace `<token>` with a valid auth token from the database:
```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute='echo DB::table(\"personal_access_tokens\")->where(\"tokenable_id\",5)->value(\"token\");'"
```

Expected response includes `journal_entry_id` as a non-null integer and `success: true`.

- [ ] **Step 5: Verify journal entry was posted**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute='
\$e = DB::table(\"user_business_expenses\")->latest()->first();
echo \"expense journal_entry_id=\".\$e->journal_entry_id.PHP_EOL;
\$je = DB::table(\"journal_entries\")->find(\$e->journal_entry_id);
echo \"entry description=\".\$je->description.PHP_EOL;
\$lines = DB::table(\"journal_lines\")->where(\"journal_entry_id\",\$je->id)->get();
foreach(\$lines as \$l) { echo \"  debit=\".\$l->debit.\" credit=\".\$l->credit.\" acct=\".\$l->book_account_id.PHP_EOL; }
'"
```

Expected: 2 lines — one debit to the expense account, one credit to WALLET_CASH (1010).

- [ ] **Step 6: Commit**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && git add app/Http/Controllers/Api/MyBusinessController.php && git commit -m 'feat(expenses): wire ExpenseJournalService into storeExpense, return full row'"
```

---

## Task 9: End-to-end shop order GL verification

**Files:** None — verification only using existing `shop:show-journals` artisan command.

Context: After Tasks 4–6, a completed shop order should show 1840 in the buyer book (not 2110 or 3140). This task verifies the full posting chain is correct on a real order.

- [ ] **Step 1: Place a test order**

Use an existing test flow or the API directly. Requires two users (buyer + seller), a product, and sufficient wallet balance.

- [ ] **Step 2: Complete the order**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "curl -s -X PUT 'http://localhost/api/v1/shop/orders/<order_id>/status' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{\"user_id\":<seller_id>,\"status\":\"completed\"}' | python3 -m json.tool"
```

- [ ] **Step 3: Run shop:show-journals to verify all three books**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan shop:show-journals"
```

Expected output for buyer book:
- Entry 1 (at payment): Dr 1840 ADVANCE PAYMENTS, Cr 1010 WALLET_CASH — balanced ✓
- Entry 2 (at completion): Dr 5330 GOODS, Dr 5332 DELIVERY, Dr 5334 FEE, Dr 1535 INPUT_VAT, Cr 1840 ADVANCE PAYMENTS — balanced ✓
- No 3140 RETAINED_EARNINGS entries
- No 2110 MEMBER_DEPOSITS entries in shop flows

Expected for seller book: unchanged — Dr 1010, Dr 5342, Dr 1535, Cr 4520, Cr 2525 — balanced ✓
Expected for platform book: unchanged — Dr 1010, Cr 4215, Cr 2525 — balanced ✓

---

## Task 10: Add journalEntryId to Expense model (Flutter)

**Files:**
- Modify: `lib/business/models/business_models.dart` (lines 1290–1351)

- [ ] **Step 1: Add journalEntryId field to Expense class**

In `lib/business/models/business_models.dart`, find the `Expense` class (line 1290) and add the field:

```dart
class Expense {
  final int? id;
  final int? businessId;
  final ExpenseCategory category;
  final String? description;
  final double amount;
  final DateTime? date;
  final String? receiptPhotoUrl;
  final String? vendorName;
  final String? paymentMethod;
  final String? reference;
  final bool isRecurring;
  final String? notes;
  final DateTime? createdAt;
  final int? journalEntryId;   // ← ADD THIS

  Expense({
    this.id,
    this.businessId,
    this.category = ExpenseCategory.other,
    this.description,
    this.amount = 0,
    this.date,
    this.receiptPhotoUrl,
    this.vendorName,
    this.paymentMethod,
    this.reference,
    this.isRecurring = false,
    this.notes,
    this.createdAt,
    this.journalEntryId,   // ← ADD THIS
  });
```

- [ ] **Step 2: Add journalEntryId to fromJson**

In `Expense.fromJson`, add after `createdAt`:

```dart
journalEntryId: _parseInt(json['journal_entry_id']),
```

- [ ] **Step 3: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/business/models/business_models.dart 2>&1 | head -20
```

Expected: no errors related to Expense class.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/business/models/business_models.dart && git commit -m "feat(expenses): add journalEntryId to Expense model"
```

---

## Task 11: Update ExpensesPage — Swahili labels, posted badge, mounted guard

**Files:**
- Modify: `lib/expenses/pages/expenses_page.dart`

- [ ] **Step 1: Fix the missing mounted guard in _load()**

In `_load()` (around line 44), the first `setState` at line 46 is not guarded. Add the guard:

Current code (line 44–49):
```dart
Future<void> _load() async {
  if (_token == null) return;
  setState(() {
    _loading = true;
    _error = null;
  });
```

Replace with:
```dart
Future<void> _load() async {
  if (_token == null) return;
  if (!mounted) return;
  setState(() {
    _loading = true;
    _error = null;
  });
```

- [ ] **Step 2: Add AppStringsScope import and make _categoryLabel bilingual**

Add import at top of file (after existing imports):
```dart
import '../../l10n/app_strings.dart';
```

Replace `_categoryLabel(ExpenseCategory c)` (lines 139–166) with:

```dart
String _categoryLabel(ExpenseCategory c, {bool isSwahili = false}) {
  switch (c) {
    case ExpenseCategory.rent:
      return isSwahili ? 'Kodi' : 'Rent';
    case ExpenseCategory.utilities:
      return isSwahili ? 'Huduma' : 'Utilities';
    case ExpenseCategory.supplies:
      return isSwahili ? 'Vifaa' : 'Supplies';
    case ExpenseCategory.transport:
      return isSwahili ? 'Usafiri' : 'Transport';
    case ExpenseCategory.salary:
      return isSwahili ? 'Mishahara' : 'Salary';
    case ExpenseCategory.marketing:
      return isSwahili ? 'Masoko' : 'Marketing';
    case ExpenseCategory.food:
      return isSwahili ? 'Chakula' : 'Food';
    case ExpenseCategory.communication:
      return isSwahili ? 'Mawasiliano' : 'Communication';
    case ExpenseCategory.maintenance:
      return isSwahili ? 'Matengenezo' : 'Maintenance';
    case ExpenseCategory.tax:
      return isSwahili ? 'Kodi ya Serikali' : 'Tax';
    case ExpenseCategory.insurance:
      return isSwahili ? 'Bima' : 'Insurance';
    case ExpenseCategory.other:
      return isSwahili ? 'Nyingine' : 'Other';
  }
}
```

- [ ] **Step 3: Thread isSwahili into call sites**

In the `build` method, extract `isSwahili` at the top:
```dart
@override
Widget build(BuildContext context) {
  final nf = NumberFormat('#,###', 'en');
  final df = DateFormat('dd/MM/yyyy');
  final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
```

Update all `_categoryLabel(c)` calls to `_categoryLabel(c, isSwahili: isSwahili)`.

There are two call sites:
1. Line 239: `_filterChip(c, _categoryLabel(c))` → `_filterChip(c, _categoryLabel(c, isSwahili: isSwahili))`
2. Inside `_buildExpenseCard` around line 444 and 454: pass `isSwahili` as a parameter to the method

Add `isSwahili` as a parameter to `_buildExpenseCard`:
```dart
Widget _buildExpenseCard(Expense e, NumberFormat nf, DateFormat df, bool isSwahili) {
```

And update the call on line 272:
```dart
...(_expenses.map((e) => _buildExpenseCard(e, nf, df, isSwahili))),
```

Update the two `_categoryLabel(e.category)` calls inside `_buildExpenseCard` to pass `isSwahili: isSwahili`.

- [ ] **Step 4: Add "In Ledger" badge to expense card**

In `_buildExpenseCard`, in the `Column` after the amount (around line 479), add the badge after the amount text:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      'TZS ${nf.format(e.amount)}',
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          fontSize: 13),
    ),
    if (e.journalEntryId != null)
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isSwahili ? 'Leja' : 'In Ledger',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _kPrimary.withValues(alpha: 0.7),
              letterSpacing: 0.3),
        ),
      ),
  ],
),
```

- [ ] **Step 5: Update "New Expense" and "No expenses" labels to be bilingual**

In `build`, update static string labels:

```dart
// "New Expense" pill button label:
label: isSwahili ? 'Matumizi Mapya' : 'New Expense',

// Empty state:
Text(isSwahili ? 'Hakuna matumizi' : 'No expenses yet', ...)
Text(isSwahili ? 'Bonyeza "Matumizi Mapya" kuingiza matumizi' : 'Use "New Expense" to record an expense', ...)

// Delete dialog:
title: Text(isSwahili ? 'Futa Matumizi?' : 'Delete Expense?'),
content: Text(isSwahili ? 'Hatua hii haiwezi kutenduliwa.' : 'This action cannot be undone.'),
// Cancel / Delete buttons keep their text (short enough to be universal)
```

- [ ] **Step 6: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/expenses/pages/expenses_page.dart 2>&1 | head -30
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/expenses/pages/expenses_page.dart lib/l10n/app_strings.dart && git commit -m "feat(expenses): Swahili labels, posted badge, mounted guard in ExpensesPage"
```

---

## Verification Checklist

After all tasks are complete, run through these checks:

- [ ] `php artisan shop:show-journals` on a completed order shows 1840 in buyer book, no 3140, no 2110 in shop flows
- [ ] POST `/business/{id}/expenses` response includes non-null `journal_entry_id`
- [ ] `user_business_expenses` row has `journal_entry_id` populated after store
- [ ] Journal entry has 2 lines: Dr expense COA, Cr 1010 — balanced
- [ ] Refund on a shop order: 1840 balance returns to 0, wallet balance restored
- [ ] Flutter `Expense.fromJson` parses `journal_entry_id` correctly
- [ ] Expense card shows "In Ledger" / "Leja" badge when `journalEntryId != null`
- [ ] Category labels show Swahili when language is set to Swahili
- [ ] `flutter analyze` reports no new errors
