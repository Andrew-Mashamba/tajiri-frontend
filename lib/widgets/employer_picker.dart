import 'package:flutter/material.dart';
import '../models/education_models.dart';
import '../services/education_service.dart';

/// Design constants per DOCS/DESIGN.md
const Color _primaryText = Color(0xFF1A1A1A);
const Color _secondaryText = Color(0xFF666666);
const Color _accent = Color(0xFF999999);
const double _minTouchTargetDp = 48.0;

/// Employer/Business picker for registration Step 8.
/// Supports DSE, Parastatals, Corporates; search by sector, category, ownership.
/// Touch targets min 48dp; layout per DOCS/DESIGN.md.
class EmployerPicker extends StatefulWidget {
  final Function(Business?) onComplete;
  final VoidCallback onSkip;

  const EmployerPicker({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<EmployerPicker> createState() => _EmployerPickerState();
}

class _EmployerPickerState extends State<EmployerPicker> {
  final BusinessService _service = BusinessService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customEmployerController = TextEditingController();

  Map<String, String> _sectors = {};
  Map<String, String> _ownershipTypes = {};
  String? _selectedSector;
  String? _selectedOwnership;
  String? _selectedCategory; // 'dse' | 'parastatals' | 'corporates'
  List<Business> _businesses = [];
  Business? _selectedBusiness;

  bool _isLoading = true;
  bool _isLoadingBusinesses = false;
  bool _isSearching = false;
  bool _useCustomEmployer = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customEmployerController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final sectors = await _service.getSectors();
      final ownershipTypes = await _service.getOwnershipTypes();
      if (mounted) {
        setState(() {
          _sectors = sectors;
          _ownershipTypes = ownershipTypes;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Imeshindwa kupakia aina za makampuni';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadByCategory(String category) async {
    setState(() {
      _isLoadingBusinesses = true;
      _selectedBusiness = null;
      _selectedSector = null;
      _selectedOwnership = null;
      _selectedCategory = category;
      _searchController.clear();
    });

    try {
      List<Business> businesses;
      switch (category) {
        case 'dse':
          businesses = await _service.getDseCompanies();
          break;
        case 'parastatals':
          businesses = await _service.getParastatals();
          break;
        case 'corporates':
          businesses = await _service.getByOwnership('private');
          break;
        default:
          businesses = [];
      }
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Imeshindwa kupakia makampuni';
          _isLoadingBusinesses = false;
        });
      }
    }
  }

  Future<void> _loadBySector(String sector) async {
    setState(() {
      _isLoadingBusinesses = true;
      _selectedBusiness = null;
      _selectedOwnership = null;
      _selectedCategory = null;
    });

    try {
      final businesses = await _service.getBySector(sector);
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Imeshindwa kupakia makampuni';
          _isLoadingBusinesses = false;
        });
      }
    }
  }

  Future<void> _loadByOwnership(String ownership) async {
    setState(() {
      _isLoadingBusinesses = true;
      _selectedBusiness = null;
      _selectedSector = null;
      _selectedCategory = null;
    });

    try {
      final businesses = await _service.getByOwnership(ownership);
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Imeshindwa kupakia makampuni';
          _isLoadingBusinesses = false;
        });
      }
    }
  }

  Future<void> _searchBusinesses(String query) async {
    if (query.length < 2) {
      setState(() {
        _businesses = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedCategory = null;
    });

    try {
      final businesses = await _service.search(query);
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _handleContinue() {
    if (_useCustomEmployer) {
      final customBusiness = Business(
        id: 0,
        code: 'CUSTOM',
        name: _customEmployerController.text.trim(),
      );
      widget.onComplete(customBusiness);
    } else {
      widget.onComplete(_selectedBusiness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Mwajiri',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unafanya kazi wapi sasa?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: _minTouchTargetDp,
                    child: ElevatedButton(
                      onPressed: _loadFilters,
                      child: const Text('Jaribu tena'),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildCustomEmployerSwitch(),
            const SizedBox(height: 16),

            if (_useCustomEmployer)
              _buildCustomEmployerField()
            else ...[
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              _buildSectorOwnershipFilters(),
              const SizedBox(height: 16),
              _buildBusinessList(),
            ],
          ],

          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCustomEmployerSwitch() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          setState(() {
            _useCustomEmployer = !_useCustomEmployer;
            if (_useCustomEmployer) _selectedBusiness = null;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ingiza mwajiri mwenyewe',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kama mwajiri wako haupo kwenye orodha',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useCustomEmployer,
                onChanged: (value) {
                  setState(() {
                    _useCustomEmployer = value;
                    if (value) _selectedBusiness = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomEmployerField() {
    return Container(
      constraints: const BoxConstraints(minHeight: _minTouchTargetDp + 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _customEmployerController,
        decoration: const InputDecoration(
          labelText: 'Jina la Kampuni/Mwajiri',
          hintText: 'Mfano: ABC Company Ltd',
          prefixIcon: Icon(Icons.business, color: _primaryText),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      constraints: const BoxConstraints(minHeight: _minTouchTargetDp + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tafuta kampuni...',
          hintStyle: const TextStyle(color: _secondaryText),
          prefixIcon: const Icon(Icons.search, color: _primaryText),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: _primaryText),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _businesses = []);
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _searchBusinesses,
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = [
      ('dse', 'DSE'),
      ('parastatals', 'Parastatals'),
      ('corporates', 'Corporates'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((e) {
        final selected = _selectedCategory == e.$1;
        return FilterChip(
          label: Text(e.$2),
          selected: selected,
          onSelected: (v) {
            setState(() => _selectedCategory = v ? e.$1 : null);
            if (v) _loadByCategory(e.$1);
          },
          selectedColor: _accent.withOpacity(0.3),
          checkmarkColor: _primaryText,
        );
      }).toList(),
    );
  }

  Widget _buildSectorOwnershipFilters() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sekta',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _primaryText,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSector,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Chagua'),
                items: _sectors.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSector = value);
                    _loadBySector(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Umiliki',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _primaryText,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedOwnership,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Chagua'),
                items: _ownershipTypes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedOwnership = value);
                    _loadByOwnership(value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessList() {
    if (_isLoadingBusinesses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_businesses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Makampuni (${_businesses.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _primaryText,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _accent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _businesses.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: _accent.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final biz = _businesses[index];
              final isSelected = _selectedBusiness?.id == biz.id;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedBusiness = biz),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _minTouchTargetDp),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  biz.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: _primaryText,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (biz.ownershipLabel.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    biz.ownershipLabel,
                                    style: const TextStyle(
                                      color: _secondaryText,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: _primaryText, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canContinue = _useCustomEmployer
        ? _customEmployerController.text.trim().isNotEmpty
        : _selectedBusiness != null;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 72,
            child: OutlinedButton(
              onPressed: widget.onSkip,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryText),
                foregroundColor: _primaryText,
              ),
              child: const Text('Ruka'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            height: 72,
            constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              child: InkWell(
                onTap: canContinue ? _handleContinue : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    'Maliza',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: canContinue ? _primaryText : _secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
