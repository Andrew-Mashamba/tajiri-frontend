import 'dart:convert';

import '../business/models/business_models.dart';
import '../business/services/business_service.dart';
import '../models/tajiri_pay_qr_models.dart';
import '../services/local_storage_service.dart';

class TajiriPayQrService {
  static const String _tipsDomain = 'tz.go.bot.tips';
  static const String _defaultAcquirerId = '01001';

  static String _cacheKey(int userId) => 'tajiri_pay_tanqr_user_$userId';

  Future<List<TajiriPayQrCode>> getBusinessQrs({
    required String token,
    required int userId,
    required String walletCurrency,
    required String ownerDisplayName,
  }) async {
    final businessesResult = await BusinessService.getMyBusinesses(token, userId);
    final businesses = businessesResult.success ? businessesResult.data : <Business>[];

    final codes = <TajiriPayQrCode>[
      _buildShopQr(
        userId: userId,
        walletCurrency: walletCurrency,
        ownerDisplayName: ownerDisplayName,
      ),
      ...businesses.map(
        (business) => _buildBusinessQr(
          userId: userId,
          business: business,
          walletCurrency: walletCurrency,
        ),
      ),
    ];

    await _saveToCache(userId, codes);
    return codes;
  }

  Future<List<TajiriPayQrCode>> getQrCardsForBusinessModule({
    required String token,
    required int userId,
    required String walletCurrency,
    required String ownerDisplayName,
    String? ownerPhone,
    String? ownerAddress,
  }) async {
    final businessesResult = await BusinessService.getMyBusinesses(token, userId);
    final businesses = businessesResult.success ? businessesResult.data : <Business>[];

    final paymentCodes = <TajiriPayQrCode>[
      _buildShopQr(
        userId: userId,
        walletCurrency: walletCurrency,
        ownerDisplayName: ownerDisplayName,
      ),
      ...businesses.map(
        (business) => _buildBusinessQr(
          userId: userId,
          business: business,
          walletCurrency: walletCurrency,
        ),
      ),
    ];

    final infoCodes = <TajiriPayQrCode>[
      _buildUserContactQr(
        userId: userId,
        ownerDisplayName: ownerDisplayName,
        ownerPhone: ownerPhone,
      ),
      _buildShopInfoQr(
        userId: userId,
        ownerDisplayName: ownerDisplayName,
        ownerPhone: ownerPhone,
        ownerAddress: ownerAddress,
      ),
      ...businesses.map(
        (business) => _buildBusinessInfoQr(
          userId: userId,
          business: business,
        ),
      ),
    ];

    final codes = [...paymentCodes, ...infoCodes];
    await _saveToCache(userId, codes);
    return codes;
  }

  List<TajiriPayQrCode> getCachedBusinessQrs(int userId) {
    final storage = LocalStorageService.instanceSync;
    if (storage == null) return const [];
    final raw = storage.getString(_cacheKey(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => TajiriPayQrCode.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveToCache(int userId, List<TajiriPayQrCode> codes) async {
    final storage = await LocalStorageService.getInstance();
    final payload = jsonEncode(codes.map((code) => code.toJson()).toList());
    await storage.setString(_cacheKey(userId), payload);
  }

  TajiriPayQrCode _buildShopQr({
    required int userId,
    required String walletCurrency,
    required String ownerDisplayName,
  }) {
    final alias = _buildAliasMerchantId(
      prefix: 'S',
      userId: userId,
      numericRef: 0,
    );
    final merchantName = _sanitizeMerchantName('$ownerDisplayName Shop');
    return TajiriPayQrCode(
      id: 'shop_$userId',
      walletUserId: userId,
      businessId: null,
      sourceType: 'shop',
      displayName: 'My Shop',
      tanqrPayload: _buildTanQrPayload(
        merchantName: merchantName,
        aliasMerchantId: alias,
        walletCurrency: walletCurrency,
        billNumber: 'SHOP$userId',
        mcc: '5311',
      ),
      aliasMerchantId: alias,
      generatedAt: DateTime.now(),
    );
  }

  TajiriPayQrCode _buildBusinessQr({
    required int userId,
    required Business business,
    required String walletCurrency,
  }) {
    final businessId = business.id ?? 0;
    final alias = _buildAliasMerchantId(
      prefix: 'B',
      userId: userId,
      numericRef: businessId,
    );
    return TajiriPayQrCode(
      id: 'business_${business.id ?? alias}',
      walletUserId: userId,
      businessId: business.id,
      sourceType: 'business',
      displayName: business.name,
      tanqrPayload: _buildTanQrPayload(
        merchantName: _sanitizeMerchantName(business.name),
        aliasMerchantId: alias,
        walletCurrency: walletCurrency,
        billNumber: 'BIZ${business.id ?? userId}',
      ),
      aliasMerchantId: alias,
      generatedAt: DateTime.now(),
    );
  }

  TajiriPayQrCode _buildUserContactQr({
    required int userId,
    required String ownerDisplayName,
    String? ownerPhone,
  }) {
    final safeName = ownerDisplayName.trim().isEmpty ? 'TAJIRI USER' : ownerDisplayName.trim();
    final safePhone = ownerPhone?.trim() ?? '';
    final payload = [
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:$safeName',
      if (safePhone.isNotEmpty) 'TEL;TYPE=CELL:$safePhone',
      'NOTE:Shared via TAJIRI QR Card',
      'END:VCARD',
    ].join('\n');

    return TajiriPayQrCode(
      id: 'contact_$userId',
      walletUserId: userId,
      businessId: null,
      sourceType: 'user_contact',
      displayName: 'My Contact',
      tanqrPayload: payload,
      aliasMerchantId: 'CONTACT',
      generatedAt: DateTime.now(),
    );
  }

  TajiriPayQrCode _buildShopInfoQr({
    required int userId,
    required String ownerDisplayName,
    String? ownerPhone,
    String? ownerAddress,
  }) {
    final alias = _buildAliasMerchantId(
      prefix: 'S',
      userId: userId,
      numericRef: 0,
    );
    final lines = <String>[
      'TAJIRI BUSINESS PROFILE',
      'Business: ${ownerDisplayName.trim().isEmpty ? 'My Shop' : '${ownerDisplayName.trim()} Shop'}',
      'Type: Shop',
      'Merchant ID: $alias',
      if ((ownerPhone ?? '').trim().isNotEmpty) 'Phone: ${ownerPhone!.trim()}',
      if ((ownerAddress ?? '').trim().isNotEmpty) 'Address: ${ownerAddress!.trim()}',
      'Platform: TAJIRI',
    ];

    return TajiriPayQrCode(
      id: 'shop_info_$userId',
      walletUserId: userId,
      businessId: null,
      sourceType: 'shop_info',
      displayName: 'Shop Information',
      tanqrPayload: lines.join('\n'),
      aliasMerchantId: alias,
      generatedAt: DateTime.now(),
    );
  }

  TajiriPayQrCode _buildBusinessInfoQr({
    required int userId,
    required Business business,
  }) {
    final businessId = business.id ?? 0;
    final alias = _buildAliasMerchantId(
      prefix: 'B',
      userId: userId,
      numericRef: businessId,
    );
    final lines = <String>[
      'TAJIRI BUSINESS PROFILE',
      'Business: ${business.name.trim().isEmpty ? 'Business' : business.name.trim()}',
      'Type: Business',
      'Merchant ID: $alias',
      if ((business.phone ?? '').trim().isNotEmpty) 'Phone: ${business.phone!.trim()}',
      if ((business.email ?? '').trim().isNotEmpty) 'Email: ${business.email!.trim()}',
      if ((business.address ?? '').trim().isNotEmpty) 'Address: ${business.address!.trim()}',
      if ((business.sector ?? '').trim().isNotEmpty) 'Sector: ${business.sector!.trim()}',
      'Platform: TAJIRI',
    ];

    return TajiriPayQrCode(
      id: 'business_info_${business.id ?? alias}',
      walletUserId: userId,
      businessId: business.id,
      sourceType: 'business_info',
      displayName: '${business.name} Info',
      tanqrPayload: lines.join('\n'),
      aliasMerchantId: alias,
      generatedAt: DateTime.now(),
    );
  }

  String _buildAliasMerchantId({
    required String prefix,
    required int userId,
    required int numericRef,
  }) {
    final userPart = userId.toString().padLeft(5, '0');
    final refPart = numericRef.toString().padLeft(5, '0');
    return '$prefix$userPart$refPart';
  }

  String _buildTanQrPayload({
    required String merchantName,
    required String aliasMerchantId,
    required String walletCurrency,
    required String billNumber,
    String mcc = '0000',
  }) {
    final currencyCode = walletCurrency.toUpperCase() == 'TZS' ? '834' : '834';
    final merchantAccountInfo = _tlv('00', _tipsDomain) +
        _tlv('01', _defaultAcquirerId) +
        _tlv('02', aliasMerchantId);

    final additionalData =
        _tlv('01', billNumber) + _tlv('05', 'TAJIRI_PAY');

    final withoutCrc = _tlv('00', '01') +
        _tlv('01', '11') +
        _tlv('26', merchantAccountInfo) +
        _tlv('52', mcc) +
        _tlv('53', currencyCode) +
        _tlv('58', 'TZ') +
        _tlv('59', merchantName) +
        _tlv('60', 'DAR ES SALAAM') +
        _tlv('62', additionalData) +
        '6304';

    final crc = _crc16Ccitt(withoutCrc);
    return '$withoutCrc$crc';
  }

  String _sanitizeMerchantName(String name) {
    final trimmed = name.trim().isEmpty ? 'TAJIRI MERCHANT' : name.trim();
    if (trimmed.length <= 25) return trimmed;
    return trimmed.substring(0, 25);
  }

  String _tlv(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  String _crc16Ccitt(String input) {
    int crc = 0xFFFF;
    for (final codeUnit in input.codeUnits) {
      crc ^= (codeUnit << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
