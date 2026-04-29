import 'package:flutter/material.dart';

import '../../food/pages/partner_product_detail_page.dart' as shared;
import '../../tajirika/models/tajirika_models.dart';

/// Housing cluster entry point for the shared partner_product detail page
/// (spec line 951) — covers home-related services like home inspection,
/// interior design, and property management surfaced in lib/housing/.
/// (Property listings themselves use property_listing_detail_page.dart.)
class PartnerProductDetailPage extends StatelessWidget {
  final int productId;
  final PartnerProduct? initial;

  const PartnerProductDetailPage({
    super.key,
    required this.productId,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return shared.PartnerProductDetailPage(
      productId: productId,
      initial: initial,
      cluster: 'housing',
    );
  }
}
