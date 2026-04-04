import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'vicobaList.dart';
import 'HttpService.dart';
import 'kikobaProfile.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _accentColor = Color(0xFF999999);
const _iconBg = Color(0xFF1A1A1A);

class SearchBarx extends StatefulWidget {
  const SearchBarx({super.key});

  @override
  State<SearchBarx> createState() => _SearchBarxState();
}

class _SearchBarxState extends State<SearchBarx> {
  final Logger _logger = Logger();
  bool _isSearching = false;
  bool _hasError = false;
  bool _hasData = false;
  dynamic _searchData;
  String _searchQuery = "";
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResults = 0;
  final int _limit = 20;
  final String _dataUrl = "${HttpService.baseUrl}kikoba/search";

  @override
  void initState() {
    super.initState();
    _logger.i('SearchBarx initialized');
  }

  Future<void> _fetchSuggestions({bool resetPage = true}) async {
    _logger.d('Fetching suggestions for query: $_searchQuery');

    if (_searchQuery.length < 2) {
      _logger.w('Search query too short (min 2 chars)');
      return;
    }

    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(_dataUrl).replace(queryParameters: {
        'query': _searchQuery,
        'limit': _limit.toString(),
        'page': _currentPage.toString(),
        'fields': 'name,location,description',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      _logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        // Check for API error response
        if (decodedData['error'] == true) {
          _logger.e('API error: ${decodedData['errmsg']}');
          setState(() {
            _hasError = true;
            _isSearching = false;
          });
          return;
        }

        _logger.i('Received ${decodedData['data']?.length ?? 0} suggestions');

        // Parse pagination meta
        final meta = decodedData['meta'];
        if (meta != null) {
          _totalResults = meta['total'] ?? 0;
          _totalPages = meta['pages'] ?? 1;
          _currentPage = meta['page'] ?? 1;
        }

        setState(() {
          _searchData = decodedData;
          _isSearching = false;
          _hasData = true;
        });
      } else {
        _logger.e('API error: ${response.statusCode}');
        setState(() {
          _hasError = true;
          _isSearching = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetching suggestions', error: e, stackTrace: stackTrace);
      setState(() {
        _hasError = true;
        _isSearching = false;
      });
    }
  }

  void _loadNextPage() {
    if (_currentPage < _totalPages && !_isSearching) {
      _currentPage++;
      _fetchSuggestions(resetPage: false);
    }
  }

  void _loadPreviousPage() {
    if (_currentPage > 1 && !_isSearching) {
      _currentPage--;
      _fetchSuggestions(resetPage: false);
    }
  }

  void _handleSuggestionTap(SearchSuggestion suggestion) {
    _logger.i('Selected kikoba: ${suggestion.name} (ID: ${suggestion.id})');
    DataStore.visitedKikobaId = suggestion.id;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KikobaProfilePage()),
    );
  }

  void _navigateBack() {
    _logger.d('Navigating back to VikobaListPage');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VikobaListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Building SearchBarx UI');

    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Tafuta Kikoba",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryText),
          onPressed: _navigateBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                _buildSearchInfoCard(),
                const SizedBox(height: 16),
                _buildSearchField(),
                const SizedBox(height: 16),
                _buildSearchResults(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Tafuta Vikoba",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Pata vikoba vilivyosajiriwa kwenye mtandao",
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Andika jina la kikoba...",
          hintStyle: const TextStyle(
            fontSize: 14,
            color: _accentColor,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _secondaryText),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _secondaryText, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _hasData = false;
                      _searchData = null;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryText, width: 1.5),
          ),
          filled: true,
          fillColor: _cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: _primaryText,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
          if (_searchQuery.length >= 2) {
            _fetchSuggestions();
          } else {
            setState(() {
              _hasData = false;
              _searchData = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: _primaryText,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_hasData || _searchData == null || _searchData['data'] == null) {
      return const SizedBox.shrink();
    }

    return _buildSuggestionsList();
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: _secondaryText,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Tatizo la Mtandao",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Hakuna mawasiliano, jaribu tena",
            style: TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: _primaryText,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _fetchSuggestions,
                borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Text(
                    "Jaribu Tena",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    try {
      final suggestions = List<SearchSuggestion>.from(
        _searchData["data"].map<SearchSuggestion>(
              (item) => SearchSuggestion.fromJSON(item),
        ),
      );

      if (suggestions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: _secondaryText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hakuna Matokeo",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Hakuna vikoba vilivyopatikana",
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _buildSuggestionItem(suggestion);
            },
          ),
          _buildPaginationControls(),
        ],
      );
    } catch (e, stackTrace) {
      _logger.e('Error building suggestions list', error: e, stackTrace: stackTrace);
      return _buildErrorWidget();
    }
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleSuggestionTap(suggestion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Kikoba Image/Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: suggestion.image != null && suggestion.image!.isNotEmpty
                        ? null
                        : _iconBg,
                    borderRadius: BorderRadius.circular(12),
                    image: suggestion.image != null && suggestion.image!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(suggestion.image!),
                            fit: BoxFit.cover,
                            onError: (e, _) => _logger.e('Image load error', error: e),
                          )
                        : null,
                  ),
                  child: suggestion.image == null || suggestion.image!.isEmpty
                      ? const Icon(Icons.groups_rounded, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (suggestion.relevance == 'exact')
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primaryBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sawa',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Location & Member Count Row
                      Row(
                        children: [
                          if (suggestion.location != null && suggestion.location!.isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined, size: 12, color: _accentColor),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                suggestion.location!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          const Icon(Icons.people_outline_rounded, size: 12, color: _accentColor),
                          const SizedBox(width: 2),
                          Text(
                            '${suggestion.memberCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                      if (suggestion.description != null && suggestion.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            suggestion.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          Material(
            color: _currentPage > 1 ? _primaryText : _primaryBg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _currentPage > 1 ? _loadPreviousPage : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _currentPage > 1 ? Colors.white : _accentColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_currentPage / $_totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(width: 16),
          // Next Button
          Material(
            color: _currentPage < _totalPages ? _primaryText : _primaryBg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _currentPage < _totalPages ? _loadNextPage : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _currentPage < _totalPages ? Colors.white : _accentColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    if (!_hasData || _totalResults == 0) return const SizedBox.shrink();

    return Text(
      'Vikoba $_totalResults vimepatikana',
      style: const TextStyle(
        fontSize: 12,
        color: _secondaryText,
      ),
    );
  }
}

class SearchSuggestion {
  final String id;
  final String name;
  final String? location;
  final String? description;
  final String? image;
  final int memberCount;
  final String? creator;
  final String? relevance;

  SearchSuggestion({
    required this.id,
    required this.name,
    this.location,
    this.description,
    this.image,
    this.memberCount = 0,
    this.creator,
    this.relevance,
  });

  factory SearchSuggestion.fromJSON(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: json["kikobaid"]?.toString() ?? '',
      name: json["kikobaname"]?.toString() ?? 'Jina haijulikani',
      location: json["location"]?.toString(),
      description: json["description"]?.toString(),
      image: json["image"]?.toString(),
      memberCount: json["member_count"] is int ? json["member_count"] : int.tryParse(json["member_count"]?.toString() ?? '0') ?? 0,
      creator: json["creator"]?.toString(),
      relevance: json["relevance"]?.toString(),
    );
  }
}