import 'package:flutter/material.dart';

import '../../food/pages/partner_product_detail_page.dart' as shared;
import '../../tajirika/models/tajirika_models.dart';

/// Mafundi (tradespeople) cluster entry point for the shared partner_product
/// detail page (spec line 951). Forwards to the shared implementation with
/// `cluster='mafundi'` so header/CTA/snackbar copy reads "huduma" instead of
/// "bidhaa". Lives under `lib/mafundi/` per the cluster-location feedback.
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
      cluster: 'mafundi',
    );
  }
}
