// lib/suppliers/pages/purchase_orders_page.dart
// Purchase Orders (Maagizo ya Manunuzi / Purchase Orders).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';
import '../services/supplier_reminders.dart';
import 'supplier_payables_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PurchaseOrdersPage extends StatefulWidget {
  final int businessId;
  const PurchaseOrdersPage({super.key, required this.businessId});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _token;
  bool _loading = true;
  String? _error;
  List<PurchaseOrder> _orders = [];
  List<Supplier> _suppliers = [];
  List<PurchaseOrder> _allOrdersForSummary = [];
  int _userId = 0;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _isSwahili
      ? const ['Zote', 'Rasimu', 'Zimetumwa', 'Zimepokelewa']
      : const ['All', 'Draft', 'Sent', 'Received'];
  // partially_received treated as Received (goods arrived but incomplete)
  final _statusFilters = const [null, 'draft', 'sent', 'received,partially_received'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _loadOrders();
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    if (_token != null) {
      await Future.wait([_loadOrders(), _loadSuppliers(), _loadSummaryOrders()]);
    }
  }

  Future<void> _loadSummaryOrders() async {
    if (_token == null) return;
    final res = await BusinessService.getPurchaseOrders(
        _token!, widget.businessId,
        status: null);
    if (mounted && res.success) {
      setState(() => _allOrdersForSummary = res.data);
    }
  }

  Widget _buildSummaryChips() {
    final now = DateTime.now();
    final monthly = _allOrdersForSummary.where((o) =>
        o.createdAt != null &&
        o.createdAt!.year == now.year &&
        o.createdAt!.month == now.month).toList();
    if (monthly.isEmpty) return const SizedBox.shrink();

    int draft = 0, sent = 0, received = 0, cancelled = 0;
    for (final o in monthly) {
      switch (o.status) {
        case PurchaseOrderStatus.draft:
          draft++;
        case PurchaseOrderStatus.sent:
          sent++;
        case PurchaseOrderStatus.received:
        case PurchaseOrderStatus.partiallyReceived:
          received++;
        case PurchaseOrderStatus.cancelled:
          cancelled++;
      }
    }

    final sw = _isSwahili;
    Widget chip(String label, int count, Color color) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$label $count',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        );

    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(sw ? 'Mwezi huu:' : 'This month:',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(width: 8),
            if (draft > 0) chip(sw ? 'Rasimu' : 'Draft', draft, Colors.grey.shade600),
            if (sent > 0) chip(sw ? 'Imetumwa' : 'Sent', sent, Colors.blue.shade600),
            if (received > 0) chip(sw ? 'Imepokelewa' : 'Received', received, Colors.green.shade600),
            if (cancelled > 0) chip(sw ? 'Imefutwa' : 'Cancelled', cancelled, Colors.red.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _loadOrders() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _statusFilters[_tabCtrl.index];
      final res = await BusinessService.getPurchaseOrders(
          _token!, widget.businessId,
          status: status);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _orders = res.data;
          } else {
            _error = res.message ??
                (_isSwahili ? 'Imeshindikana kupata maagizo' : 'Failed to load orders');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _isSwahili ? 'Tatizo la mtandao' : 'Network error';
        });
      }
    }
  }

  Future<void> _loadSuppliers() async {
    if (_token == null) return;
    final res =
        await BusinessService.getSuppliers(_token!, widget.businessId);
    if (mounted && res.success) {
      setState(() => _suppliers = res.data);
    }
  }

  Future<void> _saveEventToCalendar({
    required String title,
    required DateTime date,
    String? notes,
  }) async {
    try {
      await CalendarService().createEvent(CalendarEvent(
        id: 0,
        userId: _userId,
        title: title,
        date: date,
        isAllDay: true,
        source: EventSource.business,
        notes: notes,
      ));
    } catch (_) {}
  }

  Future<void> _offerCalendarSave({
    required String title,
    required DateTime date,
    required String dialogTitle,
    required String dialogBody,
    String? notes,
  }) async {
    if (!mounted) return;
    final sw = _isSwahili;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(sw ? 'Sio Sasa' : 'Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveEventToCalendar(title: title, date: date, notes: notes);
  }


  void _markReceived(PurchaseOrder po) {
    if (_token == null || po.id == null) return;
    _showReceiptConfirmSheet(po);
  }

  void _showReceiptConfirmSheet(PurchaseOrder po) {
    final isSwahili = _isSwahili;
    final nf = NumberFormat('#,###', 'en');
    // Controllers for received qty per item (0-based index)
    final ctrlList = po.items
        .map((item) =>
            TextEditingController(text: item.quantity.toStringAsFixed(0)))
        .toList();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          Future<void> confirm() async {
            if (submitting) return;
            setSt(() => submitting = true);

            final itemsPayload = List.generate(po.items.length, (i) {
              final qty = int.tryParse(ctrlList[i].text.trim()) ?? 0;
              return {'id': i, 'received_qty': qty};
            });

            final messenger = ScaffoldMessenger.of(context);
            final res = await BusinessService.markPOReceived(
                _token!, po.id!,
                items: itemsPayload);

            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();

            if (mounted) {
              final isPartial = res.data?.status ==
                  PurchaseOrderStatus.partiallyReceived;
              messenger.showSnackBar(SnackBar(
                  content: Text(res.success
                      ? (isPartial
                          ? (isSwahili
                              ? 'Imepokewa sehemu — baadhi ya bidhaa bado hazijafika'
                              : 'Partial receipt recorded — some items still pending')
                          : (isSwahili
                              ? 'Agizo limepokelewa kikamilifu'
                              : 'Order fully received'))
                      : (res.message ??
                          (isSwahili ? 'Imeshindikana' : 'Failed'))),
                  backgroundColor: res.success
                      ? (isPartial ? Colors.orange : null)
                      : Colors.red));
              if (res.success) {
                _loadOrders();
                if (isPartial && _token != null) {
                  SupplierReminders.schedulePartialFollowup(
                    supplierLabel: po.supplierName ?? '',
                    token: _token!,
                    userId: _userId,
                    isSwahili: isSwahili,
                  );
                }
                if (po.id != null) {
                  _showPayLaterSheet(po);
                }
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    isSwahili
                        ? 'Thibitisha Kupokea'
                        : 'Confirm Receipt',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    isSwahili
                        ? 'Ingiza kiasi kilichopokelewa kwa kila bidhaa.'
                        : 'Enter the quantity received for each item.',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: po.items.length,
                    itemBuilder: (_, i) {
                      final item = po.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${isSwahili ? "Imeagizwa" : "Ordered"}: ${item.quantity.toStringAsFixed(0)}  •  TZS ${nf.format(item.unitPrice)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: ctrlList[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  labelText: isSwahili ? 'Pokelewa' : 'Rcvd',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : confirm,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text(isSwahili ? 'Thibitisha' : 'Confirm',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      for (final c in ctrlList) {
        c.dispose();
      }
    });
  }

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
      if (res.success) {
        _loadOrders();
        _showSendShareSheet(po);
      }
    }
  }

  Future<void> _generateAndSharePDF(PurchaseOrder po) async {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final poRef = po.poNumber.isNotEmpty ? po.poNumber : 'PO-${po.id ?? ""}';
    final supplier = po.supplierId != null
        ? _suppliers.where((s) => s.id == po.supplierId).firstOrNull
        : null;
    final supplierName = supplier?.name ?? po.supplierName ?? '';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('AGIZO LA MANUNUZI',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('PURCHASE ORDER',
                          style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(poRef,
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(df.format(po.createdAt ?? DateTime.now()),
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              // Supplier info
              if (supplierName.isNotEmpty) ...[
                pw.Text('Msambazaji / Supplier',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.Text(supplierName,
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                if (supplier?.phone != null && supplier!.phone!.isNotEmpty)
                  pw.Text(supplier.phone!,
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
              ],
              // Items table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _pdfCell('Maelezo / Description', bold: true),
                      _pdfCell('Idadi\nQty', bold: true, center: true),
                      _pdfCell('Bei\nUnit Price', bold: true, center: true),
                      _pdfCell('Jumla\nTotal', bold: true, center: true),
                    ],
                  ),
                  // Item rows
                  ...po.items.map((item) => pw.TableRow(
                        children: [
                          _pdfCell(item.description),
                          _pdfCell(item.quantity.toStringAsFixed(0),
                              center: true),
                          _pdfCell(
                              'TZS ${nf.format(item.unitPrice)}',
                              center: true),
                          _pdfCell(
                              'TZS ${nf.format(item.totalPrice)}',
                              center: true),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 8),
              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (po.vatAmount > 0)
                      pw.Text(
                          'VAT: TZS ${nf.format(po.vatAmount)}',
                          style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('JUMLA / TOTAL: TZS ${nf.format(po.totalAmount)}',
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              // Delivery date
              if (po.expectedDeliveryDate != null) ...[
                pw.Text(
                    'Tarehe ya kupokea / Expected delivery: ${df.format(po.expectedDeliveryDate!)}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 6),
              ],
              // Notes
              if (po.notes != null && po.notes!.isNotEmpty) ...[
                pw.Text('Maelezo / Notes: ${po.notes}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 6),
              ],
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Text('Imetolewa na TAJIRI  •  Issued via TAJIRI',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey500)),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
        bytes: bytes,
        filename: '$poRef.pdf');
  }

  pw.Widget _pdfCell(String text,
      {bool bold = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  void _showSendShareSheet(PurchaseOrder po) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final poRef = po.poNumber.isNotEmpty ? po.poNumber : 'PO-${po.id ?? ""}';

    // Resolve supplier name and phone from linked supplier record
    final supplier = po.supplierId != null
        ? _suppliers.where((s) => s.id == po.supplierId).firstOrNull
        : null;
    final supplierName =
        supplier?.name ?? po.supplierName ?? '';
    final supplierPhone = supplier?.phone?.replaceAll(RegExp(r'[^0-9+]'), '');

    // Build WhatsApp message
    final buffer = StringBuffer();
    buffer.writeln(supplierName.isNotEmpty
        ? (_isSwahili ? 'Habari $supplierName,' : 'Hello $supplierName,')
        : (_isSwahili ? 'Habari,' : 'Hello,'));
    buffer.writeln();
    buffer.writeln(_isSwahili
        ? 'Naomba kuagiza bidhaa zifuatazo:'
        : 'We would like to place the following order:');
    buffer.writeln();
    for (final item in po.items) {
      buffer.writeln(
          '• ${item.description} × ${item.quantity.toStringAsFixed(0)} — TZS ${nf.format(item.totalPrice)}');
    }
    buffer.writeln();
    buffer.writeln('${_isSwahili ? "Jumla" : "Total"}: TZS ${nf.format(po.totalAmount)}');
    if (po.expectedDeliveryDate != null) {
      buffer.writeln(
          '${_isSwahili ? "Tarehe ya Kupokea" : "Expected Delivery"}: ${df.format(po.expectedDeliveryDate!)}');
    }
    buffer.writeln('${_isSwahili ? "Nambari ya Agizo" : "Order Ref"}: $poRef');
    if (po.notes != null && po.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${_isSwahili ? "Maelezo" : "Notes"}: ${po.notes}');
    }
    buffer.writeln();
    buffer.writeln(_isSwahili
        ? 'Asante. (Imetumwa kupitia TAJIRI)'
        : 'Thank you. (Sent via TAJIRI)');

    final message = buffer.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSwahili
                  ? 'Tuma Agizo kwa Msambazaji'
                  : 'Share Order with Supplier',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              poRef,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 20),
            // WhatsApp
            _shareOption(
              ctx,
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              subtitle: _isSwahili
                  ? 'Tuma ujumbe wa agizo kwa msambazaji'
                  : 'Send order message to supplier',
              onTap: () async {
                Navigator.pop(ctx);
                final encoded = Uri.encodeComponent(message);
                final phone = supplierPhone != null && supplierPhone.isNotEmpty
                    ? supplierPhone
                    : '';
                final url = Uri.parse(
                    'https://wa.me/$phone?text=$encoded');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),
            // Copy reference
            _shareOption(
              ctx,
              icon: Icons.copy_rounded,
              iconColor: _kPrimary,
              label: _isSwahili ? 'Nakili Nambari ya Agizo' : 'Copy Order Reference',
              subtitle: poRef,
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: poRef));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        _isSwahili ? 'Imenakiliwa' : 'Copied to clipboard')));
              },
            ),
            const SizedBox(height: 12),
            // PDF download
            _shareOption(
              ctx,
              icon: Icons.picture_as_pdf_rounded,
              iconColor: Colors.red,
              label: _isSwahili ? 'Pakua PDF' : 'Download PDF',
              subtitle: _isSwahili
                  ? 'Pakua agizo kama faili la PDF'
                  : 'Download order as PDF file',
              onTap: () async {
                Navigator.pop(ctx);
                await _generateAndSharePDF(po);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  _isSwahili ? 'Sio Sasa' : 'Not Now',
                  style: const TextStyle(color: _kSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(
    BuildContext ctx, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(PurchaseOrder po) async {
    if (_token == null || po.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa Agizo?' : 'Cancel Order?'),
        content: Text(_isSwahili
            ? 'Agizo hili litafutwa.'
            : 'This order will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Ndio, Futa' : 'Yes, Cancel',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await BusinessService.cancelPO(_token!, po.id!);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (_isSwahili ? 'Agizo limefutwa' : 'Order cancelled')
              : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _loadOrders();
    }
  }

  Color _statusColor(PurchaseOrderStatus s) {
    switch (s) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.sent:
        return Colors.blue;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.orange;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(PurchaseOrderStatus s) {
    if (_isSwahili) return poStatusLabel(s);
    switch (s) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.sent:
        return 'Sent';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Partial';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showPayLaterSheet(PurchaseOrder po) {
    final isSwahili = _isSwahili;
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final poRef = po.poNumber.isNotEmpty ? po.poNumber : 'PO-${po.id ?? ""}';
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    bool saving = false;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        Future<void> recordCredit() async {
          if (_token == null || po.id == null) return;
          setSt(() => saving = true);
          final messenger = ScaffoldMessenger.of(context);
          final body = <String, dynamic>{
            'due_date': dueDate.toIso8601String().substring(0, 10),
          };
          final notes = notesCtrl.text.trim();
          if (notes.isNotEmpty) body['notes'] = notes;
          final capturedDue = dueDate;
          final res = await BusinessService.createPayable(_token!, po.id!, body);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (mounted) {
            messenger.showSnackBar(SnackBar(
                content: Text(res.success
                    ? (isSwahili
                        ? 'Deni limeandikwa — TZS ${nf.format(po.totalAmount)} inalipwa ${df.format(capturedDue)}'
                        : 'Credit recorded — TZS ${nf.format(po.totalAmount)} due ${df.format(capturedDue)}')
                    : (res.message ??
                        (isSwahili ? 'Imeshindikana' : 'Failed'))),
                backgroundColor: res.success ? null : Colors.red));
            if (res.success) {
              final supplierLabel = po.supplierName?.isNotEmpty == true
                  ? po.supplierName!
                  : (isSwahili ? 'Msambazaji' : 'Supplier');
              _saveEventToCalendar(
                title: isSwahili
                    ? '💳 Lipa $supplierLabel: TZS ${nf.format(po.totalAmount)}'
                    : '💳 Pay $supplierLabel: TZS ${nf.format(po.totalAmount)}',
                date: capturedDue,
                notes: isSwahili ? 'Deni la $poRef' : 'Payable for $poRef',
              );
              if (_token != null) {
                SupplierReminders.schedulePayableReminders(
                  dueDate: capturedDue,
                  supplierLabel: supplierLabel,
                  amount: po.totalAmount,
                  token: _token!,
                  userId: _userId,
                  isSwahili: isSwahili,
                );
              }
            }
          }
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili
                      ? 'Je, umelipa agizo hili?'
                      : 'Have you paid for this order?',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  '$poRef  •  TZS ${nf.format(po.totalAmount)}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 20),
                // Pay now button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // Record as expense (fire-and-forget) so the payment
                      // is tracked in the business ledger.
                      if (_token != null) {
                        final supplierLabel = po.supplierName?.isNotEmpty == true
                            ? po.supplierName!
                            : (isSwahili ? 'Msambazaji' : 'Supplier');
                        BusinessService.addExpense(_token!, widget.businessId, {
                          'category': 'supplies',
                          'description': isSwahili
                              ? 'Malipo ya msambazaji: $supplierLabel'
                              : 'Supplier payment: $supplierLabel',
                          'amount': po.totalAmount,
                          'date': DateTime.now()
                              .toIso8601String()
                              .substring(0, 10),
                          if (po.supplierName?.isNotEmpty == true)
                            'vendor_name': po.supplierName,
                          if (po.poNumber.isNotEmpty)
                            'notes': isSwahili
                                ? 'PO: ${po.poNumber}'
                                : 'PO: ${po.poNumber}',
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isSwahili ? 'Ndiyo, nimelipa' : 'Yes, already paid',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Pay later
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Lipa baadaye (deni)' : 'Pay later (credit)',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) setSt(() => dueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: _kSecondary),
                              const SizedBox(width: 8),
                              Text(
                                '${isSwahili ? "Tarehe ya kulipa" : "Due date"}: ${df.format(dueDate)}',
                                style: const TextStyle(
                                    fontSize: 14, color: _kPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isSwahili
                              ? 'Makubaliano (si lazima)'
                              : 'Agreement notes (optional)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : recordCredit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isSwahili
                                      ? 'Andika kama deni'
                                      : 'Record as credit',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() => notesCtrl.dispose());
  }

  // existing: non-null when editing a draft; isReorder: true when reordering from a completed PO
  void _showCreateSheet({PurchaseOrder? existing, bool isReorder = false}) {
    final nf = NumberFormat('#,###', 'en');
    final isEdit = existing != null && !isReorder;

    // Pre-fill supplier
    Supplier? selectedSupplier = existing != null && existing.supplierId != null
        ? _suppliers.where((s) => s.id == existing.supplierId).firstOrNull
        : null;
    bool catalogLoading = false;

    // Pre-fill delivery date
    final deliveryDate = ValueNotifier<DateTime>(
        isReorder
            ? DateTime.now().add(const Duration(days: 7))
            : (existing?.expectedDeliveryDate ??
                DateTime.now().add(const Duration(days: 7))));

    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    // Pre-fill items from existing PO
    final items = <_QuickItem>[
      if (existing != null)
        ...existing.items.map((i) => _QuickItem(
              description: i.description,
              unitPrice: i.unitPrice,
              quantity: i.quantity,
            )),
    ];

    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double total =
              items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      isEdit
                          ? (_isSwahili ? 'Hariri Agizo' : 'Edit Order')
                          : isReorder
                              ? (_isSwahili ? 'Agiza Tena' : 'Reorder')
                              : (_isSwahili
                                  ? 'Agizo Jipya la Manunuzi'
                                  : 'New Purchase Order'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  if (isReorder && existing != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_isSwahili ? "Kulingana na" : "Based on"} ${existing.poNumber.isNotEmpty ? existing.poNumber : "PO-${existing.id ?? ""}"}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Supplier selector
                  if (_suppliers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isSwahili
                                  ? 'Ongeza msambazaji kwanza kwenye ukurasa wa Wasambazaji'
                                  : 'Add a supplier first on the Suppliers page',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedSupplier?.id,
                          hint: Text(_isSwahili
                              ? 'Chagua Msambazaji'
                              : 'Select Supplier'),
                          isExpanded: true,
                          items: _suppliers
                              .map((s) => DropdownMenuItem(
                                  value: s.id, child: Text(s.name)))
                              .toList(),
                          onChanged: (v) {
                            setSheetState(() {
                              selectedSupplier = v != null
                                  ? _suppliers.firstWhere((s) => s.id == v)
                                  : null;
                            });
                          },
                        ),
                      ),
                    ),
                  // Load from catalog button
                  if (selectedSupplier?.id != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: catalogLoading
                          ? null
                          : () async {
                              final sid = selectedSupplier?.id;
                              if (sid == null) return;
                              setSheetState(() => catalogLoading = true);
                              final res = await BusinessService.getSupplierCatalog(
                                  _token!, sid);
                              setSheetState(() {
                                catalogLoading = false;
                                if (res.success && res.data.isNotEmpty) {
                                  items.clear();
                                  items.addAll(res.data.map((c) => _QuickItem(
                                        description: c.name,
                                        unitPrice: c.unitPrice,
                                        quantity: c.defaultQuantity.toDouble(),
                                      )));
                                }
                              });
                            },
                      icon: catalogLoading
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.playlist_add_rounded, size: 16),
                      label: Text(
                          _isSwahili
                              ? 'Pakia bidhaa za kawaida'
                              : 'Load usual items',
                          style: const TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Items list
                  if (items.isNotEmpty)
                    ...items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final i = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${i.description} x${i.quantity.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 13, color: _kPrimary))),
                            Text(
                                'TZS ${nf.format(i.unitPrice * i.quantity)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded,
                                  size: 18, color: Colors.red),
                              onPressed: () =>
                                  setSheetState(() => items.removeAt(idx)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                  // Item input row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            hintText: _isSwahili ? 'Bidhaa' : 'Item',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: _isSwahili ? 'Bei' : 'Price',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _kPrimary),
                        onPressed: () {
                          final d = descCtrl.text.trim();
                          final qty =
                              double.tryParse(qtyCtrl.text) ?? 1;
                          final p = double.tryParse(
                                  priceCtrl.text.replaceAll(',', '')) ??
                              0;
                          if (d.isNotEmpty && p > 0) {
                            setSheetState(() {
                              items.add(_QuickItem(
                                  description: d,
                                  unitPrice: p,
                                  quantity: qty));
                              descCtrl.clear();
                              priceCtrl.clear();
                              qtyCtrl.text = '1';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isSwahili ? 'JUMLA' : 'TOTAL',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: _kPrimary)),
                        Text('TZS ${nf.format(total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: _kPrimary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Delivery date
                  ValueListenableBuilder<DateTime>(
                    valueListenable: deliveryDate,
                    builder: (_, date, child) => GestureDetector(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (dt != null) deliveryDate.value = dt;
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _isSwahili
                              ? 'Tarehe ya Kupokea'
                              : 'Expected Delivery Date',
                          filled: true,
                          fillColor: _kBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _kSecondary),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(date)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _isSwahili ? 'Maelezo' : 'Notes',
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (selectedSupplier == null || items.isEmpty) return;
                              final supplierName = selectedSupplier!.name;
                              setSheetState(() => submitting = true);
                              try {
                                final body = {
                                  'business_id': widget.businessId,
                                  'supplier_id': selectedSupplier?.id,
                                  'supplier_name': supplierName,
                                  'items': items
                                      .map((i) => {
                                            'description': i.description,
                                            'quantity': i.quantity,
                                            'unit_price': i.unitPrice,
                                            'total_price':
                                                i.unitPrice * i.quantity,
                                          })
                                      .toList(),
                                  'subtotal': total,
                                  'vat_amount': 0,
                                  'total_amount': total,
                                  'status': 'draft',
                                  'expected_delivery_date':
                                      deliveryDate.value.toIso8601String(),
                                  'notes': notesCtrl.text.trim(),
                                };

                                final poRes = isEdit && existing.id != null
                                    ? await BusinessService.updatePurchaseOrder(
                                        _token!, existing.id!, body)
                                    : await BusinessService.createPurchaseOrder(
                                        _token!, widget.businessId, body);

                                if (!poRes.success) {
                                  setSheetState(() => submitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(poRes.message ??
                                            (_isSwahili
                                                ? 'Imeshindikana. Jaribu tena.'
                                                : 'Failed. Please try again.')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final capturedDelivery = deliveryDate.value;
                                final capturedSupplierName = supplierName;
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  final sw = _isSwahili;
                                  final msg = isEdit
                                      ? (sw ? 'Agizo limesasishwa' : 'Order updated')
                                      : isReorder
                                          ? (sw ? 'Agizo jipya limeundwa' : 'New order created')
                                          : (sw ? 'Agizo limeundwa' : 'Order created');
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(msg)));
                                  _loadOrders();
                                  _loadSummaryOrders();
                                  if (!isEdit) {
                                    await _offerCalendarSave(
                                      title: sw
                                          ? 'Kupokea: $capturedSupplierName'
                                          : 'Receive: $capturedSupplierName',
                                      date: capturedDelivery,
                                      dialogTitle: sw
                                          ? 'Hifadhi kwenye Kalenda?'
                                          : 'Save to Calendar?',
                                      dialogBody: sw
                                          ? 'Hifadhi tarehe ya kupokea kwenye kalenda yako?'
                                          : 'Save the delivery date to your calendar?',
                                    );
                                    if (_token != null) {
                                      SupplierReminders.scheduleDeliveryReminder(
                                        deliveryDate: capturedDelivery,
                                        supplierLabel: capturedSupplierName,
                                        token: _token!,
                                        userId: _userId,
                                        isSwahili: sw,
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(_isSwahili
                                          ? 'Imeshindikana. Jaribu tena.'
                                          : 'Failed. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              isEdit
                                  ? (_isSwahili ? 'Sasisha Agizo' : 'Update Order')
                                  : (_isSwahili ? 'Unda Agizo' : 'Create Order'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      descCtrl.dispose();
      priceCtrl.dispose();
      qtyCtrl.dispose();
      notesCtrl.dispose();
      deliveryDate.dispose();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          _buildSummaryChips(),
          Expanded(
            child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadOrders,
                        style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary),
                        child:
                            Text(_isSwahili ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                              _isSwahili
                                  ? 'Hakuna maagizo bado'
                                  : 'No orders yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                              _isSwahili
                                  ? 'Bonyeza + kuunda agizo jipya'
                                  : 'Tap + to create a new order',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final po = _orders[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _PurchaseOrderDetailPage(
                                  po: po,
                                  isSwahili: _isSwahili,
                                  onMarkSent: () => _markSent(po),
                                  onMarkReceived: () => _markReceived(po),
                                  onCancel: () => _cancelOrder(po),
                                  onEdit: po.status == PurchaseOrderStatus.draft
                                      ? () => _showCreateSheet(existing: po)
                                      : null,
                                  onReorder: (po.status == PurchaseOrderStatus.received ||
                                          po.status == PurchaseOrderStatus.partiallyReceived ||
                                          po.status == PurchaseOrderStatus.cancelled)
                                      ? () => _showCreateSheet(
                                          existing: po, isReorder: true)
                                      : null,
                                  onPaySupplier: (po.status == PurchaseOrderStatus.received ||
                                          po.status == PurchaseOrderStatus.partiallyReceived)
                                      ? () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => SupplierPayablesPage(
                                              businessId: widget.businessId,
                                              isSwahili: _isSwahili,
                                            ),
                                          ))
                                      : null,
                                ),
                              ),
                            ),
                            child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        po.poNumber.isNotEmpty
                                            ? po.poNumber
                                            : 'PO-${po.id ?? ""}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(po.status)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _statusLabel(po.status),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _statusColor(po.status)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    po.supplierName ??
                                        (_isSwahili
                                            ? 'Msambazaji'
                                            : 'Supplier'),
                                    style: const TextStyle(
                                        fontSize: 13, color: _kSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'TZS ${nf.format(po.totalAmount)}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary)),
                                    if (po.expectedDeliveryDate != null)
                                      Text(
                                          '${_isSwahili ? "Kupokea" : "Due"}: ${df.format(po.expectedDeliveryDate!)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary)),
                                  ],
                                ),
                                if (po.status == PurchaseOrderStatus.sent ||
                                    po.status == PurchaseOrderStatus.draft ||
                                    po.status == PurchaseOrderStatus.partiallyReceived) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (po.status == PurchaseOrderStatus.draft)
                                        _actionBtn(
                                            _isSwahili ? 'Hariri' : 'Edit',
                                            Icons.edit_rounded,
                                            () => _showCreateSheet(existing: po)),
                                      if (po.status == PurchaseOrderStatus.draft)
                                        _actionBtn(
                                            _isSwahili ? 'Tuma' : 'Send',
                                            Icons.send_rounded,
                                            () => _markSent(po)),
                                      if (po.status == PurchaseOrderStatus.sent ||
                                          po.status == PurchaseOrderStatus.partiallyReceived)
                                        _actionBtn(
                                            _isSwahili
                                                ? 'Pokelewa'
                                                : 'Received',
                                            Icons.check_rounded,
                                            () => _markReceived(po)),
                                      _actionBtn(
                                          _isSwahili ? 'Futa' : 'Cancel',
                                          Icons.cancel_rounded,
                                          () => _cancelOrder(po)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }
}

class _QuickItem {
  final String description;
  final double unitPrice;
  final double quantity;
  _QuickItem(
      {required this.description, this.unitPrice = 0, this.quantity = 1});
}

class _PurchaseOrderDetailPage extends StatelessWidget {
  final PurchaseOrder po;
  final bool isSwahili;
  final VoidCallback onMarkSent;
  final VoidCallback onMarkReceived;
  final VoidCallback onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onReorder;
  final VoidCallback? onPaySupplier;

  const _PurchaseOrderDetailPage({
    required this.po,
    required this.isSwahili,
    required this.onMarkSent,
    required this.onMarkReceived,
    required this.onCancel,
    this.onEdit,
    this.onReorder,
    this.onPaySupplier,
  });

  Color _statusColor(PurchaseOrderStatus s) {
    switch (s) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.sent:
        return Colors.blue;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.orange;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(PurchaseOrderStatus s) {
    if (isSwahili) return poStatusLabel(s);
    switch (s) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.sent:
        return 'Sent';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Partial';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          po.poNumber.isNotEmpty ? po.poNumber : 'PO-${po.id ?? ""}',
          style: const TextStyle(
              color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(po.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(po.status),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(po.status)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(isSwahili ? 'Msambazaji' : 'Supplier',
                po.supplierName ?? '-'),
            if (po.expectedDeliveryDate != null)
              _detailRow(isSwahili ? 'Tarehe ya Kupokea' : 'Expected Delivery',
                  df.format(po.expectedDeliveryDate!)),
            if (po.notes != null && po.notes!.isNotEmpty)
              _detailRow(isSwahili ? 'Maelezo' : 'Notes', po.notes!),
            const SizedBox(height: 16),
            Text(isSwahili ? 'Bidhaa' : 'Items',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            if (po.items.isEmpty)
              Text(isSwahili ? 'Hakuna bidhaa' : 'No items',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
            else
              Container(
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                                  isSwahili ? 'Maelezo' : 'Description',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _kSecondary))),
                          Text(isSwahili ? 'Idadi' : 'Qty',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kSecondary)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 90,
                            child: Text(isSwahili ? 'Jumla' : 'Total',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kSecondary)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...po.items.map((item) {
                      final hasShortfall = item.shortfall != null && item.shortfall! > 0;
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(item.description,
                                          style: const TextStyle(
                                              fontSize: 13, color: _kPrimary))),
                                  Text(item.quantity.toStringAsFixed(0),
                                      style: const TextStyle(
                                          fontSize: 13, color: _kSecondary)),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                        'TZS ${nf.format(item.totalPrice)}',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary)),
                                  ),
                                ],
                              ),
                              if (item.receivedQty != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${isSwahili ? "Pokelewa" : "Received"}: ${item.receivedQty!.toStringAsFixed(0)}'
                                  '${hasShortfall ? "  •  ${isSwahili ? "Kasoro" : "Shortfall"}: ${item.shortfall!.toStringAsFixed(0)}" : ""}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: hasShortfall
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ));
                    }),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isSwahili ? 'JUMLA' : 'TOTAL',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary)),
                          Text('TZS ${nf.format(po.totalAmount)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Draft actions
            if (po.status == PurchaseOrderStatus.draft) ...[
              if (onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit!();
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(isSwahili ? 'Hariri Agizo' : 'Edit Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onMarkSent();
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(isSwahili ? 'Tuma Agizo' : 'Send Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Sent / partially received actions
            if (po.status == PurchaseOrderStatus.sent ||
                po.status == PurchaseOrderStatus.partiallyReceived) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onMarkReceived();
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    po.status == PurchaseOrderStatus.partiallyReceived
                        ? (isSwahili ? 'Kamilisha Kupokea' : 'Complete Receipt')
                        : (isSwahili ? 'Imepokelewa' : 'Mark as Received'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Cancel (draft, sent, or partially received)
            if (po.status == PurchaseOrderStatus.draft ||
                po.status == PurchaseOrderStatus.sent ||
                po.status == PurchaseOrderStatus.partiallyReceived)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel();
                  },
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: Text(isSwahili ? 'Futa Agizo' : 'Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            // Pay Supplier (received PO with outstanding payable)
            if (onPaySupplier != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPaySupplier!();
                  },
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: Text(isSwahili ? 'Lipa Msambazaji' : 'Pay Supplier'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            // Reorder (received or cancelled)
            if (onReorder != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onReorder!();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(isSwahili ? 'Agiza Tena' : 'Reorder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            // Shangazi AI
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/tea'),
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: Text(isSwahili ? 'Omba Ushauri • Shangazi' : 'Ask Shangazi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kSecondary,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary)),
          ),
        ],
      ),
    );
  }
}
