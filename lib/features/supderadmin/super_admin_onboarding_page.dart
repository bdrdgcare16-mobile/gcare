import 'package:flutter/material.dart';
import 'package:serv_app/models/onboarding_model.dart';
import 'package:serv_app/services/super_admin_onboarding_service_new.dart';
import 'package:serv_app/utils/logout.dart';

import 'super_admin_onboarding_detail_page.dart';

class SuperAdminOnboardingPage extends StatefulWidget {
  const SuperAdminOnboardingPage({super.key});

  @override
  State<SuperAdminOnboardingPage> createState() =>
      _SuperAdminOnboardingPageState();
}

class _SuperAdminOnboardingPageState
    extends State<SuperAdminOnboardingPage> {
  final TextEditingController _searchController = TextEditingController();

  List<OnboardingModel> _onboardings = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOnboardings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOnboardings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await SuperAdminOnboardingService.getAllOnboardings(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status:
            _selectedStatus == 'All' ? null : _selectedStatus.toLowerCase(),
      );

      if (!mounted) return;

      setState(() {
        _onboardings = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<OnboardingModel> get _filteredOnboardings {
    final search = _searchController.text.trim().toLowerCase();

    return _onboardings.where((item) {
      final personal = item.personalDetails;
      final company = item.companyDetails;

      final matchesSearch = search.isEmpty ||
          (personal['fullName']
                  ?.toString()
                  .toLowerCase()
                  .contains(search) ??
              false) ||
          (company['employeeId']
                  ?.toString()
                  .toLowerCase()
                  .contains(search) ??
              false) ||
          (company['department']
                  ?.toString()
                  .toLowerCase()
                  .contains(search) ??
              false) ||
          (company['designation']
                  ?.toString()
                  .toLowerCase()
                  .contains(search) ??
              false) ||
          (company['branchLocation']
                  ?.toString()
                  .toLowerCase()
                  .contains(search) ??
              false);

      final matchesStatus = _selectedStatus == 'All' ||
          item.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalCount => _onboardings.length;

  int _countByStatus(String status) {
    return _onboardings
        .where(
          (item) => item.status.toLowerCase() == status.toLowerCase(),
        )
        .length;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return const Color(0xFF655193);
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await SuperAdminOnboardingService.updateOnboardingStatus(
        id,
        status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchOnboardings();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _openDetails(OnboardingModel onboarding) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuperAdminOnboardingDetailPage(
          onboarding: onboarding,
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    int count,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final cards = [
          _summaryCard(
            'Requests',
            _totalCount,
            Colors.blue,
          ),
          _summaryCard(
            'Approved',
            _countByStatus('approved'),
            Colors.green,
          ),
          _summaryCard(
            'Rejected',
            _countByStatus('rejected'),
            Colors.red,
          ),
          _summaryCard(
            'Completed',
            _countByStatus('completed'),
            const Color(0xFF655193),
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF655193),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final searchField = TextField(
          controller: _searchController,
          decoration: _inputDecoration('Search').copyWith(
            hintText: 'Name, ID, department, designation',
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
            ),
          ),
          onChanged: (_) => setState(() {}),
        );

        final statusField = DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: _inputDecoration('Status'),
          isExpanded: true,
          items: const [
            'All',
            'pending',
            'approved',
            'rejected',
            'completed',
          ]
              .map(
                (status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value ?? 'All';
            });

            _fetchOnboardings();
          },
        );

        if (isMobile) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              statusField,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: searchField,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statusField,
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(
    String label,
    dynamic value,
  ) {
    final text = value?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? '-' : text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(
    OnboardingModel onboarding,
  ) {
    final personal = onboarding.personalDetails;
    final company = onboarding.companyDetails;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  personal['fullName']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(onboarding.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Employee ID: ${company['employeeId']?.toString() ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 18),
          _infoRow(
            'Department',
            company['department'],
          ),
          _infoRow(
            'Designation',
            company['designation'],
          ),
          _infoRow(
            'Branch',
            company['branchLocation'],
          ),
          _infoRow(
            'DOJ',
            company['dateOfJoining'],
          ),
          const SizedBox(height: 10),
          _buildActionButtons(onboarding),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    OnboardingModel onboarding,
  ) {
    final status = onboarding.status.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        final viewButton = OutlinedButton(
          onPressed: () => _openDetails(onboarding),
          child: const Text('View'),
        );

        final approveButton = ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () => _updateStatus(
                    onboarding.id,
                    'approved',
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Approve'),
        );

        final rejectButton = ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () => _updateStatus(
                    onboarding.id,
                    'rejected',
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Reject'),
        );

        final completeButton = ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () => _updateStatus(
                    onboarding.id,
                    'completed',
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF655193),
          ),
          child: const Text('Complete'),
        );

        final buttons = <Widget>[
          viewButton,
          if (status == 'pending') approveButton,
          if (status == 'pending') rejectButton,
          if (status == 'approved') completeButton,
        ];

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                buttons[i],
                if (i != buttons.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < buttons.length; i++) ...[
              Expanded(
                child: buttons[i],
              ),
              if (i != buttons.length - 1)
                const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (_filteredOnboardings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No onboarding requests found',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredOnboardings.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildOnboardingCard(
          _filteredOnboardings[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF6F52A3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOnboardings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Employee',
                          style: TextStyle(color: Color(0xFF1E1B4B)),
                        ),
                        TextSpan(
                          text: ' Onboarding',
                          style: TextStyle(color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 16),
              _buildBodyContent(),
            ],
          ),
        ),
      ),
    );
  }
}