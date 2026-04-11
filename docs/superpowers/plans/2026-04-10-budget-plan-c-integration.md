# Budget Plan C: Platform Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire the budget module into the entire TAJIRI platform — cross-module income/expenditure reporting, budget context in payment flows, Shangazi AI insights, FCM notifications, real-time updates.

**Architecture:** Existing services modified to report to IncomeService/ExpenditureService at the moment money moves. Budget context widget shown before payments. Shangazi reads budget summaries. FCM routes budget alerts.

**Tech Stack:** Flutter/Dart, existing TAJIRI services

**Depends on:** Plan A (backend + core services) and Plan B (screens) must be complete.

---

## Task 1: WalletService Integration

**File:** `lib/services/wallet_service.dart`

Add import at top of file, after existing imports:

```dart
import 'income_service.dart';
import 'expenditure_service.dart';
```

### Step 1.1: deposit() — record income on success

In the `deposit()` method (line 92), after the success check at line 113, add the income recording call. Insert AFTER the `return TransactionResult(success: true, ...)` block is constructed but BEFORE it returns. Restructure the success block:

- [ ] **Modify deposit() success path (line 112-119)**

Replace:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        final txn = WalletTransaction.fromJson(data['data']);
        // Report income to budget system
        IncomeService.recordIncome(
          userId: userId,
          amount: amount,
          source: 'top_up',
          description: 'Amana kupitia $provider',
          referenceId: 'wallet_deposit_${txn.id}',
          sourceModule: 'wallet',
          metadata: {'provider': provider, 'phone': phoneNumber},
        );
        return TransactionResult(success: true, transaction: txn);
      }
```

### Step 1.2: withdraw() — record expenditure on success

- [ ] **Modify withdraw() success path (line 145-150)**

Replace:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        final txn = WalletTransaction.fromJson(data['data']);
        // Report expenditure to budget system
        ExpenditureService.recordExpenditure(
          userId: userId,
          amount: amount,
          category: 'other',
          description: 'Kutoa pesa kupitia $provider',
          referenceId: 'wallet_withdraw_${txn.id}',
          sourceModule: 'wallet',
          metadata: {'provider': provider, 'phone': phoneNumber},
        );
        return TransactionResult(success: true, transaction: txn);
      }
```

### Step 1.3: transfer() — record expenditure for sender

- [ ] **Modify transfer() success path (line 192-197)**

Replace:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        final txn = WalletTransaction.fromJson(data['data']);
        // Report expenditure for sender (budget categorized by description)
        ExpenditureService.recordExpenditure(
          userId: userId,
          amount: amount,
          category: 'familia', // default for P2P transfers; user can recategorize
          description: description ?? 'Kutuma pesa',
          referenceId: 'wallet_transfer_${txn.id}',
          sourceModule: 'wallet',
          metadata: {
            if (recipientId != null) 'recipientId': recipientId,
            if (recipientPhone != null) 'recipientPhone': recipientPhone,
          },
        );
        // Note: Income for recipient is recorded server-side via webhook/event
        // because the recipient's userId is resolved by the backend
        return TransactionResult(success: true, transaction: txn);
      }
```

### Step 1.4: payRequest() — record expenditure for payer

- [ ] **Modify payRequest() success path (line 383-389)**

Replace:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        final txn = WalletTransaction.fromJson(data['data']);
        // Report expenditure for payer
        ExpenditureService.recordExpenditure(
          userId: userId,
          amount: txn.amount,
          category: 'other', // user can recategorize
          description: 'Malipo ya ombi #$requestId',
          referenceId: 'wallet_payreq_${txn.id}',
          sourceModule: 'wallet',
          metadata: {'requestId': requestId},
        );
        return TransactionResult(success: true, transaction: txn);
      }
```

---

## Task 2: ShopService Integration

**File:** `lib/services/shop_service.dart`

Add import at top, after existing imports (after line 10):

```dart
import 'income_service.dart';
import 'expenditure_service.dart';
```

### Step 2.1: createOrder() — record expenditure for buyer

- [ ] **Modify createOrder() success path (line 1062-1069)**

Replace:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final order = Order.fromJson(data['data']);
        _log('Order created: #${order.orderNumber} for product #$productId');
        return OrderResult(
          success: true,
          order: order,
        );
      }
```

With:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final order = Order.fromJson(data['data']);
        _log('Order created: #${order.orderNumber} for product #$productId');
        // Report expenditure for buyer
        ExpenditureService.recordExpenditure(
          userId: buyerId,
          amount: order.totalAmount,
          category: 'other', // Shop purchases; user can recategorize to mavazi, etc.
          description: 'Ununuzi: ${order.product?.title ?? 'Bidhaa #$productId'}',
          referenceId: 'shop_order_${order.id}',
          sourceModule: 'shop',
          envelopeTag: 'other',
          metadata: {
            'orderId': order.id,
            'orderNumber': order.orderNumber,
            'productId': productId,
            'productTitle': order.product?.title,
          },
        );
        return OrderResult(success: true, order: order);
      }
```

### Step 2.2: checkout() — record expenditure for each order in batch

- [ ] **Modify checkout() success path (line 1107-1113)**

Replace:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final orders = (data['data'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
        return OrderListResult(
          success: true,
          orders: orders,
        );
      }
```

With:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final orders = (data['data'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
        // Report expenditure for each order in the checkout batch
        for (final order in orders) {
          ExpenditureService.recordExpenditure(
            userId: buyerId,
            amount: order.totalAmount,
            category: 'other',
            description: 'Ununuzi: ${order.product?.title ?? 'Agizo #${order.id}'}',
            referenceId: 'shop_order_${order.id}',
            sourceModule: 'shop',
            envelopeTag: 'other',
            metadata: {
              'orderId': order.id,
              'orderNumber': order.orderNumber,
              'productTitle': order.product?.title,
            },
          );
        }
        return OrderListResult(success: true, orders: orders);
      }
```

### Step 2.3: confirmReceived() — record income for seller

- [ ] **Modify confirmReceived() success path (line 1395-1401)**

Replace:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        return OrderResult(
          success: true,
          order: Order.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 200 && data['success'] == true) {
        final order = Order.fromJson(data['data']);
        // Record income for the seller when buyer confirms receipt
        // The seller's userId comes from order.sellerId
        if (order.sellerId != null) {
          IncomeService.recordIncome(
            userId: order.sellerId!,
            amount: order.totalAmount,
            source: 'shop_sale',
            description: 'Mauzo: ${order.product?.title ?? 'Agizo #${order.id}'}',
            referenceId: 'shop_sale_${order.id}',
            sourceModule: 'shop',
            metadata: {
              'orderId': order.id,
              'buyerId': buyerId,
              'productTitle': order.product?.title,
            },
          );
        }
        return OrderResult(success: true, order: order);
      }
```

**Note:** If the `Order` model does not have a `sellerId` field, the income recording must be done server-side via backend webhook instead. Check `lib/models/shop_models.dart` — look for `sellerId`, `seller_id`, or `seller` in the Order model. If absent, skip the seller income call here and document that backend handles it.

---

## Task 3: SubscriptionService Integration

**File:** `lib/services/subscription_service.dart`

Add import at top, after existing imports:

```dart
import 'income_service.dart';
import 'expenditure_service.dart';
```

### Step 3.1: subscribe() — record expenditure for subscriber

- [ ] **Modify subscribe() success path (line 150-156)**

Replace:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        return SubscriptionResult(
          success: true,
          subscription: Subscription.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final sub = Subscription.fromJson(data['data']);
        // Report expenditure for subscriber
        ExpenditureService.recordExpenditure(
          userId: userId,
          amount: sub.price ?? 0,
          category: 'burudani',
          description: 'Usajili: ${sub.tierName ?? 'Creator subscription'}',
          referenceId: 'subscription_${sub.id}',
          sourceModule: 'subscription',
          envelopeTag: 'burudani',
          isRecurring: true,
          metadata: {
            'tierId': tierId,
            'tierName': sub.tierName,
            'creatorId': sub.creatorId,
          },
        );
        return SubscriptionResult(success: true, subscription: sub);
      }
```

**Note:** Adjust field names (`sub.price`, `sub.tierName`, `sub.creatorId`) based on actual `Subscription` model fields in `lib/models/subscription_models.dart`. If price is not on the model, pass the tier price from context or query it.

### Step 3.2: sendTip() — record expenditure for tipper

- [ ] **Modify sendTip() success path (line 302-304)**

Replace:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        return TipResult(success: true, message: 'Tuzo imetumwa!');
      }
```

With:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        // Report expenditure for tipper
        ExpenditureService.recordExpenditure(
          userId: userId,
          amount: amount,
          category: 'burudani',
          description: 'Tuzo kwa msanii #$creatorId',
          referenceId: 'tip_${DateTime.now().millisecondsSinceEpoch}_${creatorId}',
          sourceModule: 'subscription',
          envelopeTag: 'burudani',
          metadata: {
            'creatorId': creatorId,
            'message': message,
          },
        );
        return TipResult(success: true, message: 'Tuzo imetumwa!');
      }
```

### Step 3.3: Creator income — handled server-side

Creator income from subscriptions and tips is recorded server-side because:
1. Subscription payments are processed asynchronously (monthly renewals)
2. The platform takes a commission before crediting the creator
3. The creator's net amount is determined by the backend

The backend should call `POST /budget/income` when crediting the creator's wallet. No frontend change needed for creator income from subscriptions/tips.

---

## Task 4: ContributionService Integration

**File:** `lib/services/contribution_service.dart`

Add import at top, after existing imports:

```dart
import 'income_service.dart';
import 'expenditure_service.dart';
```

### Step 4.1: donateToCampaign() — record expenditure for donor

- [ ] **Modify donateToCampaign() success path (line 367-373)**

Replace:
```dart
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          return DonationResult(
            success: true,
            donation: Donation.fromJson(data['data']),
            message: data['message'],
          );
        }
      }
```

With:
```dart
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          final donation = Donation.fromJson(data['data']);
          // Report expenditure for donor
          // Note: donateToCampaign does not have userId param — it is implied by auth.
          // We use the donation object to get the amount, or fall back to the input amount.
          ExpenditureService.recordExpenditure(
            userId: donation.userId ?? 0, // Adjust based on actual Donation model
            amount: amount,
            category: 'michango',
            description: 'Mchango kwa kampeni #$campaignId',
            referenceId: 'donation_${donation.id}',
            sourceModule: 'michango',
            envelopeTag: 'michango',
            metadata: {
              'campaignId': campaignId,
              'donationId': donation.id,
              'isAnonymous': isAnonymous,
            },
          );
          return DonationResult(
            success: true,
            donation: donation,
            message: data['message'],
          );
        }
      }
```

**Important:** Check the `Donation` model in `lib/models/contribution_models.dart` for the `userId` field. If absent, the userId must be passed into `donateToCampaign()` as a parameter (add it), or resolved from `LocalStorageService` at call time.

### Step 4.2: requestWithdrawal() — record income for campaign organizer

- [ ] **Modify requestWithdrawal() success path (line 447-453)**

Replace:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        return WithdrawalResult(
          success: true,
          withdrawal: Withdrawal.fromJson(data['data']),
        );
      }
```

With:
```dart
      if (response.statusCode == 201 && data['success'] == true) {
        final withdrawal = Withdrawal.fromJson(data['data']);
        // Report income for campaign organizer
        // The organizer's userId is resolved from LocalStorageService at the call site,
        // or from the withdrawal object if available.
        IncomeService.recordIncome(
          userId: withdrawal.userId ?? 0, // Adjust based on Withdrawal model
          amount: amount,
          source: 'michango_withdrawal',
          description: 'Kutoa pesa kutoka kampeni #$campaignId',
          referenceId: 'michango_withdraw_${withdrawal.id}',
          sourceModule: 'michango',
          metadata: {
            'campaignId': campaignId,
            'destinationType': destinationType,
          },
        );
        return WithdrawalResult(success: true, withdrawal: withdrawal);
      }
```

**Note:** Check `Withdrawal` model for `userId` field. If absent, add `required int userId` parameter to `requestWithdrawal()` method signature.

---

## Task 5: TajirikaService Integration

**File:** `lib/tajirika/services/tajirika_service.dart`

Add import at top, after existing imports:

```dart
import '../../services/income_service.dart';
```

### Step 5.1: reportJobCompleted() — record income for partner

- [ ] **Modify reportJobCompleted() success path (line 870-873)**

Replace:
```dart
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
```

With:
```dart
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        // Report income for Tajirika partner
        IncomeService.recordIncome(
          userId: partnerId, // partnerId is the user's partner profile ID
          amount: earnings,
          source: 'tajirika_job',
          description: 'Kazi imekamilika: $module #$jobId',
          referenceId: 'tajirika_job_${jobId}',
          sourceModule: 'tajirika',
          metadata: {
            'module': module,
            'jobId': jobId,
            'rating': rating,
          },
        );
        return TajirikaResult(success: true);
      }
```

**Note:** `partnerId` here is the Tajirika partner ID, not necessarily the user ID. Check if the partner profile maps 1:1 to a user. If `partnerId != userId`, resolve the userId from context or add it as a parameter.

### Step 5.2: requestPayout() — record income for partner

- [ ] **Modify requestPayout() success path (line 758-760)**

Replace:
```dart
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
```

With:
```dart
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        // Report income for Tajirika partner payout
        IncomeService.recordIncome(
          userId: userId,
          amount: amount,
          source: 'tajirika_payout',
          description: 'Malipo ya Tajirika — $method',
          referenceId: 'tajirika_payout_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'tajirika',
          metadata: {'method': method, 'amount': amount},
        );
        return TajirikaResult(success: true);
      }
```

---

## Task 6: AdService + LiveStreamService + EventTicketService Integration

### Step 6.1: AdService — depositAdBalance() records expenditure

**File:** `lib/services/ad_service.dart`

Add import after existing imports (after line 8):

```dart
import 'expenditure_service.dart';
import 'income_service.dart';
```

- [ ] **Modify depositAdBalance() (line 373-392)**

Replace:
```dart
  static Future<Map<String, dynamic>> depositAdBalance(
    String? token,
    double amount,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/balance/deposit');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({'amount': amount}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      return body;
    } catch (e) {
      _log('depositAdBalance error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
```

With:
```dart
  static Future<Map<String, dynamic>> depositAdBalance(
    String? token,
    double amount,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/balance/deposit');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({'amount': amount}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      // Report expenditure for ad budget deposit
      if (body['success'] == true) {
        final storage = await LocalStorageService.getInstance();
        final userId = storage.getUser()?.userId;
        if (userId != null) {
          ExpenditureService.recordExpenditure(
            userId: userId,
            amount: amount,
            category: 'biashara',
            description: 'Bajeti ya matangazo',
            referenceId: 'ad_deposit_${DateTime.now().millisecondsSinceEpoch}',
            sourceModule: 'ad',
            envelopeTag: 'biashara',
            metadata: {'type': 'ad_budget_deposit'},
          );
        }
      }
      return body;
    } catch (e) {
      _log('depositAdBalance error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
```

### Step 6.2: AdService — reportAdMobRevenue() records income

- [ ] **Modify reportAdMobRevenue() success path (line 96-119)**

Replace:
```dart
  static Future<bool> reportAdMobRevenue(
    String? token,
    int userId,
    String placement,
    double revenue,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/ads/admob-revenue');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'placement': placement,
          'revenue': revenue,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _log('reportAdMobRevenue error: $e');
      return false;
    }
  }
```

With:
```dart
  static Future<bool> reportAdMobRevenue(
    String? token,
    int userId,
    String placement,
    double revenue,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/ads/admob-revenue');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'placement': placement,
          'revenue': revenue,
        }),
      );
      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success && revenue > 0) {
        // Report ad revenue as income
        IncomeService.recordIncome(
          userId: userId,
          amount: revenue,
          source: 'ad_revenue',
          description: 'Mapato ya matangazo — $placement',
          referenceId: 'admob_${placement}_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'ad',
          metadata: {'placement': placement},
        );
      }
      return success;
    } catch (e) {
      _log('reportAdMobRevenue error: $e');
      return false;
    }
  }
```

### Step 6.3: LiveStreamService — sendGift() records expenditure for sender

**File:** `lib/services/livestream_service.dart`

Add import after existing imports (after line 4):

```dart
import 'expenditure_service.dart';
```

- [ ] **Modify sendGift() (line 380-396)**

Replace:
```dart
  Future<bool> sendGift(int streamId, int senderId, int giftId, {int quantity = 1, String? message}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/gifts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'gift_id': giftId,
          'quantity': quantity,
          if (message != null) 'message': message,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
```

With:
```dart
  Future<bool> sendGift(int streamId, int senderId, int giftId, {int quantity = 1, String? message, double? giftValue}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/gifts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'gift_id': giftId,
          'quantity': quantity,
          if (message != null) 'message': message,
        }),
      );
      final success = response.statusCode == 201;
      if (success && giftValue != null && giftValue > 0) {
        // Report expenditure for gift sender
        ExpenditureService.recordExpenditure(
          userId: senderId,
          amount: giftValue * quantity,
          category: 'burudani',
          description: 'Zawadi ya mubashara #$streamId',
          referenceId: 'stream_gift_${streamId}_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'livestream',
          envelopeTag: 'burudani',
          metadata: {
            'streamId': streamId,
            'giftId': giftId,
            'quantity': quantity,
          },
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }
```

**Note:** `giftValue` is a new optional parameter. The caller (live stream viewer screen) must pass the gift's TZS value when calling sendGift(). If the gift value is not available at the call site, extract it from the `VirtualGift` object that the user selected.

### Step 6.4: EventTicketService — purchaseTicket() records expenditure

**File:** `lib/events/services/ticket_service.dart`

Add import at top:

```dart
import '../../services/expenditure_service.dart';
```

- [ ] **Modify purchaseTicket() success path (line 92-114)**

Replace:
```dart
  Future<TicketPurchaseResult> purchaseTicket({
    required int eventId,
    required int tierId,
    required int quantity,
    required PaymentMethod paymentMethod,
    String? phoneNumber,
    String? promoCode,
    List<GuestInfo>? guests,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/tickets/purchase', data: {
        'tier_id': tierId,
        'quantity': quantity,
        'payment_method': paymentMethod.apiValue,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (promoCode != null) 'promo_code': promoCode,
        if (guests != null) 'guests': guests.map((g) => g.toJson()).toList(),
      });
      return TicketPurchaseResult.fromJson(response.data);
    } catch (e) {
      return TicketPurchaseResult(success: false, message: 'Imeshindwa kununua tiketi: $e');
    }
  }
```

With:
```dart
  Future<TicketPurchaseResult> purchaseTicket({
    required int eventId,
    required int tierId,
    required int quantity,
    required PaymentMethod paymentMethod,
    String? phoneNumber,
    String? promoCode,
    List<GuestInfo>? guests,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/tickets/purchase', data: {
        'tier_id': tierId,
        'quantity': quantity,
        'payment_method': paymentMethod.apiValue,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (promoCode != null) 'promo_code': promoCode,
        if (guests != null) 'guests': guests.map((g) => g.toJson()).toList(),
      });
      final result = TicketPurchaseResult.fromJson(response.data);
      // Report expenditure for ticket buyer
      if (result.success && result.totalAmount != null && result.totalAmount! > 0) {
        final userId = _resolveUserId(); // Resolve from auth context
        if (userId != null) {
          ExpenditureService.recordExpenditure(
            userId: userId,
            amount: result.totalAmount!,
            category: 'burudani',
            description: 'Tiketi ya tukio #$eventId',
            referenceId: 'event_ticket_${result.ticketId ?? eventId}_${DateTime.now().millisecondsSinceEpoch}',
            sourceModule: 'events',
            envelopeTag: 'burudani',
            metadata: {
              'eventId': eventId,
              'tierId': tierId,
              'quantity': quantity,
            },
          );
        }
      }
      return result;
    } catch (e) {
      return TicketPurchaseResult(success: false, message: 'Imeshindwa kununua tiketi: $e');
    }
  }
```

**Note:** Check `TicketPurchaseResult` model for `totalAmount` and `ticketId` fields. Also check how `TicketService` resolves the current user — it likely stores a userId or reads from a Dio interceptor. Add a `_resolveUserId()` helper or pass userId as parameter.

---

## Task 7: Budget Context Widget

**File to create:** `lib/widgets/budget_context_banner.dart`

This is a lightweight, reusable widget that shows the relevant budget envelope balance before a payment. It queries `ExpenditureService.getSpendingPace()` for the given category and shows a small card.

- [ ] **Step 7.1: Create BudgetContextBanner widget**

```dart
// lib/widgets/budget_context_banner.dart

import 'package:flutter/material.dart';
import '../services/expenditure_service.dart';
import '../l10n/app_strings.dart';

/// Lightweight banner showing budget envelope balance before a payment.
/// Shows: envelope name, allocated, spent, remaining, and whether this
/// payment fits within the budget.
///
/// Usage:
///   BudgetContextBanner(
///     userId: userId,
///     category: 'chakula',
///     paymentAmount: 15000,
///   )
class BudgetContextBanner extends StatefulWidget {
  final int userId;
  final String category;
  final double paymentAmount;

  const BudgetContextBanner({
    super.key,
    required this.userId,
    required this.category,
    required this.paymentAmount,
  });

  @override
  State<BudgetContextBanner> createState() => _BudgetContextBannerState();
}

class _BudgetContextBannerState extends State<BudgetContextBanner> {
  SpendingPace? _pace;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadPace();
  }

  Future<void> _loadPace() async {
    try {
      final now = DateTime.now();
      final pace = await ExpenditureService.getSpendingPace(
        userId: widget.userId,
        category: widget.category,
        year: now.year,
        month: now.month,
      );
      if (!mounted) return;
      setState(() {
        _pace = pace;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_error || _pace == null) return const SizedBox.shrink();

    final remaining = _pace!.remaining;
    final fitsInBudget = remaining >= widget.paymentAmount;
    final overBy = widget.paymentAmount - remaining;
    final isSwahili = AppStrings.isSwahili;

    // Status colors
    final Color statusColor;
    final IconData statusIcon;
    if (fitsInBudget) {
      statusColor = const Color(0xFF4CAF50); // green
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFF44336); // red
      statusIcon = Icons.warning_rounded;
    }

    final envelopeName = _categoryLabel(widget.category, isSwahili);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fitsInBudget
                  ? '$envelopeName: TZS ${_format(remaining)} ${isSwahili ? "imebaki" : "remaining"}'
                  : '$envelopeName: TZS ${_format(overBy)} ${isSwahili ? "zaidi ya bajeti" : "over budget"}',
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Map category key to human-readable envelope name.
  String _categoryLabel(String category, bool isSwahili) {
    const labels = {
      'kodi': ['Rent/Housing', 'Kodi'],
      'chakula': ['Food', 'Chakula'],
      'usafiri': ['Transport', 'Usafiri'],
      'umeme_maji': ['Utilities', 'Umeme na Maji'],
      'simu_intaneti': ['Phone & Internet', 'Simu na Intaneti'],
      'afya': ['Health', 'Afya'],
      'ada_shule': ['Education', 'Ada/Shule'],
      'watoto': ['Children', 'Watoto'],
      'familia': ['Family', 'Familia'],
      'mavazi': ['Clothing', 'Mavazi'],
      'urembo': ['Personal Care', 'Urembo'],
      'burudani': ['Entertainment', 'Burudani'],
      'dini': ['Faith & Giving', 'Dini'],
      'michango': ['Contributions', 'Michango'],
      'akiba': ['Savings', 'Akiba'],
      'deni': ['Debt', 'Deni'],
      'bima': ['Insurance', 'Bima'],
      'dharura': ['Emergency', 'Dharura'],
      'biashara': ['Business', 'Biashara'],
    };
    final pair = labels[category];
    if (pair != null) return isSwahili ? pair[1] : pair[0];
    return category;
  }
}
```

### Step 7.2: Wire BudgetContextBanner into payment confirmation screens

- [ ] **Add to Shop checkout confirmation** — In the checkout/order confirmation dialog or screen, add `BudgetContextBanner(userId: userId, category: 'other', paymentAmount: totalAmount)` above the "Confirm" button.

- [ ] **Add to Wallet transfer confirmation** — In the transfer confirmation dialog, add `BudgetContextBanner(userId: userId, category: 'familia', paymentAmount: amount)` above the "Send" button.

- [ ] **Add to Subscription subscribe screen** — Add `BudgetContextBanner(userId: userId, category: 'burudani', paymentAmount: tierPrice)` in the subscription confirmation flow.

- [ ] **Add to ContributionService donate screen** — Add `BudgetContextBanner(userId: userId, category: 'michango', paymentAmount: donationAmount)` in the donation confirmation.

- [ ] **Add to Event ticket purchase screen** — Add `BudgetContextBanner(userId: userId, category: 'burudani', paymentAmount: ticketPrice)` before ticket purchase confirmation.

- [ ] **Add to LiveStream gift screen** — Add `BudgetContextBanner(userId: userId, category: 'burudani', paymentAmount: giftValue)` in the gift selection dialog.

**Pattern for wiring:** Each payment confirmation screen should import `budget_context_banner.dart` and place the widget between the payment details and the confirm button. The widget loads its own data and shows nothing on error (graceful degradation).

---

## Task 8: Shangazi Tea Integration

### Step 8.1: Create getBudgetSummaryForAI() method

**File:** `lib/services/budget_service.dart`

Add this method to the existing `BudgetService` class, at the end before the closing brace:

- [ ] **Add getBudgetSummaryForAI() to BudgetService**

Add import at top of budget_service.dart:
```dart
import 'income_service.dart';
import 'expenditure_service.dart';
```

Add method:
```dart
  /// Returns a structured JSON summary of the user's budget for Shangazi AI.
  /// Called by TeaService before sending a message when budget context is needed.
  static Future<Map<String, dynamic>> getBudgetSummaryForAI(int userId) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // Fetch data in parallel
      final results = await Future.wait([
        IncomeService.getIncomeSummary(userId: userId, period: 'monthly'),
        ExpenditureService.getExpenditureSummary(userId: userId, period: 'monthly'),
        ExpenditureService.getExpenditureByCategory(userId: userId, year: year, month: month),
        ExpenditureService.getRecurringExpenses(userId),
        ExpenditureService.getUpcomingExpenses(userId),
      ]);

      final incomeSummary = results[0] as IncomeSummary;
      final expenditureSummary = results[1] as ExpenditureSummary;
      final byCategory = results[2] as Map<String, double>;
      final recurring = results[3] as List<RecurringExpense>;
      final upcoming = results[4] as List<UpcomingExpense>;

      final daysInMonth = DateTime(year, month + 1, 0).day;
      final daysElapsed = now.day;
      final daysRemaining = daysInMonth - daysElapsed;

      return {
        'period': '${year}-${month.toString().padLeft(2, '0')}',
        'days_elapsed': daysElapsed,
        'days_remaining': daysRemaining,
        'income': {
          'total': incomeSummary.totalIncome,
          'by_source': incomeSummary.bySource,
          'trend_percent': incomeSummary.trend,
        },
        'spending': {
          'total': expenditureSummary.totalSpent,
          'by_category': byCategory,
          'trend_percent': expenditureSummary.trend,
        },
        'savings_rate': incomeSummary.totalIncome > 0
            ? ((incomeSummary.totalIncome - expenditureSummary.totalSpent) / incomeSummary.totalIncome * 100).round()
            : 0,
        'daily_spend_average': daysElapsed > 0
            ? (expenditureSummary.totalSpent / daysElapsed).round()
            : 0,
        'upcoming_expenses': upcoming.take(5).map((e) => {
          'description': e.description,
          'amount': e.amount,
          'expected_date': e.expectedDate.toIso8601String(),
        }).toList(),
        'recurring_count': recurring.length,
        'top_categories': _topCategories(byCategory, 5),
      };
    } catch (e) {
      return {'error': 'Failed to load budget summary: $e'};
    }
  }

  static List<Map<String, dynamic>> _topCategories(Map<String, double> byCategory, int limit) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => {'category': e.key, 'amount': e.value}).toList();
  }
```

### Step 8.2: Modify TeaService to include budget context

**File:** `lib/services/tea_service.dart`

- [ ] **Modify startChat() to include budget context when user asks about spending**

Add import:
```dart
import 'budget_service.dart';
```

Modify `startChat()` — before the HTTP call, check if the message mentions budget/spending keywords and attach budget summary as context:

Replace the body construction (line 17-19):
```dart
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (conversationId != null) body['conversation_id'] = conversationId;
      if (userId != null) body['user_id'] = userId;
```

With:
```dart
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (conversationId != null) body['conversation_id'] = conversationId;
      if (userId != null) body['user_id'] = userId;

      // Attach budget context when user asks about money/spending/budget
      if (userId != null && message != null && _isBudgetQuery(message)) {
        try {
          final budgetSummary = await BudgetService.getBudgetSummaryForAI(userId);
          body['budget_context'] = budgetSummary;
        } catch (_) {
          // Graceful degradation — Shangazi can still respond without budget data
        }
      }
```

Add the keyword detection helper at the bottom of the class:

```dart
  /// Detect if user's message is asking about budget/spending/money.
  static bool _isBudgetQuery(String message) {
    final lower = message.toLowerCase();
    const keywords = [
      // Swahili
      'bajeti', 'matumizi', 'pesa', 'gharama', 'hifadhi', 'akiba',
      'mapato', 'mshahara', 'kodi', 'chakula', 'usafiri', 'bili',
      'nimebaki', 'nimetumia', 'nionyeshe', 'kiasi',
      // English
      'budget', 'spend', 'expense', 'income', 'saving', 'money',
      'earn', 'cost', 'afford', 'balance', 'remaining',
    ];
    return keywords.any((kw) => lower.contains(kw));
  }
```

---

## Task 9: FCM Budget Notifications

**File:** `lib/services/fcm_service.dart`

### Step 9.1: Add budget notification channel

- [ ] **Add budget Android notification channel in _createNotificationChannels() (after line 114)**

Add to the `channels` list:
```dart
      AndroidNotificationChannel(
        'budget',
        'Bajeti',
        description: 'Arifa za bajeti na matumizi',
        importance: Importance.high,
        playSound: true,
      ),
```

### Step 9.2: Add budget types to channel routing

- [ ] **Modify _getChannelForType() (after line 148)**

Add budget cases before the `default:` case:
```dart
      case 'budget_envelope_warning':
      case 'budget_over':
      case 'budget_pace_warning':
      case 'budget_income':
      case 'budget_weekly_digest':
      case 'budget_monthly_report':
      case 'budget_goal_milestone':
      case 'budget_streak':
      case 'budget_unallocated':
      case 'budget_recurring_upcoming':
        return 'budget';
```

### Step 9.3: Add budget notification titles

- [ ] **Modify _getTitleForType() (after line 191)**

Add budget cases before the `default:` case:
```dart
      case 'budget_envelope_warning':
        return data['envelope_name'] as String? ?? 'Bajeti';
      case 'budget_over':
        return data['envelope_name'] as String? ?? 'Bajeti imezidi';
      case 'budget_pace_warning':
        return 'Kasi ya matumizi';
      case 'budget_income':
        return 'Mapato mapya';
      case 'budget_weekly_digest':
        return 'Muhtasari wa wiki';
      case 'budget_monthly_report':
        return 'Ripoti ya mwezi';
      case 'budget_goal_milestone':
        return data['goal_name'] as String? ?? 'Lengo la akiba';
      case 'budget_streak':
        return 'Mfululizo wa bajeti';
      case 'budget_unallocated':
        return 'Pesa haijatengwa';
      case 'budget_recurring_upcoming':
        return 'Malipo yanakuja';
```

### Step 9.4: Add budget notification routing in _handlePayload()

- [ ] **Add budget routing in _handlePayload() (after line 410, before the game_challenge check)**

```dart
    // Budget notification types — navigate to budget screens
    if (type == 'budget_envelope_warning' || type == 'budget_over' || type == 'budget_pace_warning') {
      _openBudgetEnvelope(data, navigator);
      return;
    }
    if (type == 'budget_income' || type == 'budget_unallocated') {
      _openBudgetHome(navigator);
      return;
    }
    if (type == 'budget_weekly_digest' || type == 'budget_monthly_report') {
      _openBudgetReport(navigator);
      return;
    }
    if (type == 'budget_goal_milestone') {
      _openBudgetGoals(navigator);
      return;
    }
    if (type == 'budget_streak') {
      _openBudgetHome(navigator);
      return;
    }
    if (type == 'budget_recurring_upcoming') {
      _openBudgetRecurring(navigator);
      return;
    }
```

### Step 9.5: Add budget navigation helper methods

- [ ] **Add helper methods before the `_intFrom` method**

```dart
  /// Opens budget home screen.
  void _openBudgetHome(NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/budget');
    }
  }

  /// Opens budget envelope detail for a specific category.
  void _openBudgetEnvelope(Map<String, dynamic> data, NavigatorState navigator) {
    final envelopeId = _intFrom(data, 'envelope_id');
    if (envelopeId != null && navigator.mounted) {
      navigator.pushNamed('/budget/envelope/$envelopeId');
    } else {
      _openBudgetHome(navigator);
    }
  }

  /// Opens budget monthly report screen.
  void _openBudgetReport(NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/budget/report');
    }
  }

  /// Opens budget goals screen.
  void _openBudgetGoals(NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/budget/goals');
    }
  }

  /// Opens budget recurring expenses screen.
  void _openBudgetRecurring(NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/budget/recurring');
    }
  }
```

**Note:** These routes (`/budget`, `/budget/envelope/:id`, `/budget/report`, `/budget/goals`, `/budget/recurring`) must be registered in `lib/main.dart` in the `onGenerateRoute` handler. This should already be done in Plan B (screens). If not, add them.

---

## Task 10: LiveUpdateService Integration

**File:** `lib/services/live_update_service.dart`

### Step 10.1: Add BudgetUpdateEvent sealed class

- [ ] **Add after StoriesUpdateEvent (after line 38)**

```dart
/// Budget data changed — refresh budget screens.
/// Emitted when income or expenditure is recorded, or when envelope allocations change.
class BudgetUpdateEvent extends LiveUpdateEvent {
  final String? category; // which envelope category changed, if known
  const BudgetUpdateEvent([this.category]);
}
```

### Step 10.2: Add budget event handling in _onSnapshot switch

- [ ] **Add cases in the switch statement (after the 'stories_updated' case, before `default:`)**

```dart
      case 'budget_updated':
      case 'income_recorded':
      case 'expenditure_recorded':
        final category = payload?['category'] as String?;
        ev = BudgetUpdateEvent(category);
        break;
```

### Step 10.3: Subscribe to BudgetUpdateEvent in budget screens

This is done in the budget screens themselves (Plan B files). Each budget screen should add a listener:

```dart
// In budget screen initState():
_liveUpdateSubscription = LiveUpdateService.instance.stream
    .where((e) => e is BudgetUpdateEvent)
    .listen((_) {
      if (mounted) _refreshBudgetData();
    });

// In dispose():
_liveUpdateSubscription?.cancel();
```

**Screens to wire (verify these exist from Plan B):**
- [ ] `lib/screens/budget/budget_home_screen.dart` — refresh all data
- [ ] `lib/screens/budget/envelope_detail_screen.dart` — refresh transactions list
- [ ] `lib/screens/budget/monthly_report_screen.dart` — refresh report data

---

## Task 11: Remove Old BudgetService Sync Code

**File:** `lib/services/budget_service.dart`

The old sync methods pulled data from other services in batch. Now each service reports to IncomeService/ExpenditureService in real-time. The old sync code is dead weight and can cause double-counting.

- [ ] **Step 11.1: Delete syncFromTajiri() method (lines 122-145)**

Remove the entire `syncFromTajiri()` method.

- [ ] **Step 11.2: Delete _syncWalletTransactions() method (lines 148-188)**

Remove the entire method.

- [ ] **Step 11.3: Delete _syncCreatorEarnings() method (lines 191-221)**

Remove the entire method.

- [ ] **Step 11.4: Delete _syncShopSales() method (lines 224-253)**

Remove the entire method.

- [ ] **Step 11.5: Delete _syncShopPurchases() method (lines 256-280)**

Remove the entire method.

- [ ] **Step 11.6: Delete _syncMichangoReceived() method (lines 283-308)**

Remove the entire method.

- [ ] **Step 11.7: Remove unused fields and imports**

Remove the service instances that were only used by the sync methods. At the top of BudgetService, remove the fields:
- `final WalletService _walletService;`
- `final SubscriptionService _subscriptionService;`
- `final ShopService _shopService;`
- `final ContributionService _contributionService;`

And the corresponding constructor parameters. Also remove the `SharedPreferences` import and `_lastSyncKey` constant if only used by sync.

Remove the corresponding import lines:
```dart
import 'wallet_service.dart';
import 'subscription_service.dart';
import 'shop_service.dart';
import 'contribution_service.dart';
```

- [ ] **Step 11.8: Remove calls to syncFromTajiri()**

Search for all call sites of `syncFromTajiri()` across the codebase and remove them. Likely locations:
- Budget home screen `initState()` or `_loadData()`
- Any periodic sync timer

Replace with calls to the new IncomeService/ExpenditureService query methods for loading data.

---

## Task 12: Final Verification

- [ ] **Step 12.1: Run flutter analyze on all modified files**

```bash
flutter analyze lib/services/wallet_service.dart \
  lib/services/shop_service.dart \
  lib/services/subscription_service.dart \
  lib/services/contribution_service.dart \
  lib/tajirika/services/tajirika_service.dart \
  lib/services/ad_service.dart \
  lib/services/livestream_service.dart \
  lib/events/services/ticket_service.dart \
  lib/widgets/budget_context_banner.dart \
  lib/services/budget_service.dart \
  lib/services/tea_service.dart \
  lib/services/fcm_service.dart \
  lib/services/live_update_service.dart
```

Fix any lint errors or type mismatches.

- [ ] **Step 12.2: Verify all model field references**

For each service modification, verify that the model fields used actually exist:
- `WalletTransaction.id` — check `lib/models/wallet_models.dart`
- `Order.totalAmount`, `Order.sellerId`, `Order.product.title` — check `lib/models/shop_models.dart`
- `Subscription.price`, `Subscription.tierName`, `Subscription.creatorId` — check `lib/models/subscription_models.dart`
- `Donation.userId`, `Donation.id` — check `lib/models/contribution_models.dart`
- `Withdrawal.userId`, `Withdrawal.id` — check `lib/models/contribution_models.dart`
- `TicketPurchaseResult.totalAmount`, `TicketPurchaseResult.ticketId` — check `lib/events/services/ticket_service.dart` result models

Adjust field names to match actual models. If a field is missing, use an alternative (e.g., pass via parameter).

- [ ] **Step 12.3: Verify IncomeService and ExpenditureService exist**

Confirm Plan A created these files:
- `lib/services/income_service.dart` — with `static Future<void> recordIncome(...)` method
- `lib/services/expenditure_service.dart` — with `static Future<void> recordExpenditure(...)` and `static Future<SpendingPace> getSpendingPace(...)` methods

If not present, they must be created first (Plan A prerequisite).

- [ ] **Step 12.4: Verify FCM routes are registered in main.dart**

Check that `lib/main.dart` has routes for:
- `/budget`
- `/budget/envelope/:id`
- `/budget/report`
- `/budget/goals`
- `/budget/recurring`

- [ ] **Step 12.5: Smoke test — verify no import cycles**

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Fix any circular dependency issues. The dependency graph should be:
```
Services (wallet, shop, etc.) → IncomeService/ExpenditureService → API
Budget screens → IncomeService/ExpenditureService → API
TeaService → BudgetService → IncomeService/ExpenditureService
```

No service should import BudgetService directly — they only report to Income/ExpenditureService.

---

## Summary of Files Modified

| File | Change |
|---|---|
| `lib/services/wallet_service.dart` | Add income/expenditure reporting to deposit, withdraw, transfer, payRequest |
| `lib/services/shop_service.dart` | Add expenditure on createOrder/checkout, income on confirmReceived |
| `lib/services/subscription_service.dart` | Add expenditure on subscribe/sendTip |
| `lib/services/contribution_service.dart` | Add expenditure on donateToCampaign, income on requestWithdrawal |
| `lib/tajirika/services/tajirika_service.dart` | Add income on reportJobCompleted/requestPayout |
| `lib/services/ad_service.dart` | Add expenditure on depositAdBalance, income on reportAdMobRevenue |
| `lib/services/livestream_service.dart` | Add expenditure on sendGift (with giftValue param) |
| `lib/events/services/ticket_service.dart` | Add expenditure on purchaseTicket |
| `lib/widgets/budget_context_banner.dart` | **NEW** — Reusable budget envelope context widget |
| `lib/services/budget_service.dart` | Add getBudgetSummaryForAI(), remove old sync methods |
| `lib/services/tea_service.dart` | Attach budget context to Shangazi chat when user asks about money |
| `lib/services/fcm_service.dart` | Add budget notification channel, types, routing, navigation helpers |
| `lib/services/live_update_service.dart` | Add BudgetUpdateEvent, handle budget_updated/income_recorded/expenditure_recorded |
| Various payment screens | Wire BudgetContextBanner before confirm buttons |
