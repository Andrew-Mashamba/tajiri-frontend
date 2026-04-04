import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:vicoba/DataStore.dart';

import '../HttpService.dart';
import '../chooseBank.dart';
import '../enterNumber.dart';
import '../paymentStatus.dart';
import '../waitDialog.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class selectPaymentMethode extends StatelessWidget {
  const selectPaymentMethode({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Methods',
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryBg,
        fontFamily: 'Roboto',
      ),
      home: PaymentMethodScreen(),
    );
  }
}

class PaymentMethodScreen extends StatelessWidget {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  final formatCurrency = NumberFormat.simpleCurrency();
  final String mnologo;
  final String maintitle;

  PaymentMethodScreen({super.key})
      : mnologo = DataStore.userNumberMNO == "VODACOM"
      ? "assets/mpesa.png"
      : "assets/no-avatar.png",
        maintitle = DataStore.userNumberMNO == "VODACOM"
            ? "M - PESA"
            : "Mobile Money";



  Route _routeToPaymentStatus() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const paymentStatus(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    _logger.i('Starting payment process');

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return const waitDialog(
            title: "Tafadhali Subiri",
            descriptions: "Malipo yanafanyika...",
            text: "",
          );
        }
    );

    try {
      DataStore.paymentChanel = "MNO";
      DataStore.paymentInstitution = DataStore.userNumberMNO;

      _logger.d('Payment details', error: {
        'service': DataStore.paymentService,
        'amount': DataStore.paymentAmount,
        'currency': "TZS",
        'userNumber': DataStore.userNumber,
        'serviceId': DataStore.paidServiceId,
        'personId': DataStore.personPaidId,
        'description': DataStore.maelezoYaMalipo
      });

      String? result;
      switch (DataStore.paymentService) {
        case "closeloan":
          result = await HttpService.closeloanPaymentIntentMNO(
              DataStore.paymentAmount,
              "TZS",
              DataStore.userNumber,
              DataStore.paymentService,
              DataStore.paidServiceId,
              DataStore.personPaidId,
              DataStore.maelezoYaMalipo
          );
          break;
        case "rejesho":
          result = await HttpService.rejeshoPaymentIntentMNO(
              DataStore.paymentAmount,
              "TZS",
              DataStore.userNumber,
              DataStore.paymentService,
              DataStore.paidServiceId,
              DataStore.personPaidId,
              DataStore.maelezoYaMalipo
          );
          break;
        case "topup":
          result = await HttpService.topuploanPaymentIntentMNO(
              DataStore.paymentAmount,
              "TZS",
              DataStore.userNumber,
              DataStore.paymentService,
              DataStore.paidServiceId,
              DataStore.personPaidId,
              DataStore.maelezoYaMalipo,
              DataStore.paymentTopUpAmount ?? "0" // Handle null case
          );

          // Update payment description for topup
          final date = DateTime.now();
          final formattedDate = "${date.month}/${date.year}";
          DataStore.maelezoYaMalipo =
          "${DataStore.currentUserName} amepewa Top-up ya mkopo wa shilingi, "
              "mwezi $formattedDate, shilingi ${formatCurrency.format(double.parse(DataStore.paymentAmount.toString())).replaceAll("\$", "")}, "
              "ambapo kiasi cha shilingi${formatCurrency.format(double.parse(DataStore.paymentAmount.toString())).replaceAll("\$", "")} "
              "kitakatwa kulipa mkopo wake unao endelea.";
          break;
        case "ada":
          result = await HttpService.createPaymentIntentMNO(
              DataStore.paymentAmount.toString(),
              "TZS",
              DataStore.userNumber,
              DataStore.userNumberMNO
          );
          break;
        case "hisa":
          result = await HttpService.createPaymentIntentMNO(
              DataStore.paymentAmount.toString(),
              "TZS",
              DataStore.userNumber,
              DataStore.userNumberMNO
          );
          break;
        case "mchango":
          result = await HttpService.createPaymentIntentMNO(
              DataStore.paymentAmount.toString(),
              "TZS",
              DataStore.userNumber,
              DataStore.userNumberMNO
          );
          break;
        default:
          _logger.e('Unknown payment service: ${DataStore.paymentService}');
          throw Exception('Unknown payment service');
      }

      _logger.i('Payment completed with result: $result');

      // Post payment notification
      await _postPaymentNotification();

      // Record contribution payment if this is a mchango payment
      if (DataStore.paymentService == "mchango" && DataStore.paidServiceId != null) {
        await _recordMchangoPayment();
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        Navigator.of(context).push(_routeToPaymentStatus());
      }
    } catch (e, stackTrace) {
      _logger.e('Payment failed', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Malipo yameshindikana: ${e.toString()}'),
              backgroundColor: Colors.blue,
            )
        );
      }
    }
  }

  Future<void> _postPaymentNotification() async {
    try {
      final uuid = const Uuid().v4();
      final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      final thedate = dateFormat.format(DateTime.now());

      final baraza = FirebaseFirestore.instance.collection('${DataStore.currentKikobaId}barazaMessages');

      await baraza.add({
        'posterName': DataStore.currentUserName ?? 'Unknown',
        'posterId': DataStore.currentUserId ?? '',
        'posterNumber': DataStore.userNumber ?? '',
        'posterPhoto': "",
        'postComment': DataStore.maelezoYaMalipo ?? '',
        'postImage': '',
        'postType': 'taarifaYakujiunga',
        'postId': uuid,
        'postTime': thedate,
        'kikobaId': DataStore.currentKikobaId ?? ''
      });

      _logger.i('Payment notification posted successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to post payment notification', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _recordMchangoPayment() async {
    try {
      _logger.i('Recording mchango contribution payment');

      final response = await HttpService.recordMchangoContribution(
        mchangoId: DataStore.paidServiceId!,
        amount: DataStore.paymentAmount is double
            ? DataStore.paymentAmount
            : double.parse(DataStore.paymentAmount.toString()),
        paymentReference: 'MNO-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response != null && response['success'] == true) {
        _logger.i('✅ Mchango contribution recorded successfully');
      } else {
        _logger.w('⚠️ Failed to record mchango contribution: ${response?['message']}');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to record mchango payment', error: e, stackTrace: stackTrace);
      // Don't throw - allow payment to complete even if recording fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        title: const Text(
          'Njia za malipo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false, // AppBar handles top
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          _buildSectionHeader("Njia kuu ya malipo"),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            mnologo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.phone_android_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              maintitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: _primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Lipa kupitia namba yako ya simu ya usajiri",
                              style: TextStyle(
                                fontSize: 13,
                                color: _secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DataStore.userNumber ?? 'Namba haijasajiriwa',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _iconBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _processPayment(context),
                      child: const Text(
                        'Lipa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionHeader("Njia Mbadala"),

          _buildPaymentOption(
            icon: Icons.account_balance,
            title: "Lipa kwa akaunti yako ya benki",
            subtitle: "Bonyeza hapa kuhamisha pesa kutoka akaunti yako ya benki",
            onTap: () {
              DataStore.paymentChanel = "UMOJA BANKS ACCOUNT";
              DataStore.paymentInstitution = "UMOJA BANK";
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const choosebank()),
              );
            },
          ),

          _buildPaymentOption(
            icon: Icons.phone_android,
            title: "Lipa kwa mitandao mingine ya simu",
            subtitle: "Chagua mtandao wa simu",
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildNetworkButton("M - Pesa", () => _payWithMNO(context, "M - PESA")),
                  _buildNetworkButton("Tigo Pesa", () => _payWithMNO(context, "TIGO PESA")),
                  _buildNetworkButton("Airtel Money", () => _payWithMNO(context, "AIRTEL MONEY")),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _secondaryText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    List<Widget>? children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: _primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null && children == null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _accentColor,
                        size: 24,
                      ),
                  ],
                ),
                if (children != null) ...[
                  const SizedBox(height: 12),
                  ...children,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkButton(String label, VoidCallback onPressed) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _payWithMNO(BuildContext context, String institution) {
    _logger.i('Selected MNO payment: $institution');
    DataStore.paymentChanel = "MNO WALLET";
    DataStore.paymentInstitution = institution;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const enterNumber()),
    );
  }

}