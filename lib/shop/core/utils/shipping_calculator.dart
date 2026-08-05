// Generated for docs/shop/shop.md — see core/utils/shipping_calculator.dart
class ShippingCalculator {
  static double combineFees(List<double> fees) =>
      fees.fold(0.0, (a, b) => a + b);
}
