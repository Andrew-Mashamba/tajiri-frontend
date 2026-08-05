class ShopPaymentCompletedEvent {
  ShopPaymentCompletedEvent(this.orderId, {required this.amount});
  final int orderId;
  final double amount;
}
