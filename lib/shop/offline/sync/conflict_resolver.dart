/// Simple last-write-wins resolver for optimistic numeric fields (e.g. cart quantity).
class ShopConflictResolver {
  ShopConflictResolver._();

  /// Prefer the larger quantity when both sides edited offline (safer for buyer intent).
  static int resolveQuantity(int local, int remote) =>
      local >= remote ? local : remote;
}
