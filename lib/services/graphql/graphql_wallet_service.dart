import '../../models/wallet_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL wallet — balance, movements, seller wallet (Phase 20/24).
class GraphqlWalletService {
  static const _walletFields = r'''
    balance
    pendingBalance
    availableBalance
    currency
    hasPin
  ''';

  static const _txFields = r'''
    id
    type
    amount
    balanceAfter
    description
    referenceType
    referenceId
    createdAt
  ''';

  static const _myWalletQuery = '''
    query MyWallet {
      myWallet {
        $_walletFields
      }
    }
  ''';

  static const _sellerWalletQuery = '''
    query ShopSellerWallet {
      shopSellerWallet {
        availableBalance
        adSpend
        refundExposure
        transactions {
          $_txFields
        }
      }
    }
  ''';

  static const _myWalletTransactionsQuery = '''
    query MyWalletTransactions(\$cursor: String) {
      myWalletTransactions(cursor: \$cursor) {
        items {
          $_txFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static final Map<String, String?> _txCursors = {};
  static final Map<String, String?> _paymentRequestCursors = {};

  static Future<WalletResult> getWallet(int userId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_myWalletQuery);
      final wallet = data['myWallet'] as Map<String, dynamic>? ?? {};
      return WalletResult(
        success: true,
        wallet: Wallet.fromJson(_walletToLegacy(wallet)),
      );
    } catch (e) {
      return WalletResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<({bool success, String? message})> setPin({
    required String pin,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetWalletPin(\$pin: String!) {
          setWalletPin(pin: \$pin) {
            success
            message
            hasPin
          }
        }
        ''',
        variables: {'pin': pin},
        auth: true,
      );
      final result = data['setWalletPin'] as Map<String, dynamic>? ?? {};
      return (
        success: result['success'] == true,
        message: result['message']?.toString(),
      );
    } catch (e) {
      return (success: false, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        WalletTransaction? transaction,
        String? message,
      })> deposit({
    required int userId,
    required double amount,
    required String provider,
    required String phoneNumber,
  }) async {
    try {
      final idempotencyKey =
          'wallet_deposit_${userId}_${DateTime.now().microsecondsSinceEpoch}';
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DepositWallet(\$input: DepositWalletInput!) {
          depositWallet(input: \$input) {
            id
            transactionId
            userId
            type
            amount
            fee
            balanceBefore
            balanceAfter
            status
            paymentMethod
            provider
            description
            createdAt
            completedAt
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'provider': provider,
            'phoneNumber': phoneNumber,
            'idempotencyKey': idempotencyKey,
          },
        },
        auth: true,
      );
      final movement = data['depositWallet'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        transaction: WalletTransaction.fromJson(_movementToLegacy(movement, userId)),
        message: null,
      );
    } catch (e) {
      return (success: false, transaction: null, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        WalletTransaction? transaction,
        String? message,
      })> withdraw({
    required int userId,
    required double amount,
    required String provider,
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final idempotencyKey =
          'wallet_withdraw_${userId}_${DateTime.now().microsecondsSinceEpoch}';
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation WithdrawWallet(\$input: WithdrawWalletInput!) {
          withdrawWallet(input: \$input) {
            id
            transactionId
            userId
            type
            amount
            fee
            balanceBefore
            balanceAfter
            status
            paymentMethod
            provider
            description
            createdAt
            completedAt
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'provider': provider,
            'phoneNumber': phoneNumber,
            'pin': pin,
            'idempotencyKey': idempotencyKey,
          },
        },
        auth: true,
      );
      final movement = data['withdrawWallet'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        transaction: WalletTransaction.fromJson(_movementToLegacy(movement, userId)),
        message: null,
      );
    } catch (e) {
      return (success: false, transaction: null, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        double fee,
        double total,
        String? message,
      })> calculateFee({
    required double amount,
    String type = 'withdrawal',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WalletFee(\$amount: Float!, \$feeType: String!) {
          walletFee(amount: \$amount, feeType: \$feeType) {
            fee
            total
          }
        }
        ''',
        variables: {'amount': amount, 'feeType': type},
      );
      final quote = data['walletFee'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        fee: (quote['fee'] as num?)?.toDouble() ?? 0,
        total: (quote['total'] as num?)?.toDouble() ?? amount,
        message: null,
      );
    } catch (e) {
      return (success: false, fee: 0, total: amount, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        WalletTransaction? transaction,
        String? message,
      })> transfer({
    required int userId,
    int? recipientId,
    String? recipientPhone,
    required double amount,
    required String pin,
    String? description,
  }) async {
    try {
      final idempotencyKey =
          'wallet_transfer_${userId}_${DateTime.now().microsecondsSinceEpoch}';
      final input = <String, dynamic>{
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (description != null && description.isNotEmpty) 'description': description,
      };
      if (recipientId != null) {
        input['recipientId'] = recipientId.toString();
      } else if (recipientPhone != null && recipientPhone.isNotEmpty) {
        input['recipientPhone'] = recipientPhone.trim();
      }
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TransferWallet(\$input: TransferWalletInput!) {
          transferWallet(input: \$input) {
            id
            transactionId
            userId
            type
            amount
            fee
            balanceBefore
            balanceAfter
            status
            paymentMethod
            provider
            description
            createdAt
            completedAt
          }
        }
        ''',
        variables: {'input': input},
        auth: true,
      );
      final movement = data['transferWallet'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        transaction: WalletTransaction.fromJson(_movementToLegacy(movement, userId)),
        message: null,
      );
    } catch (e) {
      return (success: false, transaction: null, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        List<WalletTransaction> transactions,
        int currentPage,
        int lastPage,
        int perPage,
        int total,
        String? message,
      })> getTransactions({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const key = 'wallet_tx';
      String? cursor;
      if (page > 1) {
        cursor = _txCursors[key];
        if (cursor == null) {
          return (
            success: true,
            transactions: <WalletTransaction>[],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0,
            message: null,
          );
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _myWalletTransactionsQuery,
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['myWalletTransactions'] as Map<String, dynamic>? ?? {};
      final transactions = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((tx) => WalletTransaction.fromJson(_ledgerToLegacy(tx, userId)))
          .toList();
      _txCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      final total = hasMore
          ? page * perPage + 1
          : (page - 1) * perPage + transactions.length;
      return (
        success: true,
        transactions: transactions,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        perPage: perPage,
        total: total,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        transactions: <WalletTransaction>[],
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        total: 0,
        message: 'Kosa: $e',
      );
    }
  }

  static Future<
      ({
        bool success,
        List<MobileMoneyAccount> accounts,
        String? message,
      })> getMobileAccounts(int userId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyWalletMobileAccounts {
          myWalletMobileAccounts {
            id
            userId
            provider
            phoneNumber
            accountName
            isVerified
            isPrimary
          }
        }
        ''',
        auth: true,
      );
      final accounts = (data['myWalletMobileAccounts'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => MobileMoneyAccount.fromJson(_accountToLegacy(a)))
          .toList();
      return (success: true, accounts: accounts, message: null);
    } catch (e) {
      return (success: false, accounts: <MobileMoneyAccount>[], message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        MobileMoneyAccount? account,
        String? message,
      })> addMobileAccount({
    required String provider,
    required String phoneNumber,
    required String accountName,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddWalletMobileAccount(\$input: AddWalletMobileAccountInput!) {
          addWalletMobileAccount(input: \$input) {
            id
            userId
            provider
            phoneNumber
            accountName
            isVerified
            isPrimary
          }
        }
        ''',
        variables: {
          'input': {
            'provider': provider,
            'phoneNumber': phoneNumber,
            'accountName': accountName,
          },
        },
        auth: true,
      );
      final account = data['addWalletMobileAccount'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        account: MobileMoneyAccount.fromJson(_accountToLegacy(account)),
        message: null,
      );
    } catch (e) {
      return (success: false, account: null, message: 'Kosa: $e');
    }
  }

  static Future<bool> deleteMobileAccount({required int accountId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteWalletMobileAccount(\$accountId: ID!) {
          deleteWalletMobileAccount(accountId: \$accountId)
        }
        ''',
        variables: {'accountId': accountId.toString()},
        auth: true,
      );
      return data['deleteWalletMobileAccount'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setPrimaryAccount({required int accountId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetPrimaryWalletMobileAccount(\$accountId: ID!) {
          setPrimaryWalletMobileAccount(accountId: \$accountId)
        }
        ''',
        variables: {'accountId': accountId.toString()},
        auth: true,
      );
      return data['setPrimaryWalletMobileAccount'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<
      ({
        bool success,
        PaymentRequest? request,
        String? message,
      })> createPaymentRequest({
    required int payerId,
    required double amount,
    String? description,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateWalletPaymentRequest(\$input: CreateWalletPaymentRequestInput!) {
          createWalletPaymentRequest(input: \$input) {
            id
            requestId
            requesterId
            payerId
            amount
            description
            status
            expiresAt
            paidAt
            createdAt
            requester { id firstName lastName profilePhotoUrl }
            payer { id firstName lastName profilePhotoUrl }
          }
        }
        ''',
        variables: {
          'input': {
            'payerId': payerId.toString(),
            'amount': amount,
            if (description != null) 'description': description,
          },
        },
        auth: true,
      );
      final request = data['createWalletPaymentRequest'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        request: PaymentRequest.fromJson(_paymentRequestToLegacy(request)),
        message: null,
      );
    } catch (e) {
      return (success: false, request: null, message: 'Kosa: $e');
    }
  }

  static Future<
      ({
        bool success,
        List<PaymentRequest> requests,
        int currentPage,
        int lastPage,
        int perPage,
        int total,
        String? message,
      })> getPaymentRequests({
    required int userId,
    String direction = 'received',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = 'payment_requests:$direction';
      String? cursor;
      if (page > 1) {
        cursor = _paymentRequestCursors[key];
        if (cursor == null) {
          return (
            success: true,
            requests: <PaymentRequest>[],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0,
            message: null,
          );
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WalletPaymentRequests(\$direction: String, \$cursor: String) {
          walletPaymentRequests(direction: \$direction, cursor: \$cursor) {
            items {
              id
              requestId
              requesterId
              payerId
              amount
              description
              status
              expiresAt
              paidAt
              createdAt
              requester { id firstName lastName profilePhotoUrl }
              payer { id firstName lastName profilePhotoUrl }
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'direction': direction,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['walletPaymentRequests'] as Map<String, dynamic>? ?? {};
      final requests = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((r) => PaymentRequest.fromJson(_paymentRequestToLegacy(r)))
          .toList();
      _paymentRequestCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      final total = hasMore
          ? page * perPage + 1
          : (page - 1) * perPage + requests.length;
      return (
        success: true,
        requests: requests,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        perPage: perPage,
        total: total,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        requests: <PaymentRequest>[],
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        total: 0,
        message: 'Kosa: $e',
      );
    }
  }

  static Future<
      ({
        bool success,
        WalletTransaction? transaction,
        String? message,
      })> payRequest({
    required int userId,
    required String requestId,
    required String pin,
  }) async {
    try {
      final idempotencyKey =
          'wallet_payreq_${userId}_${DateTime.now().microsecondsSinceEpoch}';
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PayWalletPaymentRequest(\$requestId: String!, \$pin: String!, \$idempotencyKey: String!) {
          payWalletPaymentRequest(requestId: \$requestId, pin: \$pin, idempotencyKey: \$idempotencyKey) {
            id
            transactionId
            userId
            type
            amount
            fee
            balanceBefore
            balanceAfter
            status
            paymentMethod
            provider
            description
            createdAt
            completedAt
          }
        }
        ''',
        variables: {
          'requestId': requestId,
          'pin': pin,
          'idempotencyKey': idempotencyKey,
        },
        auth: true,
      );
      final movement = data['payWalletPaymentRequest'] as Map<String, dynamic>? ?? {};
      return (
        success: true,
        transaction: WalletTransaction.fromJson(_movementToLegacy(movement, userId)),
        message: null,
      );
    } catch (e) {
      return (success: false, transaction: null, message: 'Kosa: $e');
    }
  }

  static Future<bool> declineRequest({required String requestId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeclineWalletPaymentRequest(\$requestId: String!) {
          declineWalletPaymentRequest(requestId: \$requestId)
        }
        ''',
        variables: {'requestId': requestId},
        auth: true,
      );
      return data['declineWalletPaymentRequest'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getSellerWallet() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_sellerWalletQuery);
      final wallet = data['shopSellerWallet'] as Map<String, dynamic>?;
      if (wallet == null) return null;
      return _sellerWalletToLegacy(wallet);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _paymentRequestToLegacy(Map<String, dynamic> gql) {
    Map<String, dynamic>? userToLegacy(Map<String, dynamic>? user) {
      if (user == null) return null;
      return {
        'id': int.tryParse(user['id']?.toString() ?? '') ?? 0,
        'first_name': user['firstName']?.toString() ?? '',
        'last_name': user['lastName']?.toString() ?? '',
        'profile_photo_path': user['profilePhotoUrl']?.toString(),
      };
    }

    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'request_id': gql['requestId']?.toString() ?? '',
      'requester_id': int.tryParse(gql['requesterId']?.toString() ?? '') ?? 0,
      'payer_id': int.tryParse(gql['payerId']?.toString() ?? '') ?? 0,
      'amount': gql['amount'] ?? 0,
      'description': gql['description']?.toString(),
      'status': gql['status']?.toString() ?? 'pending',
      'expires_at': gql['expiresAt']?.toString(),
      'paid_at': gql['paidAt']?.toString(),
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'requester': userToLegacy(gql['requester'] as Map<String, dynamic>?),
      'payer': userToLegacy(gql['payer'] as Map<String, dynamic>?),
    };
  }

  static Map<String, dynamic> _accountToLegacy(Map<String, dynamic> gql) {
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(gql['userId']?.toString() ?? '') ?? 0,
      'provider': gql['provider']?.toString() ?? '',
      'phone_number': gql['phoneNumber']?.toString() ?? '',
      'account_name': gql['accountName']?.toString() ?? '',
      'is_verified': gql['isVerified'] == true,
      'is_primary': gql['isPrimary'] == true,
    };
  }

  static Map<String, dynamic> _walletToLegacy(Map<String, dynamic> gql) {
    return {
      'balance': gql['balance'] ?? 0,
      'pending_balance': gql['pendingBalance'] ?? 0,
      'currency': gql['currency'] ?? 'TZS',
      'is_active': true,
      'has_pin': gql['hasPin'] ?? false,
      'ad_balance': 0,
    };
  }

  static Map<String, dynamic> _movementToLegacy(
    Map<String, dynamic> gql,
    int userId,
  ) {
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'transaction_id': gql['transactionId']?.toString() ?? '',
      'user_id': int.tryParse(gql['userId']?.toString() ?? '') ?? userId,
      'type': gql['type']?.toString() ?? 'deposit',
      'amount': gql['amount'] ?? 0,
      'fee': gql['fee'] ?? 0,
      'balance_before': gql['balanceBefore'] ?? 0,
      'balance_after': gql['balanceAfter'] ?? 0,
      'status': gql['status']?.toString() ?? 'completed',
      'payment_method': gql['paymentMethod']?.toString(),
      'provider': gql['provider']?.toString(),
      'description': gql['description']?.toString(),
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'completed_at': gql['completedAt']?.toString(),
    };
  }

  static Map<String, dynamic> _ledgerToLegacy(
    Map<String, dynamic> gql,
    int userId,
  ) {
    final signedAmount = (gql['amount'] as num?)?.toDouble() ?? 0;
    final amount = signedAmount.abs();
    final balanceAfter = (gql['balanceAfter'] as num?)?.toDouble() ?? 0;
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'transaction_id': 'TXN${gql['id']}',
      'user_id': userId,
      'type': gql['type']?.toString() ?? 'deposit',
      'amount': amount,
      'fee': 0,
      'balance_before': balanceAfter + (signedAmount < 0 ? amount : -amount),
      'balance_after': balanceAfter,
      'status': 'completed',
      'description': gql['description']?.toString(),
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _sellerWalletToLegacy(Map<String, dynamic> gql) {
    final txs = (gql['transactions'] as List? ?? []).map((t) {
      final tx = t as Map<String, dynamic>;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      return {
        'description': tx['description'] ?? tx['type'] ?? 'Transaction',
        'date': tx['createdAt']?.toString() ?? '',
        'amount': amount.abs(),
        'type': amount >= 0 ? 'credit' : 'debit',
        'credit': amount >= 0,
      };
    }).toList();
    return {
      'available_balance': gql['availableBalance'] ?? 0,
      'ad_spend': gql['adSpend'] ?? 0,
      'refund_exposure': gql['refundExposure'] ?? 0,
      'transactions': txs,
    };
  }
}
