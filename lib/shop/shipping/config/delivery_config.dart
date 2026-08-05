// Delivery dispatch configuration — frontend side.
//
// All provider API keys (Sendy, WhatsApp, Piki, AfriDelivery, Lori) are stored
// in the BACKEND's .env file and never exposed to the mobile app.
//
// The frontend calls the TAJIRI backend API which proxies to each provider.
//
// Backend endpoints:
//   POST /api/shop/orders/{id}/dispatch/quotes  — get quotes from all providers
//   POST /api/shop/orders/{id}/dispatch         — dispatch via chosen provider
//   GET  /api/shop/orders/{id}/dispatch/track   — live tracking status
//   POST /api/shop/delivery/webhook/{provider}  — carrier status callbacks (server-side)

class DeliveryConfig {
  DeliveryConfig._();

  // Default seller location used as pickup coordinates when not set on product.
  // Backend will also apply this fallback.
  static const double defaultPickupLat = -6.7924; // Dar es Salaam
  static const double defaultPickupLng = 39.2083;
}
