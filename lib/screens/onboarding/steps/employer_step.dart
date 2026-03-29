import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/education_models.dart';
import '../../../models/registration_models.dart';
import '../../../services/education_service.dart';
import '../../../widgets/tap_chip_selector.dart';

/// Chapter 4: Current Employer Search.
///
/// Asks "Unafanya kazi wapi sasa?" and lets the user search for their employer
/// via type-ahead against the /businesses/search API. If the employer is not
/// found the user can enter a custom name and pick a sector chip.
///
/// Selection is written into [state.currentEmployer] as an [EmployerEntry].
/// Skip ("Sina kazi kwa sasa") clears [state.currentEmployer] and calls [onSkip].
class EmployerStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const EmployerStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<EmployerStep> createState() => _EmployerStepState();
}

// ---------------------------------------------------------------------------
// Sector chip data
// ---------------------------------------------------------------------------

const List<_Sector> _kSectors = [
  _Sector('technology', 'Teknolojia'),
  _Sector('education', 'Elimu'),
  _Sector('health', 'Afya'),
  _Sector('business', 'Biashara'),
  _Sector('government', 'Serikali'),
  _Sector('other', 'Nyingine'),
];

class _Sector {
  final String code;
  final String label;
  const _Sector(this.code, this.label);

  @override
  bool operator ==(Object other) => other is _Sector && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _EmployerStepState extends State<EmployerStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _border = Color(0xFFE0E0E0);

  final _service = BusinessService();
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  final _scrollController = ScrollController();

  // Search state
  List<Business> _results = [];
  bool _isSearching = false;
  bool _showDropdown = false;
  Timer? _debounce;

  // Selection state
  Business? _selectedBusiness;
  bool _isCustom = false;
  _Sector? _selectedSector;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _prefillFromState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _customController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pre-fill
  // ---------------------------------------------------------------------------

  void _prefillFromState() {
    final e = widget.state.currentEmployer;
    if (e == null) return;

    if (e.isCustomEmployer) {
      _isCustom = true;
      _customController.text = e.employerName ?? '';
      if (e.sector != null) {
        try {
          _selectedSector = _kSectors.firstWhere((s) => s.code == e.sector);
        } catch (_) {}
      }
    } else if (e.employerName != null) {
      _searchController.text = e.employerName!;
      // Reconstruct a lightweight Business so the selection highlight works.
      _selectedBusiness = Business(
        id: e.employerId ?? 0,
        code: e.employerCode ?? '',
        name: e.employerName!,
        sector: e.sector,
        ownership: e.ownership,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _showDropdown = false;
        _isSearching = false;
        if (_selectedBusiness != null &&
            query.trim() != _selectedBusiness!.name) {
          _selectedBusiness = null;
        }
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await _service.search(query.trim());
        if (!mounted) return;
        setState(() {
          _results = results;
          _isSearching = false;
          _showDropdown = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _showDropdown = false;
        });
      }
    });
  }

  void _selectBusiness(Business biz) {
    setState(() {
      _selectedBusiness = biz;
      _showDropdown = false;
      _searchController.text = biz.displayName;
      _results = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _addCustomEmployer() {
    setState(() {
      _isCustom = true;
      _showDropdown = false;
      _results = [];
      _selectedBusiness = null;
      _customController.text = _searchController.text.trim();
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _cancelCustom() {
    setState(() {
      _isCustom = false;
      _selectedSector = null;
      _customController.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Submit / skip
  // ---------------------------------------------------------------------------

  bool get _canContinue {
    if (_isCustom) {
      return _customController.text.trim().isNotEmpty;
    }
    return _selectedBusiness != null;
  }

  void _handleNext() {
    if (!_canContinue) return;

    if (_isCustom) {
      widget.state.currentEmployer = EmployerEntry(
        employerName: _customController.text.trim(),
        sector: _selectedSector?.code,
        isCustomEmployer: true,
      );
    } else {
      final biz = _selectedBusiness!;
      widget.state.currentEmployer = EmployerEntry(
        employerId: biz.id,
        employerCode: biz.code,
        employerName: biz.name,
        sector: biz.sector,
        ownership: biz.ownership,
        isCustomEmployer: false,
      );
    }

    widget.onNext();
  }

  void _handleSkip() {
    widget.state.currentEmployer = null;
    widget.onSkip?.call();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showDropdown) setState(() => _showDropdown = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: _isCustom
                      ? _buildCustomSection()
                      : _buildSearchSection(),
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unafanya kazi wapi sasa?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kampuni au biashara yako',
          style: TextStyle(
            fontSize: 15,
            color: _secondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search section
  // ---------------------------------------------------------------------------

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        if (_showDropdown && (_results.isNotEmpty || _isSearching))
          _buildDropdown(),
        if (_selectedBusiness != null && !_showDropdown)
          _buildSelectedCard(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 15, color: _primary),
        decoration: InputDecoration(
          hintText: 'Tafuta kampuni au mwajiri...',
          hintStyle: const TextStyle(color: _secondary, fontSize: 15),
          prefixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
                )
              : const Icon(Icons.search_rounded, color: _secondary, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: _secondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _showDropdown = false;
                      _selectedBusiness = null;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          // +1 for "Ongeza kampuni" row at the bottom
          itemCount: _results.length + 1,
          itemBuilder: (context, index) {
            if (index == _results.length) {
              return _buildAddCompanyTile();
            }
            return _buildResultTile(_results[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildResultTile(Business biz, int index) {
    final isLast = index == _results.length - 1;
    return InkWell(
      onTap: () => _selectBusiness(biz),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Color.fromRGBO(224, 224, 224, 0.6)),
                ),
        ),
        child: Row(
          children: [
            const Icon(Icons.business_rounded, size: 18, color: _secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    biz.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (biz.ownershipLabel.isNotEmpty &&
                      biz.ownership != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      biz.ownershipLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCompanyTile() {
    return InkWell(
      onTap: _addCustomEmployer,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border(
            top: BorderSide(color: Color.fromRGBO(224, 224, 224, 0.6)),
          ),
        ),
        child: Row(
          children: const [
            Icon(Icons.add_business_rounded, size: 18, color: _primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ongeza kampuni',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    final biz = _selectedBusiness!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 20, color: _primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  biz.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (biz.ownership != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    biz.ownershipLabel,
                    style: const TextStyle(fontSize: 12, color: _secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18, color: _secondary),
            tooltip: 'Badilisha',
            onPressed: () {
              setState(() {
                _selectedBusiness = null;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom employer section
  // ---------------------------------------------------------------------------

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back-to-search link
        GestureDetector(
          onTap: _cancelCustom,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_back_rounded, size: 16, color: _secondary),
              SizedBox(width: 4),
              Text(
                'Rudi kutafuta',
                style: TextStyle(fontSize: 13, color: _secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Custom name field
        const Text(
          'Jina la kampuni / mwajiri',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: _customController,
            onChanged: (_) => setState(() {}),
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 15, color: _primary),
            decoration: const InputDecoration(
              hintText: 'Mfano: ABC Company Ltd',
              hintStyle: TextStyle(color: _secondary, fontSize: 15),
              prefixIcon:
                  Icon(Icons.business_rounded, color: _secondary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              isDense: true,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Sector chips
        const Text(
          'Sekta (hiari)',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
        ),
        const SizedBox(height: 12),
        TapChipSelector<_Sector>(
          options: _kSectors,
          selectedOption: _selectedSector,
          labelBuilder: (s) => s.label,
          onSelected: (s) => setState(() => _selectedSector = s),
          horizontal: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary continue button
        SizedBox(
          height: 52,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _canContinue ? 1.0 : 0.45,
            child: FilledButton(
              onPressed: _canContinue ? _handleNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Endelea',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),

        // Skip link
        if (widget.onSkip != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _handleSkip,
              style: TextButton.styleFrom(
                foregroundColor: _secondary,
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Sina kazi kwa sasa',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
