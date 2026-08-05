import 'package:flutter/material.dart';

enum CheckoutPaymentMethod { wallet, cod }

extension CheckoutPaymentMethodExt on CheckoutPaymentMethod {
  String get label =>
      this == CheckoutPaymentMethod.wallet ? 'Tajiri Pay' : 'Cash on Delivery';

  String get subtitle => this == CheckoutPaymentMethod.wallet
      ? 'Pay with your Tajiri wallet balance'
      : 'Pay cash when your order arrives';

  IconData get icon => this == CheckoutPaymentMethod.wallet
      ? Icons.account_balance_wallet_rounded
      : Icons.money_rounded;

  String get value =>
      this == CheckoutPaymentMethod.wallet ? 'wallet' : 'cod';

  static CheckoutPaymentMethod fromString(String value) {
    switch (value) {
      case 'cod':
        return CheckoutPaymentMethod.cod;
      case 'wallet':
      default:
        return CheckoutPaymentMethod.wallet;
    }
  }
}
