// lib/investments/widgets/portfolio_card.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class PortfolioCard extends StatelessWidget {
  final PortfolioSummary portfolio;

  const PortfolioCard({super.key, required this.portfolio});

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = portfolio.totalReturns >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kundi la Uwekezaji',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'TZS ${_fmt(portfolio.totalValue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${portfolio.returnPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPositive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${isPositive ? '+' : ''}TZS ${_fmt(portfolio.totalReturns)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (portfolio.allocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Allocation bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: portfolio.allocations.map((a) {
                    return Expanded(
                      flex: (a.percent * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: _allocationColor(a.category),
                        margin: const EdgeInsets.only(right: 1),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: portfolio.allocations.map((a) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _allocationColor(a.category),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${a.category} ${a.percent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _allocationColor(String category) {
    switch (category.toLowerCase()) {
      case 'bonds':
      case 'bondi':
        return Colors.blueAccent;
      case 'stocks':
      case 'hisa':
        return Colors.greenAccent;
      case 'unit_trusts':
      case 'mifuko':
        return Colors.orangeAccent;
      case 'real_estate':
      case 'nyumba':
        return Colors.purpleAccent;
      case 'agriculture':
      case 'kilimo':
        return Colors.tealAccent;
      case 'savings':
      case 'akiba':
        return Colors.amberAccent;
      default:
        return Colors.white54;
    }
  }
}
