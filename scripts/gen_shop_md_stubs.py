#!/usr/bin/env python3
"""One-shot generator: create missing lib/shop/** files from docs/shop/shop.md blueprint.
Skips paths that already exist. Run from repo root: python3 scripts/gen_shop_md_stubs.py"""

from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHOP = ROOT / "lib" / "shop"

# --- Export forwards (relative path under lib/shop -> target import without lib/shop prefix use relative) ---

EXPORTS: dict[str, str] = {
    # common/widgets → shared / buyer
    "common/widgets/product_card.dart": "export '../../shared/widgets/product_card.dart';",
    "common/widgets/stock_urgency_badge.dart": "export '../../shared/widgets/stock_urgency_badge.dart';",
    "common/widgets/review_section.dart": "export '../../shared/widgets/review_section.dart';",
    "common/widgets/zoomable_image_gallery.dart": "export '../../shared/widgets/zoomable_image_gallery.dart';",
    "common/sheets/filter_bottom_sheet.dart": "export '../../buyer/widgets/filter_bottom_sheet.dart';",
    # search align doc names
    "search/screens/search_screen.dart": "export 'shop_search_screen.dart';\n",
    "search/screens/search_results_screen.dart": "export 'shop_search_results_screen.dart';\n",
    # reviews align doc names
    "reviews/screens/product_reviews_screen.dart": "export 'product_reviews_list_screen.dart';\n",
    # payments wallet_screen doc name
    "payments/screens/wallet_screen.dart": "export 'shop_wallet_screen.dart';\n",
    # offline doc filenames
    "offline/sync/sync_manager.dart": "export 'shop_sync_manager.dart';\n",
    "offline/queue/operation_queue.dart": "export 'shop_operation_queue.dart';\n",
    # events canonical names
    "events/order_created_event.dart": "export 'shop_order_created_event.dart';\n",
    "events/payment_completed_event.dart": "export 'shop_payment_completed_event.dart';\n",
    "events/inventory_updated_event.dart": "export 'shop_inventory_updated_event.dart';\n",
}


def write(rel: str, body: str, overwrite: bool = False) -> bool:
    path = SHOP / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and not overwrite:
        return False
    path.write_text(body.rstrip() + "\n", encoding="utf-8")
    return True


def library_header(src: str) -> str:
    return f"// Generated for docs/shop/shop.md — see {src}\n"


# Minimal stubs (compile-safe, delegate to ShopRepository / ShopExtendedApi where sensible)

STUB_SERVICE = '''import '../../integrations/shop_extended_api.dart';
import '../../data/repositories/shop_repository.dart';

{header}/// Blueprint service (`docs/shop/shop.md`).
class {name} {{
  {name}({{ShopExtendedApi? api, ShopRepository? repo}})
      : _api = api ?? ShopExtendedApi(),
        _repo = repo ?? ShopRepository.instance;
  final ShopExtendedApi _api;
  final ShopRepository _repo;
}}
'''

STUB_PROVIDER = '''import 'package:flutter/foundation.dart';
{header}/// Blueprint notifier (`docs/shop/shop.md`).
class {name} extends ChangeNotifier {{
  {name}();
}}
'''

STUB_WIDGET = '''import 'package:flutter/material.dart';
{header}/// Blueprint widget (`docs/shop/shop.md`).
class {name} extends StatelessWidget {{
  const {name}({{super.key}});
  @override
  Widget build(BuildContext context) {{
    return const SizedBox.shrink();
  }}
}}
'''

SCREEN_REDIRECT = '''import 'package:flutter/material.dart';
{header}/// See implementation under buyer/seller/search routes (`main.dart`).
class {name} extends StatelessWidget {{
  const {name}({{super.key}});
  @override
  Widget build(BuildContext context) {{
    return const Scaffold(
      body: Center(child: Text('{name}')),
    );
  }}
}}
'''


def main() -> None:
    created = 0
    for rel, body in EXPORTS.items():
        if write(rel, library_header(rel) + body):
            created += 1

    # --- core/constants ---
    for fname in ("api_constants", "cache_constants", "route_constants", "ui_constants"):
        rel = f"core/constants/{fname}.dart"
        if (SHOP / rel).exists():
            continue
        body = f"""{library_header(rel)}import '../../config/shop_constants.dart';
import '../../routes/shop_routes.dart';

/// Barrel tying blueprint constants to shipped [`ShopApiPaths`] / [`ShopRoutes`].
abstract final class {fname.title().replace('_', '')} {{
  static String get shopPrefix => ShopApiPaths.prefix;
}}
"""
        if fname == "route_constants":
            body = library_header(rel) + """import '../../routes/shop_routes.dart';

abstract final class RouteConstants {
  static const String shopRoot = ShopRoutes.shop;
}
"""
        if fname == "api_constants":
            body = library_header(rel) + """import '../../config/shop_constants.dart';

abstract final class ApiConstants {
  static String get shopProducts => ShopApiPaths.products;
}
"""
        if fname == "cache_constants":
            body = library_header(rel) + """abstract final class CacheConstants {
  static const Duration productTtl = Duration(hours: 1);
}
"""
        if fname == "ui_constants":
            body = library_header(rel) + """import 'package:flutter/material.dart';

abstract final class UiConstants {
  static const double minTouch = 48;
  static const Color primaryText = Color(0xFF1A1A1A);
}
"""
        write(rel, body)
        created += 1

    # --- core/extensions ---
    for rel_base, code in [
        (
            "currency_extension.dart",
            """extension ShopCurrencyFormat on num {
  String formatTzs() => 'TZS ${toStringAsFixed(0)}';
}
""",
        ),
        (
            "date_extension.dart",
            """extension ShopDateUi on DateTime {
  String get shopShort => toIso8601String().substring(0, 10);
}
""",
        ),
        (
            "context_extension.dart",
            """import 'package:flutter/material.dart';

extension ShopContextX on BuildContext {
  ThemeData get shopTheme => Theme.of(this);
}
""",
        ),
    ]:
        rel = f"core/extensions/{rel_base}"
        if not (SHOP / rel).exists():
            write(rel, library_header(rel) + code)
            created += 1

    # --- core/utils ---
    utils = {
        "currency_formatter.dart": """class CurrencyFormatter {
  static String tzs(num v) => 'TZS ${v.toStringAsFixed(0)}';
}
""",
        "validation_utils.dart": """class ValidationUtils {
  static bool isPositive(num n) => n > 0;
}
""",
        "image_compressor.dart": """/// Placeholder — wire `flutter_image_compress` when product uploads need it.
class ImageCompressor {
  static Future<String?> compressPath(String path) async => path;
}
""",
        "shipping_calculator.dart": """class ShippingCalculator {
  static double combineFees(List<double> fees) =>
      fees.fold(0.0, (a, b) => a + b);
}
""",
        "tax_calculator.dart": """class TaxCalculator {
  static double vat(double net, double rate) => net * rate;
}
""",
    }
    for name, code in utils.items():
        rel = f"core/utils/{name}"
        if not (SHOP / rel).exists():
            write(rel, library_header(rel) + code)
            created += 1

    # --- core/theme ---
    theme_files = {
        "shop_colors.dart": """import 'package:flutter/material.dart';

abstract final class ShopColors {
  static const Color background = Color(0xFFFAFAFA);
  static const Color primaryText = Color(0xFF1A1A1A);
}
""",
        "shop_typography.dart": """import 'package:flutter/material.dart';

abstract final class ShopTypography {
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A),
  );
}
""",
        "shop_theme.dart": """import 'package:flutter/material.dart';
import 'shop_colors.dart';

ThemeData buildShopTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: ShopColors.primaryText,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
""",
    }
    for name, code in theme_files.items():
        rel = f"core/theme/{name}"
        if not (SHOP / rel).exists():
            write(rel, library_header(rel) + code)
            created += 1

    # --- core/network network_checker ---
    rel = "core/network/network_checker.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """import 'package:flutter/foundation.dart';
import '../../../services/network_state_service.dart';

class ShopNetworkChecker {
  static bool get hasConnection =>
      NetworkStateService.instance.isOnline.value;
}
""",
        )
        created += 1

    # --- domain entities (export models) ---
    entities = [
        "product_entity.dart",
        "service_entity.dart",
        "order_entity.dart",
        "cart_entity.dart",
        "ad_entity.dart",
        "promotion_entity.dart",
        "shop_entity.dart",
    ]
    show_map = {
        "product_entity.dart": "Product",
        "service_entity.dart": "Product",
        "order_entity.dart": "Order",
        "cart_entity.dart": "Cart",
        "ad_entity.dart": "Product",
        "promotion_entity.dart": "ProductCategory",
        "shop_entity.dart": "ProductCategory",
    }
    for e in entities:
        rel = f"domain/entities/{e}"
        if not (SHOP / rel).exists():
            show = show_map[e]
            write(
                rel,
                library_header(rel)
                + f"export '../../../models/shop_models.dart' show {show};\n",
            )
            created += 1

    # --- domain usecases (thin) ---
    uc = [
        "add_to_cart.dart",
        "create_order.dart",
        "apply_coupon.dart",
        "process_payment.dart",
        "calculate_shipping.dart",
        "boost_product_post.dart",
        "publish_product_post.dart",
        "create_shop_ad.dart",
    ]
    for u in uc:
        rel = f"domain/usecases/{u}"
        if not (SHOP / rel).exists():
            write(
                rel,
                library_header(rel)
                + """import '../../data/repositories/shop_repository.dart';

/// Use-case façade (`IMPLEMENTATION_PLAN` Phase 2 style).
class UseCasePlaceholder {
  UseCasePlaceholder({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;
  final ShopRepository _repo;
  ShopRepository get repository => _repo;
}
""".replace("UseCasePlaceholder", "".join(w.title() for w in u.replace(".dart", "").split("_"))),
            )
            created += 1

    # Fix usecase class names - simpler: single class per file matching PascalCase
    # Overwrite with cleaner names
    uc_names = {
        "add_to_cart.dart": "AddToCart",
        "create_order.dart": "CreateOrder",
        "apply_coupon.dart": "ApplyCoupon",
        "process_payment.dart": "ProcessPayment",
        "calculate_shipping.dart": "CalculateShipping",
        "boost_product_post.dart": "BoostProductPost",
        "publish_product_post.dart": "PublishProductPost",
        "create_shop_ad.dart": "CreateShopAd",
    }
    for u, cls in uc_names.items():
        rel = f"domain/usecases/{u}"
        body = (
            library_header(rel)
            + f"""import '../../data/repositories/shop_repository.dart';

class {cls} {{
  {cls}({{ShopRepository? repo}}) : _repo = repo ?? ShopRepository.instance;
  final ShopRepository _repo;
}}
"""
        )
        write(rel, body, overwrite=True)

    # validators
    for v in ("product_validator.dart", "checkout_validator.dart", "ad_validator.dart"):
        rel = f"domain/validators/{v}"
        if not (SHOP / rel).exists():
            write(
                rel,
                library_header(rel)
                + """class PlaceholderValidator {
  static bool ok(String? s) => s != null && s.isNotEmpty;
}
""".replace("PlaceholderValidator", v.replace(".dart", "").title().replace("_", "")),
            )
            created += 1

    # data/models barrel
    rel = "data/models/shop_models_export.dart"
    if not (SHOP / rel).exists():
        write(rel, library_header(rel) + "export '../../../models/shop_models.dart';\n")
        created += 1

    rel = "data/sources/remote/shop_remote_source.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """import '../../repositories/shop_repository.dart';

/// Remote API source wrapping [`ShopRepository`].
class ShopRemoteSource {
  ShopRemoteSource({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;
  final ShopRepository _repo;
  ShopRepository get repository => _repo;
}
""",
        )
        created += 1

    rel = "data/sources/local/shop_local_source.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """import '../../../offline/persistence/local_database.dart';

class ShopLocalSource {
  ShopLocalSource({ShopLocalDatabase? db}) : _db = db ?? ShopLocalDatabase();
  final ShopLocalDatabase _db;
}
""",
        )
        created += 1

    rel = "data/dto/shop_dto.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """/// API boundary placeholder — extend when endpoints require dedicated DTOs.
class ShopDto {{
  const ShopDto();
}}
""",
        )
        created += 1

    # split repos thin
    for name, method_hint in [
        ("product_repository.dart", "catalog"),
        ("cart_repository.dart", "cart"),
        ("order_repository.dart", "orders"),
    ]:
        rel = f"data/repositories/{name}"
        if not (SHOP / rel).exists():
            write(
                rel,
                library_header(rel)
                + """import 'shop_repository.dart';

/// Thin delegate on [`ShopRepository`] (`IMPLEMENTATION_PLAN` split repos).
class %s {
  %s({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
"""
                % (
                    name.replace(".dart", "").split("_")[0].title() + "Repository",
                    name.replace(".dart", "").split("_")[0].title() + "Repository",
                ),
            )
            created += 1

    # Fix ProductRepository class name - manual
    write(
        "data/repositories/product_repository.dart",
        library_header("data/repositories/product_repository.dart")
        + """import 'shop_repository.dart';

class ProductRepository {
  ProductRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
""",
        overwrite=True,
    )
    write(
        "data/repositories/cart_repository.dart",
        library_header("data/repositories/cart_repository.dart")
        + """import 'shop_repository.dart';

class CartRepository {
  CartRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
""",
        overwrite=True,
    )
    write(
        "data/repositories/order_repository.dart",
        library_header("data/repositories/order_repository.dart")
        + """import 'shop_repository.dart';

class OrderRepository {
  OrderRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
""",
        overwrite=True,
    )

    # offline product_cache, draft_storage, retry_policy
    rel = "offline/cache/product_cache.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """import '../../../services/shop_database.dart';

class ProductCache {
  ProductCache({ShopDatabase? db}) : _db = db ?? ShopDatabase.instance;
  final ShopDatabase _db;
  Future<void> warm() async => _db.database;
}
""",
        )
        created += 1

    rel = "offline/persistence/draft_storage.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """import 'package:hive_flutter/hive_flutter.dart';

class DraftStorage {
  static const String boxName = 'shop_drafts';
  Future<Box<dynamic>> open() async => Hive.openBox(boxName);
}
""",
        )
        created += 1

    rel = "offline/queue/retry_policy.dart"
    if not (SHOP / rel).exists():
        write(
            rel,
            library_header(rel)
            + """/// Exponential backoff caps for mutation replay.
class RetryPolicy {
  static const int maxAttempts = 3;
  static Duration delayForAttempt(int n) => Duration(seconds: (n + 1).clamp(1, 8));
}
""",
        )
        created += 1

    print(f"Created/updated stubs (approx): check logs — shop dir files")


if __name__ == "__main__":
    main()
