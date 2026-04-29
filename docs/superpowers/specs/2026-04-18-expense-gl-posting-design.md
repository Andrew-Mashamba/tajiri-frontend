# Expense GL Posting — Design Spec
_Date: 2026-04-18_

## Goal

Wire every money-out event in TAJIRI (app-triggered and manually entered) to proper double-entry GL postings using a professional prepayment clearing model. Fix the existing RETAINED_EARNINGS hack in the buyer shop posting. Ensure all users have an accounting book (personal or business) so nothing is silently dropped.

## Architecture

Two distinct posting patterns based on whether fulfilment is deferred:

**Pattern A — Deferred (marketplace, food, fuel, any "pay now, receive later"):**
- Step 1 at payment: cash leaves wallet, advance payment asset created (1840)
- Step 2 at fulfilment: advance cleared, specific expense accounts debited

**Pattern B — Immediate (manual expense entry, instant spend with no delivery):**
- Single entry: expense account debited, wallet cash credited

All GL posting happens server-side. Flutter never calls GL endpoints directly — it calls existing feature endpoints (ExpensesService, FoodService, etc.) and the backend posts to the ledger automatically.

---

## COA Change: New Account 1840

Add one leaf to the existing 1800 PREPAID EXPENSES category:

```
SUBCAT|1000|1800|1840|ADVANCE PAYMENTS — APP PURCHASES
```

**Why 1800 (asset), not 2000 (liability):** When the buyer prepays, they hold a *right to receive goods* — an asset on their books. The seller holds the liability (deferred revenue). Since we post to the buyer's book, the correct classification is an asset. This matches IFRS/IAS prepayment treatment.

**Why not 2120:** Code 2120 is already FIXED DEPOSITS under MEMBER DEPOSITS. It is occupied.

`BookProvisioner::provision()` already creates a `BookAccount` for every `CoaDefinition` row, so adding the new `coa_definitions` row is sufficient — all existing and new books get account 1840 automatically.

---

## Posting Model: All Books

### Marketplace Shop Order

**BUYER BOOK**

| Step | Trigger | Dr | Cr |
|---|---|---|---|
| 1 | Order placed (payment) | ADVANCE PAYMENTS 1840 — full amount | WALLET_CASH 1010 — full amount |
| 2 | Order completed | GOODS_EXPENSE 5330 — goods net | ADVANCE PAYMENTS 1840 — full amount |
| | | DELIVERY_EXPENSE 5332 — delivery net | |
| | | PLATFORM_FEE_EXPENSE 5334 — fee net | |
| | | INPUT_VAT 1535 — VAT portion | |
| Refund | Order cancelled | WALLET_CASH 1010 — full amount | ADVANCE PAYMENTS 1840 — full amount |

Account 1840 balance = 0 after completion or refund.

**SELLER BOOK** _(unchanged — already correct)_

| Trigger | Dr | Cr |
|---|---|---|
| Completion | WALLET_CASH 1010 (net received) | MISCELLANEOUS_INCOME 4520 (sales net ex VAT) |
| | MARKETPLACE_COMMISSION_EXPENSE 5342 (fee net) | OUTPUT_VAT_PAYABLE 2525 (output VAT) |
| | INPUT_VAT_RECOVERABLE 1535 (VAT on fee) | |

**PLATFORM BOOK** _(unchanged — already correct)_

| Trigger | Dr | Cr |
|---|---|---|
| Completion | WALLET_CASH 1010 (fee received) | TRANSACTION_FEES_REVENUE 4215 (fee net) |
| | | OUTPUT_VAT_PAYABLE 2525 (fee VAT) |

---

### Manual Business/Personal Expense (Pattern B)

Single entry, no clearing needed:

```
Dr  <EXPENSE_ACCOUNT>   5xxx   amount
Cr  WALLET_CASH         1010   amount
```

Category → COA mapping:

| Category | COA | Name |
|---|---|---|
| rent | 5710 | RENTAL PAYMENTS |
| utilities | 5720 | UTILITY EXPENSES |
| salary | 5110 | BASE SALARIES |
| transport | 5242 | TRANSPORTATION |
| supplies | 5616 | OFFICE SUPPLIES |
| marketing | 5328 | OTHER OPERATIONAL |
| food | 5860 | MEALS |
| communication | 5610 | TELEPHONE EXPENSES |
| maintenance | 5730 | MAINTENANCE COSTS |
| tax | 5320 | PROPERTY TAXES |
| insurance | 5326 | INSURANCE PREMIUMS |
| other | 5880 | OTHER CHARGES |

---

### App-Triggered Spend (Food, Fuel Delivery — Pattern A)

Same two-step clearing as marketplace:
- Step 1 at checkout payment: Dr 1840, Cr 1010
- Step 2 at delivery/fulfilment: Dr appropriate expense (5860 for food, 5242 for fuel transport), Cr 1840

---

## Backend Components

### 1. Database Migration
- Add `coa_definitions` row: code=1840, name="ADVANCE PAYMENTS — APP PURCHASES", major_code=1000, category_code=1800
- Add `journal_entry_id` nullable FK to `user_business_expenses` table

### 2. CoaAccountCodes.php
Add the following constants (most of these are new — the current file only has ~15 entries):

```php
// New clearing account
public const ADVANCE_PAYMENTS_APP = '1840';

// Expense category → COA mapping constants (all new)
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
public const FREIGHT                = '5870';
```

Keep existing constant (backward compat, but no new code should reference it for purchases):
```php
public const RETAINED_EARNINGS_UNAPPROPRIATED = '3140';
```

### 3. WalletLedgerService.php — modify two methods

**`postShopPurchase()`** — currently calls `postOutboundTotal()` which does Dr MEMBER_DEPOSITS (2110) / Cr WALLET_CASH (1010). Change to:
```php
// Dr ADVANCE_PAYMENTS_APP (1840), Cr WALLET_CASH (1010)
$this->journal->post($book, [
    ['code' => CoaAccountCodes::ADVANCE_PAYMENTS_APP, 'debit' => $total, 'credit' => 0],
    ['code' => CoaAccountCodes::WALLET_CASH, 'debit' => 0, 'credit' => $total],
], WalletTransaction::class, $txn->id, 'Shop payment — advance for goods not yet received');
```
Keep `syncWalletBalanceFromLedger()` call — it reads WALLET_CASH (1010) only, still correct.

**`postShopBuyerSpendAllocation()`** — change credit from RETAINED_EARNINGS_UNAPPROPRIATED (3140) to ADVANCE_PAYMENTS_APP (1840):
```php
// All debit lines unchanged (5330, 5332, 5334, 1535)
// Credit line: was 3140, now 1840
$lines[] = ['code' => CoaAccountCodes::ADVANCE_PAYMENTS_APP, 'debit' => 0, 'credit' => $sumDr];
```

**`postShopRefund()`** — currently Dr WALLET_CASH / Cr MEMBER_DEPOSITS. Change to:
```php
// Dr WALLET_CASH (1010), Cr ADVANCE_PAYMENTS_APP (1840)
```

### 4. ExpenseJournalService.php (new)

Handles all manual expense GL posting. Responsibilities:
- Resolve the correct `AccountingBook` for the user (business book if `businessId` supplied, else personal book)
- Auto-provision the book if it doesn't exist (calls `ensureUserBook()`)
- Map `category` string → COA code using the mapping table above
- Post single-entry: Dr expense COA, Cr WALLET_CASH (1010)
- Save `journal_entry_id` back to the `user_business_expenses` row

```php
class ExpenseJournalService
{
    private static array $categoryMap = [
        'rent'          => CoaAccountCodes::RENTAL_PAYMENTS,       // 5710
        'utilities'     => CoaAccountCodes::UTILITY_EXPENSES,      // 5720
        'salary'        => CoaAccountCodes::BASE_SALARIES,         // 5110
        'transport'     => CoaAccountCodes::TRANSPORTATION,        // 5242
        'supplies'      => CoaAccountCodes::OFFICE_SUPPLIES,       // 5616
        'marketing'     => CoaAccountCodes::OTHER_OPERATIONAL,     // 5328
        'food'          => CoaAccountCodes::MEALS,                  // 5860
        'communication' => CoaAccountCodes::TELEPHONE_EXPENSES,    // 5610
        'maintenance'   => CoaAccountCodes::MAINTENANCE_COSTS,     // 5730
        'tax'           => CoaAccountCodes::PROPERTY_TAXES,        // 5320
        'insurance'     => CoaAccountCodes::INSURANCE_PREMIUMS,    // 5326
        'other'         => CoaAccountCodes::OTHER_CHARGES,         // 5880
    ];

    public function postManualExpense(int $userProfileId, ?int $businessId, float $amount, string $category, int $expenseId): JournalEntry
    // ...
}
```

### 5. ExpenseController.storeExpense()

After saving the `user_business_expenses` row, call:
```php
$entry = app(ExpenseJournalService::class)->postManualExpense(
    $userProfileId, $businessId, $amount, $category, $expense->id
);
$expense->update(['journal_entry_id' => $entry->id]);
```

### 6. Food / Fuel delivery controllers

Add clearing entries at checkout (Dr 1840, Cr 1010) and expense recognition at delivery (Dr expense COA, Cr 1840). These follow the same Pattern A as shop orders. The food expense COA is 5860 (MEALS), fuel is 5242 (TRANSPORTATION).

### 7. Personal Book Auto-Creation

`WalletLedgerService::ensureUserBook()` already calls `AccountingBook::forUser()` + `BookProvisioner::provision()`. `ExpenseJournalService` uses the same method. No additional work needed — the book is created on first expense post if it doesn't exist.

---

## Frontend Changes

### lib/expenses/pages/expenses_page.dart
- Add Swahili labels via `AppStringsScope.of(context)?.isSwahili`
- Add `posted` badge on each expense card when `journal_entry_id != null`
- Fix missing `mounted` guard on `setState` in `_load()`

### lib/expenses/pages/add_expense_page.dart
- No structural changes — backend GL posts automatically on save

### lib/expenses/services/expenses_service.dart
- No changes — existing endpoints are correct

### App-wide expense callsites (food, fuel, shop)
- GL posting is server-side at fulfilment. No Flutter changes needed for GL.

---

## What Does NOT Change

- Seller book postings (`postMarketplaceSellerCredit`) — already correct
- Platform book postings — already correct
- P2P transfer postings (`postPeerTransfer`) — no goods, no clearing needed
- Ad spend postings (`postAdSpendAndPlatformRevenue`) — already uses AD_WALLET (1020) correctly
- Wallet deposit/withdrawal postings — MEMBER_DEPOSITS (2110) stays correct for pure wallet flows

---

## Cancellation / Refund Safety

Every open 1840 entry (Step 1 posted, Step 2 not yet posted) represents an order pending delivery. On cancellation/refund: Dr WALLET_CASH (1010), Cr ADVANCE_PAYMENTS_APP (1840) — clears the asset and returns cash. 1840 balance = 0.

A non-zero 1840 balance at period end = open orders awaiting delivery. This is correct and auditable.

---

## Testing Checklist

- [ ] 1840 account exists in `coa_definitions` and is provisioned in all books
- [ ] Shop order placed: 1840 Dr = total, 1010 Cr = total, wallet.balance correct
- [ ] Shop order completed: 1840 Cr = total, 5330+5332+5334+1535 Dr = total, 1840 net = 0
- [ ] Shop order cancelled: 1840 Cr reversed, 1010 Dr restored, wallet.balance restored
- [ ] Manual expense saved: 5xxx Dr = amount, 1010 Cr = amount, `journal_entry_id` populated
- [ ] Seller book unchanged by buyer posting changes
- [ ] Platform book unchanged by buyer posting changes
- [ ] User with no business gets personal book provisioned on first expense
- [ ] `ShopShowOrderJournalsCommand` shows balanced entries with 1840 instead of 3140/2110
