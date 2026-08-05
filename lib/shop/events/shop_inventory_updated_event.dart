class ShopInventoryUpdatedEvent {
  ShopInventoryUpdatedEvent(this.productId, {required this.newQuantity});
  final int productId;
  final int newQuantity;
}
