class ShopOrderCreatedEvent {
  ShopOrderCreatedEvent(this.orderId, {this.buyerId});
  final int orderId;
  final int? buyerId;
}
