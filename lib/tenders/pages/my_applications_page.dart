// My tender applications tracking page
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';
import '../widgets/application_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUrgent = Color(0xFFD32F2F);

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<TenderApplication> _allApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    if (mounted) setState(() => _isLoading = true);
    final result = await TenderService.getMyApplications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _allApplications = result.applications;
        }
      });
    }
  }

  List<TenderApplication> _filtered(ApplicationStatus? status) {
    if (status == null) return _allApplications;
    return _allApplications.where((a) => a.status == status).toList();
  }

  Future<void> _editApplication(TenderApplication app) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditApplicationSheet(application: app),
    );

    if (result == null || app.id == null) return;

    final status = result['status'] as ApplicationStatus;
    final notes = result['notes'] as String?;

    final updateResult = await TenderService.updateApplication(
      applicationId: app.id!,
      status: status,
      notes: notes,
    );

    if (mounted) {
      if (updateResult.success) {
        final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSwahili ? 'Ombi limesasishwa' : 'Application updated'), backgroundColor: const Color(0xFF2E7D32)),
        );
        _loadApplications();
      } else {
        final isSwFail = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updateResult.error ?? (isSwFail ? 'Imeshindwa kusasisha' : 'Failed to update')), backgroundColor: _kUrgent),
        );
      }
    }
  }

  Future<void> _deleteApplication(TenderApplication app) async {
    if (app.id == null) return;

    final result = await TenderService.deleteApplication(app.id!);
    if (mounted) {
      if (result.success) {
        setState(() {
          _allApplications.removeWhere((a) => a.id == app.id);
        });
        final isSwDel = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSwDel ? 'Ombi limefutwa' : 'Application deleted')),
        );
      } else {
        final isSwDelFail = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? (isSwDelFail ? 'Imeshindwa kufuta' : 'Failed to delete')), backgroundColor: _kUrgent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSwahili ? 'Maombi Yangu' : 'My Applications',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabAlignment: TabAlignment.start,
          tabs: [
            _buildTab(isSwahili ? 'Zote' : 'All', _allApplications.length),
            _buildTab(isSwahili ? 'Ninapendezwa' : 'Interested', _filtered(ApplicationStatus.interested).length),
            _buildTab(isSwahili ? 'Ninaandaa' : 'Preparing', _filtered(ApplicationStatus.preparing).length),
            _buildTab(isSwahili ? 'Zimewasilishwa' : 'Submitted', _filtered(ApplicationStatus.submitted).length),
            _buildTab(isSwahili ? 'Zimeshinda' : 'Won', _filtered(ApplicationStatus.won).length),
            _buildTab(isSwahili ? 'Hazijashinda' : 'Lost', _filtered(ApplicationStatus.lost).length),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(null),
                _buildList(ApplicationStatus.interested),
                _buildList(ApplicationStatus.preparing),
                _buildList(ApplicationStatus.submitted),
                _buildList(ApplicationStatus.won),
                _buildList(ApplicationStatus.lost),
              ],
            ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(ApplicationStatus? status) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final apps = _filtered(status);

    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              isSwahili ? 'Hakuna maombi' : 'No applications',
              style: const TextStyle(fontSize: 15, color: _kSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              isSwahili
                  ? 'Maombi yako ya zabuni yataonekana hapa'
                  : 'Your tender applications will appear here',
              style: TextStyle(fontSize: 13, color: _kSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return ApplicationCard(
            application: app,
            onEdit: () => _editApplication(app),
            onDelete: () => _deleteApplication(app),
          );
        },
      ),
    );
  }
}

// ============================================================================
// EDIT APPLICATION BOTTOM SHEET
// ============================================================================

class _EditApplicationSheet extends StatefulWidget {
  final TenderApplication application;
  const _EditApplicationSheet({required this.application});

  @override
  State<_EditApplicationSheet> createState() => _EditApplicationSheetState();
}

class _EditApplicationSheetState extends State<_EditApplicationSheet> {
  late ApplicationStatus _selectedStatus;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.application.status;
    _notesController = TextEditingController(text: widget.application.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isSwahili ? 'Sasisha Ombi' : 'Update Application',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.application.tenderTitle ?? widget.application.tenderId,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Status selector
          Text(
            isSwahili ? 'Hali' : 'Status',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ApplicationStatus.values.map((status) {
              final selected = _selectedStatus == status;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = status),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? status.color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? status.color : const Color(0xFFE0E0E0),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 14, color: selected ? status.color : const Color(0xFF999999)),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? status.color : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Notes
          Text(
            isSwahili ? 'Maelezo' : 'Notes',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: isSwahili ? 'Andika maelezo ya hatua...' : 'Add notes about progress...',
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': _selectedStatus,
                  'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isSwahili ? 'Hifadhi' : 'Save', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
