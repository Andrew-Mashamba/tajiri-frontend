import 'package:flutter/material.dart';
import '../../business/models/business_models.dart';
import 'clients_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class ClientsBusinessesPage extends StatefulWidget {
  final List<Business> businesses;
  const ClientsBusinessesPage({super.key, required this.businesses});

  @override
  State<ClientsBusinessesPage> createState() => _ClientsBusinessesPageState();
}

class _ClientsBusinessesPageState extends State<ClientsBusinessesPage> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.businesses.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: SafeArea(
          child: Center(
            child: Text(
              'No business found',
              style: TextStyle(color: _kSecondary),
            ),
          ),
        ),
      );
    }
    final current = widget.businesses[_selectedIdx];
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: widget.businesses.length,
                itemBuilder: (_, i) {
                  final b = widget.businesses[i];
                  final selected = i == _selectedIdx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedIdx = i),
                      label: Text(
                        b.name.isEmpty ? 'Business ${i + 1}' : b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selectedColor: _kPrimary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: selected ? _kPrimary : _kSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: current.id == null
                  ? const Center(
                      child: Text(
                        'Invalid business',
                        style: TextStyle(color: _kSecondary),
                      ),
                    )
                  : ClientsPage(
                      key: ValueKey('clients_business_${current.id}'),
                      businessId: current.id!,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

