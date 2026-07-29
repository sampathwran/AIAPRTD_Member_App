import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart';
import 'mobile_reload_data.dart';
import 'dart:math' as math;

class MobileReloadPage extends StatefulWidget {
  const MobileReloadPage({super.key});

  @override
  State<MobileReloadPage> createState() => _MobileReloadPageState();
}

class _MobileReloadPageState extends State<MobileReloadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  NetworkProvider? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DataPackage? _selectedPackage;

  // History State
  final List<Map<String, dynamic>> _reloadHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitReload() {
    if (_selectedProvider == null) {
      _showError('Please select a network provider.');
      return;
    }
    if (_phoneController.text.length != 10) {
      _showError('Please enter a valid 10-digit phone number.');
      return;
    }

    double amount = 0;
    if (_selectedPackage != null) {
      amount = _selectedPackage!.price;
    } else {
      amount = double.tryParse(_amountController.text) ?? 0;
    }

    if (amount <= 0) {
      _showError('Please enter a valid amount or select a package.');
      return;
    }

    final currentSavings = context.read<FinanceProvider>().mySavingsBalance;

    if (amount > currentSavings) {
      _showError(
          'Insufficient savings balance. You only have Rs. ${currentSavings.toStringAsFixed(2)}');
      return;
    }

    // Success - Add to history and reset form
    setState(() {
      _reloadHistory.insert(0, {
        'id': 'TRX${math.Random().nextInt(900000) + 100000}',
        'provider': _selectedProvider,
        'phone': _phoneController.text,
        'amount': amount,
        'package': _selectedPackage,
        'date': DateTime.now(),
        'status': 'Pending', // Pending admin approval
      });

      _selectedProvider = null;
      _phoneController.clear();
      _amountController.clear();
      _selectedPackage = null;
      _tabController.animateTo(1); // Go to history tab
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reload request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get real savings balance
    final savingsBalance = context.watch<FinanceProvider>().mySavingsBalance;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mobile Reload',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Savings Balance Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Savings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${savingsBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.primaryColor.withValues(alpha: 0.15),
              ),
              labelColor: theme.primaryColor,
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'New Reload'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewReloadTab(theme, isDark),
                _buildHistoryTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewReloadTab(ThemeData theme, bool isDark) {
    // Filter packages based on selected provider
    final availablePackages = dummyDataPackages
        .where((pkg) =>
            _selectedProvider != null &&
            pkg.providerId == _selectedProvider!.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Network Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: networkProviders.length,
              itemBuilder: (context, index) {
                final provider = networkProviders[index];
                final isSelected = _selectedProvider?.id == provider.id;
                final color = Color(int.parse('0xFF${provider.colorHex}'));

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProvider = provider;
                      _selectedPackage =
                          null; // reset package when provider changes
                    });
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              provider.logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.signal_cellular_alt_rounded,
                                      color: color),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? color
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Phone Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'e.g. 0712345678',
              prefixIcon: const Icon(Icons.phone_android_rounded),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              counterText: '',
            ),
          ),
          if (_selectedProvider != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reload Amount',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_selectedPackage != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPackage = null;
                      });
                    },
                    child: const Text('Clear Package',
                        style: TextStyle(fontSize: 12)),
                  )
              ],
            ),
            if (_selectedPackage == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount (Rs.)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or Select a Package',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],

            const SizedBox(height: 12),
            // Packages List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availablePackages.length,
              itemBuilder: (context, index) {
                final pkg = availablePackages[index];
                final isSelected = _selectedPackage?.id == pkg.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isSelected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPackage = null;
                        } else {
                          _selectedPackage = pkg;
                          _amountController.clear();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            pkg.type == 'Data'
                                ? Icons.wifi_rounded
                                : (pkg.type == 'Voice'
                                    ? Icons.call_rounded
                                    : Icons.star_rounded),
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pkg.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(pkg.description,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Rs. ${pkg.price.toInt()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitReload,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Submit Reload Request',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    if (_reloadHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              "No reload history yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reloadHistory.length,
      itemBuilder: (context, index) {
        final item = _reloadHistory[index];
        final provider = item['provider'] as NetworkProvider;
        final package = item['package'] as DataPackage?;
        final date = item['date'] as DateTime;
        final status = item['status'] as String;

        Color statusColor = Colors.orange;
        if (status == 'Success') statusColor = Colors.green;
        if (status == 'Failed') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              provider.logoUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['phone'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${item['amount']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      package != null ? package.name : 'Direct Top-up',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
