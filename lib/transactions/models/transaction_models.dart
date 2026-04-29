// lib/transactions/models/transaction_models.dart
//
// Models for central transaction ledger (GET /transactions) and composite fallbacks.

import '../../business/models/business_models.dart';

enum TransactionDataSource { api, composite }

/// Single recorded micro-transaction (from POST /transactions/record pipeline or composite).
class RecordedTransaction {
  final String? id;
  final String traceId;
  final String status; // pending | success | failed
  final String module;
  final String action;
  final String direction; // incoming | outgoing
  final double amount;
  final String currency;
  final String? referenceId;
  final int? businessId;
  final Map<String, dynamic> metadata;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final String? message;
  final TransactionDataSource source;

  RecordedTransaction({
    this.id,
    required this.traceId,
    required this.status,
    required this.module,
    required this.action,
    required this.direction,
    required this.amount,
    this.currency = 'TZS',
    this.referenceId,
    this.businessId,
    this.metadata = const {},
    this.startedAt,
    this.completedAt,
    this.failedAt,
    this.message,
    this.source = TransactionDataSource.api,
  });

  DateTime get sortTime =>
      completedAt ?? failedAt ?? startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  String get displayTitle {
    if (metadata['title'] is String && (metadata['title'] as String).trim().isNotEmpty) {
      return (metadata['title'] as String).trim();
    }
    if (module.isNotEmpty && action.isNotEmpty) {
      return '$module · $action';
    }
    return action.isNotEmpty ? action : module;
  }

  factory RecordedTransaction.fromJson(Map<String, dynamic> json) {
    final tid = json['trace_id']?.toString() ?? json['traceId']?.toString() ?? '';
    final rid = json['id']?.toString();
    return RecordedTransaction(
      id: rid,
      traceId: tid.isNotEmpty ? tid : (rid ?? 'txn'),
      status: json['status']?.toString() ?? 'success',
      module: json['module']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'outgoing',
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      referenceId: json['reference_id']?.toString(),
      businessId: _parseInt(json['business_id']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : (json['metadata'] is Map
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : {}),
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      failedAt: _parseDate(json['failed_at']),
      message: json['message']?.toString(),
      source: TransactionDataSource.api,
    );
  }

  factory RecordedTransaction.fromInvoice(Invoice inv, int businessId) {
    final id = inv.id?.toString();
    final invNum = inv.invoiceNumber;
    return RecordedTransaction(
      id: id,
      traceId: 'composite_inv_${id ?? invNum}',
      status: 'success',
      module: 'business',
      action: 'invoice',
      direction: 'incoming',
      amount: inv.totalAmount,
      referenceId: id,
      businessId: businessId,
      metadata: {
        'title': invNum.isEmpty ? 'Invoice' : 'Invoice #$invNum',
        'kind': 'composite_invoice',
      },
      startedAt: inv.createdAt,
      completedAt: inv.createdAt,
      source: TransactionDataSource.composite,
    );
  }

  factory RecordedTransaction.fromDebt(Debt d, int businessId) {
    final id = d.id?.toString();
    final name = (d.customerName ?? '').trim();
    final title = name.isEmpty ? 'Debt' : 'Debt · $name';
    final when = d.createdAt ?? d.dueDate;
    final amt = d.remainingAmount > 0 ? d.remainingAmount : d.amount;
    return RecordedTransaction(
      id: id,
      traceId: 'composite_debt_${id ?? title.hashCode}',
      status: 'success',
      module: 'business',
      action: 'debt',
      direction: 'incoming',
      amount: amt,
      referenceId: id,
      businessId: businessId,
      metadata: {
        'title': title,
        'kind': 'composite_debt',
        'debt_status': d.status.name,
      },
      startedAt: when,
      completedAt: when,
      source: TransactionDataSource.composite,
    );
  }

  factory RecordedTransaction.fromPurchaseOrder(PurchaseOrder po, int businessId) {
    final id = po.id?.toString();
    final title = po.poNumber.isEmpty ? 'Purchase order' : 'PO ${po.poNumber}';
    final when = po.createdAt ?? po.expectedDeliveryDate;
    return RecordedTransaction(
      id: id,
      traceId: 'composite_po_${id ?? title.hashCode}',
      status: 'success',
      module: 'business',
      action: 'purchase_order',
      direction: 'outgoing',
      amount: po.totalAmount,
      referenceId: id,
      businessId: businessId,
      metadata: {
        'title': title,
        'kind': 'composite_po',
        'po_status': po.status.name,
        if ((po.supplierName ?? '').trim().isNotEmpty) 'supplier': po.supplierName,
      },
      startedAt: when,
      completedAt: when,
      source: TransactionDataSource.composite,
    );
  }

  factory RecordedTransaction.fromExpense(Expense exp, int businessId) {
    final id = exp.id?.toString();
    final desc = (exp.description ?? '').trim();
    final title = desc.isEmpty ? 'Expense' : desc;
    final when = exp.date ?? exp.createdAt;
    return RecordedTransaction(
      id: id,
      traceId: 'composite_exp_${id ?? title.hashCode}',
      status: 'success',
      module: 'business',
      action: 'expense',
      direction: 'outgoing',
      amount: exp.amount,
      referenceId: id,
      businessId: businessId,
      metadata: {
        'title': title,
        'kind': 'composite_expense',
      },
      startedAt: when,
      completedAt: when,
      source: TransactionDataSource.composite,
    );
  }
}

class TransactionListMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  TransactionListMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class TransactionListResult {
  final bool success;
  final String? message;
  final List<RecordedTransaction> items;
  final TransactionListMeta? meta;
  final TransactionDataSource source;

  TransactionListResult({
    required this.success,
    this.message,
    this.items = const [],
    this.meta,
    this.source = TransactionDataSource.api,
  });
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
