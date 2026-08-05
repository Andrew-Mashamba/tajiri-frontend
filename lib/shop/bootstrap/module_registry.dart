/// Shop sub-areas that are **actually present** under `lib/shop` and wired into the app.
///
/// (Legacy blueprint modules such as ads/AI were removed until they ship with real API contracts.)
class ModuleRegistry {
  ModuleRegistry._();

  static const List<String> _modules = [
    'bootstrap',
    'config',
    'data',
    'buyer',
    'seller',
    'shared',
    'offline',
    'routes',
    'search',
    'reviews',
    'checkout',
    'payments',
    'social_commerce',
    'chat',
    'analytics',
    'integrations',
    'ads',
    'testing',
    'events',
  ];

  static List<String> get modules => List.unmodifiable(_modules);
}
