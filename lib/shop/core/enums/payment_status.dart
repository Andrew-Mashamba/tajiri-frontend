// Marketplace checkout / payout lifecycle (shop module — not hair_nails PaymentStatus).
enum PaymentStatus {
  pending,
  authorized,
  captured,
  failed,
  refunded,
}
