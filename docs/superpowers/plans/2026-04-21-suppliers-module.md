# Suppliers Module — Move + Gap Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move supplier/PO pages to `lib/suppliers/`, create a barrel, update all import references, then fix 4 UX gaps: notes field in create-PO sheet, Send action for Draft POs, supplier tap detail, PO tap detail page.

**Architecture:**
- Models (`Supplier`, `PurchaseOrder`, etc.) stay in `lib/business/models/business_models.dart` — `PurchaseOrder.items` uses `InvoiceItem` from the same file; moving would create circular imports.
- Service methods stay in `lib/business/services/business_service.dart` — add `markPOSent` alongside existing `markPOReceived`/`cancelPO`.
- Only **pages** move to `lib/suppliers/pages/`.

**Tech Stack:** Flutter/Dart, `http` package, `intl`, `url_launcher` (already in pubspec), Laravel backend at `172.240.241.180`

**IMPORTANT CONSTRAINTS:**
- Do NOT use git — no commits, no branch operations.
- Work directly on main repo at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`.
- Run `flutter analyze` after each task to verify zero errors.
- `flutter analyze` exit code 1 with only `info`-level messages is acceptable — zero `error` or `warning` messages required.

---

## Context: Current State

### Files that currently exist (to be moved/updated):
- `lib/business/pages/suppliers_page.dart` — `SuppliersPage` widget
- `lib/business/pages/purchase_orders_page.dart` — `PurchaseOrdersPage` widget + `_QuickItem`

### Files that import the pages being moved:
- `lib/screens/profile/profile_screen.dart` lines 84–85:
  ```dart
  import '../../business/pages/suppliers_page.dart';
  import '../../business/pages/purchase_orders_page.dart';
  ```
- `lib/reminders/reminder_navigation.dart` lines 14, 16:
  ```dart
  import '../business/pages/purchase_orders_page.dart';
  import '../business/pages/suppliers_page.dart';
  ```

### Models (stay in business_models.dart, do NOT move):
- `Supplier` class
- `PurchaseOrderStatus` enum
- `_parsePOStatus` function
- `poStatusLabel` function
- `PurchaseOrder` class (uses `InvoiceItem` from same file)

### Service methods (stay in business_service.dart):
- `getSuppliers`, `addSupplier`, `updateSupplier`, `deleteSupplier`
- `createPurchaseOrder`, `getPurchaseOrders`, `markPOReceived`, `cancelPO`
- **To add:** `markPOSent`

### Backend (SSH: `root@172.240.241.180`, password `ZimaBlueApps`, path `/var/www/tajiri.zimasystems.com`):
- Existing routes: `POST /api/business/purchase-orders/{id}/received`, `POST /api/business/purchase-orders/{id}/cancel`
- **To add:** `POST /api/business/purchase-orders/{id}/send`

### 4 UX Gaps to fix:
1. **Notes field** — `notesCtrl` exists in `_showCreateSheet` but has no TextField in the UI
2. **Send Draft POs** — Draft POs show only "Cancel"; need a "Send" button + backend endpoint
3. **Supplier tap** — `ListTile` has no `onTap`; tapping a supplier should open a detail bottom sheet
4. **PO tap detail** — tapping a PO card does nothing; should open a full detail view with items, notes, totals, actions

---

## Task 1: Move pages to lib/suppliers/ and update all references

**Files:**
- Create: `lib/suppliers/suppliers.dart`
- Create: `lib/suppliers/pages/suppliers_page.dart` (content from business/pages/suppliers_page.dart, imports updated)
- Create: `lib/suppliers/pages/purchase_orders_page.dart` (content from business/pages/purchase_orders_page.dart, imports updated)
- Delete: `lib/business/pages/suppliers_page.dart`
- Delete: `lib/business/pages/purchase_orders_page.dart`
- Modify: `lib/screens/profile/profile_screen.dart` — update 2 import lines
- Modify: `lib/reminders/reminder_navigation.dart` — update 2 import lines

- [ ] **Step 1: Create lib/suppliers/pages/ directory and move suppliers_page.dart**

  Create `lib/suppliers/pages/suppliers_page.dart` with this content (imports updated to point at business module):

  ```dart
  // lib/suppliers/pages/suppliers_page.dart
  import 'package:flutter/material.dart';
  import '../../l10n/app_strings_scope.dart';
  import '../../services/local_storage_service.dart';
  import '../../business/models/business_models.dart';
  import '../../business/services/business_service.dart';
  ```
  Then copy the rest of `lib/business/pages/suppliers_page.dart` unchanged after the imports. The class names and logic are identical.

- [ ] **Step 2: Move purchase_orders_page.dart**

  Create `lib/suppliers/pages/purchase_orders_page.dart` with updated imports:
  ```dart
  // lib/suppliers/pages/purchase_orders_page.dart
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import '../../l10n/app_strings_scope.dart';
  import '../../services/local_storage_service.dart';
  import '../../business/models/business_models.dart';
  import '../../business/services/business_service.dart';
  ```
  Then copy the rest unchanged.

- [ ] **Step 3: Create barrel lib/suppliers/suppliers.dart**

  ```dart
  // lib/suppliers/suppliers.dart
  export 'pages/suppliers_page.dart' show SuppliersPage;
  export 'pages/purchase_orders_page.dart' show PurchaseOrdersPage;
  ```

- [ ] **Step 4: Delete old files**

  Delete `lib/business/pages/suppliers_page.dart` and `lib/business/pages/purchase_orders_page.dart`.

- [ ] **Step 5: Update imports in profile_screen.dart**

  Replace:
  ```dart
  import '../../business/pages/suppliers_page.dart';
  import '../../business/pages/purchase_orders_page.dart';
  ```
  With:
  ```dart
  import '../../suppliers/suppliers.dart';
  ```

- [ ] **Step 6: Update imports in reminder_navigation.dart**

  Replace:
  ```dart
  import '../business/pages/purchase_orders_page.dart';
  import '../business/pages/suppliers_page.dart';
  ```
  With:
  ```dart
  import '../suppliers/suppliers.dart';
  ```

- [ ] **Step 7: Verify zero errors**

  ```bash
  flutter analyze lib/suppliers/ lib/screens/profile/profile_screen.dart lib/reminders/reminder_navigation.dart
  ```
  Expected: No errors or warnings. Info messages acceptable.

---

## Task 2: Add markPOSent service method + backend endpoint

**Files:**
- Modify: `lib/business/services/business_service.dart` — add `markPOSent`
- Modify backend: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/MyBusinessController.php`
- Modify backend: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Add markPOSent to business_service.dart**

  Add after `cancelPO` (around line 1403):
  ```dart
  static Future<BusinessResult<void>> markPOSent(
      String token, int poId) async {
    try {
      final url = '$_baseUrl/business/purchase-orders/$poId/send';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Agizo limetumwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }
  ```

- [ ] **Step 2: Add backend controller method**

  SSH into server and add `sendPO` method to `MyBusinessController.php` after the `cancelPO` method:
  ```php
  public function sendPO($id)
  {
      DB::table('user_business_purchase_orders')
          ->where('id', $id)
          ->where('status', 'draft')
          ->update(['status' => 'sent', 'updated_at' => now()]);
      return response()->json(['success' => true, 'message' => 'Purchase order sent']);
  }
  ```

- [ ] **Step 3: Add backend route**

  In `routes/api.php`, after the line `Route::post("/purchase-orders/{id}/cancel", ...)`, add:
  ```php
  Route::post("/purchase-orders/{id}/send", [\App\Http\Controllers\Api\MyBusinessController::class, 'sendPO']);
  ```

- [ ] **Step 4: Test endpoint**

  ```bash
  sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan route:list 2>/dev/null | grep 'purchase-orders.*send'"
  ```
  Expected: route listed.

---

## Task 3: Fix all 4 UX gaps in the moved pages

**Files:**
- Modify: `lib/suppliers/pages/suppliers_page.dart`
- Modify: `lib/suppliers/pages/purchase_orders_page.dart`

### Gap 1: Notes field in create-PO sheet

In `_showCreateSheet`, the `notesCtrl` is declared and sent in the body but has no TextField. Add it just above the submit button:

```dart
const SizedBox(height: 10),
TextField(
  controller: notesCtrl,
  maxLines: 2,
  decoration: InputDecoration(
    hintText: _isSwahili ? 'Maelezo (Hiari)' : 'Notes (Optional)',
    filled: true,
    fillColor: _kBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  ),
  style: const TextStyle(fontSize: 13),
),
const SizedBox(height: 14),
// [existing submit button]
```

### Gap 2: Send action for Draft POs

In the PO list `itemBuilder`, the existing action row for draft/sent POs is:
```dart
if (po.status == PurchaseOrderStatus.sent || po.status == PurchaseOrderStatus.draft) ...[
  const SizedBox(height: 8),
  Row(children: [
    if (po.status == PurchaseOrderStatus.sent)
      _actionBtn('Received', Icons.check_rounded, () => _markReceived(po)),
    _actionBtn('Cancel', Icons.cancel_rounded, () => _cancelOrder(po)),
  ]),
],
```

Add a `_markSent` method and a "Send" button for drafts:

```dart
Future<void> _markSent(PurchaseOrder po) async {
  if (_token == null || po.id == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final res = await BusinessService.markPOSent(_token!, po.id!);
  if (mounted) {
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (_isSwahili ? 'Agizo limetumwa' : 'Order sent')
            : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
        backgroundColor: res.success ? null : Colors.red));
    if (res.success) _loadOrders();
  }
}
```

Update the action row:
```dart
if (po.status == PurchaseOrderStatus.sent)
  _actionBtn(_isSwahili ? 'Pokelewa' : 'Received',
      Icons.check_rounded, () => _markReceived(po)),
if (po.status == PurchaseOrderStatus.draft)
  _actionBtn(_isSwahili ? 'Tuma' : 'Send',
      Icons.send_rounded, () => _markSent(po)),
_actionBtn(_isSwahili ? 'Futa' : 'Cancel',
    Icons.cancel_rounded, () => _cancelOrder(po)),
```

### Gap 3: Supplier tap — detail bottom sheet

Add `onTap` to the supplier `ListTile` that calls `_showSupplierDetail(s)`. Add a `_showSupplierDetail` method:

```dart
void _showSupplierDetail(Supplier s) {
  showModalBottomSheet(
    context: context,
    backgroundColor: _kCardBg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Drag handle
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(s.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18, color: _kSecondary),
            onPressed: () { Navigator.pop(ctx); _showAddEditSheet(existing: s); },
          ),
        ]),
        const SizedBox(height: 16),
        if (s.phone != null && s.phone!.isNotEmpty)
          _detailRow(Icons.phone_rounded, s.phone!),
        if (s.email != null && s.email!.isNotEmpty)
          _detailRow(Icons.email_outlined, s.email!),
        if (s.address != null && s.address!.isNotEmpty)
          _detailRow(Icons.location_on_outlined, s.address!),
        if (s.tinNumber != null && s.tinNumber!.isNotEmpty)
          _detailRow(Icons.receipt_outlined, 'TIN: ${s.tinNumber}'),
        if (s.notes != null && s.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_isSwahili ? 'Maelezo' : 'Notes',
              style: const TextStyle(fontSize: 12, color: _kSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(s.notes!, style: const TextStyle(fontSize: 13, color: _kPrimary)),
        ],
        const SizedBox(height: 20),
      ]),
    ),
  );
}

Widget _detailRow(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(children: [
    Icon(icon, size: 16, color: _kSecondary),
    const SizedBox(width: 8),
    Expanded(child: Text(text,
        style: const TextStyle(fontSize: 13, color: _kPrimary),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]),
);
```

Then add `onTap: () => _showSupplierDetail(s),` to the `ListTile`.

### Gap 4: PO tap — detail page

Add `onTap` to the PO card `GestureDetector` (or wrap the existing `Container` in a `GestureDetector`) that navigates to `_PurchaseOrderDetailPage`. Add `_PurchaseOrderDetailPage` as a private class at the bottom of the file (after `_QuickItem`):

```dart
class _PurchaseOrderDetailPage extends StatelessWidget {
  final PurchaseOrder po;
  final bool sw;
  final VoidCallback onStatusChanged;

  const _PurchaseOrderDetailPage({
    required this.po,
    required this.sw,
    required this.onStatusChanged,
  });

  // ... (see Step 1 detail below)
}
```

The detail page shows:
- **AppBar** with PO number as title, status chip in subtitle area
- **Header card** (dark): supplier name, PO number, status
- **Items table**: description | qty | unit price | total — in a Card
- **Totals section**: subtotal, VAT (if > 0), total amount (bold)
- **Expected delivery** date row (if set)
- **Notes** section (if non-empty)
- **Action buttons** (full-width row at bottom):
  - Draft: "Send" + "Cancel"
  - Sent: "Mark Received" + "Cancel"
  - Received/Cancelled: nothing (read-only)

The page is stateless — it calls service methods and then calls `onStatusChanged()` to trigger a reload in the parent page.

- [ ] **Step 1: Implement Gap 1 (notes field)**

  In `lib/suppliers/pages/purchase_orders_page.dart`, locate `_showCreateSheet` and find the block ending with `const SizedBox(height: 14),` just before the `FilledButton`. Insert the notes TextField between the delivery date picker and `const SizedBox(height: 14)`:

  ```dart
  const SizedBox(height: 10),
  TextField(
    controller: notesCtrl,
    maxLines: 2,
    decoration: InputDecoration(
      hintText: _isSwahili ? 'Maelezo (Hiari)' : 'Notes (Optional)',
      filled: true,
      fillColor: _kBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    style: const TextStyle(fontSize: 13),
  ),
  ```

- [ ] **Step 2: Implement Gap 2 (Send action)**

  In `lib/suppliers/pages/purchase_orders_page.dart`:
  1. Add `_markSent` method after `_markReceived`:
     ```dart
     Future<void> _markSent(PurchaseOrder po) async {
       if (_token == null || po.id == null) return;
       final messenger = ScaffoldMessenger.of(context);
       final res = await BusinessService.markPOSent(_token!, po.id!);
       if (mounted) {
         messenger.showSnackBar(SnackBar(
             content: Text(res.success
                 ? (_isSwahili ? 'Agizo limetumwa' : 'Order sent')
                 : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
             backgroundColor: res.success ? null : Colors.red));
         if (res.success) _loadOrders();
       }
     }
     ```
  2. Update the action row in the list `itemBuilder` to add "Send" for drafts:
     ```dart
     if (po.status == PurchaseOrderStatus.sent)
       _actionBtn(_isSwahili ? 'Pokelewa' : 'Received',
           Icons.check_rounded, () => _markReceived(po)),
     if (po.status == PurchaseOrderStatus.draft)
       _actionBtn(_isSwahili ? 'Tuma' : 'Send',
           Icons.send_rounded, () => _markSent(po)),
     _actionBtn(_isSwahili ? 'Futa' : 'Cancel',
         Icons.cancel_rounded, () => _cancelOrder(po)),
     ```

- [ ] **Step 3: Implement Gap 3 (supplier tap detail sheet)**

  In `lib/suppliers/pages/suppliers_page.dart`:
  1. Add `_showSupplierDetail(Supplier s)` method
  2. Add `_detailRow(IconData, String)` helper widget method
  3. Add `onTap: () => _showSupplierDetail(s),` to the `ListTile`

- [ ] **Step 4: Implement Gap 4 (PO detail page)**

  In `lib/suppliers/pages/purchase_orders_page.dart`:
  1. Wrap the PO card `Container` in a `GestureDetector` with `onTap` that pushes `_PurchaseOrderDetailPage`
  2. Add `_PurchaseOrderDetailPage` class at bottom of file with full implementation:
     - AppBar with PO number title + back button
     - Dark header card: supplier name, PO number, status chip
     - Items ListView.separated (description | qty × price | line total)
     - Totals card: subtotal, VAT (if > 0), total amount
     - Delivery date row with calendar icon (if non-null)
     - Notes section (if non-empty)
     - Action buttons based on status: Send/Cancel for draft, Mark Received/Cancel for sent, nothing for received/cancelled
     - Action buttons call service methods directly (using `token` parameter) and call `Navigator.pop` + `onStatusChanged()`

  The class signature:
  ```dart
  class _PurchaseOrderDetailPage extends StatefulWidget {
    final PurchaseOrder po;
    final String token;
    final VoidCallback onStatusChanged;
    const _PurchaseOrderDetailPage({
      required this.po,
      required this.token,
      required this.onStatusChanged,
    });
    @override
    State<_PurchaseOrderDetailPage> createState() => _PurchaseOrderDetailPageState();
  }
  ```
  Use `StatefulWidget` so action button loading state can be managed.

- [ ] **Step 5: Verify all files compile**

  ```bash
  flutter analyze lib/suppliers/
  ```
  Expected: No errors or warnings. Info messages only.

---

## Final Verification

```bash
flutter analyze lib/suppliers/ lib/screens/profile/profile_screen.dart lib/reminders/reminder_navigation.dart
```
Expected: No errors or warnings.
