import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/order.dart';

class EarningsScreen extends StatefulWidget {
  final List<Order> orders;
  const EarningsScreen({super.key, required this.orders});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with TickerProviderStateMixin {
  String _selectedDateRange = 'This Month';
  double _monthlyGoal = 3000.0;
  bool _isUsd = true;
  final double _exchangeRate = 120.0;
  late AnimationController _countAnimationController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _countAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnimation = Tween<double>(begin: 0, end: _calculateNetProfit()).animate(
      CurvedAnimation(parent: _countAnimationController, curve: Curves.easeOut),
    );
    _countAnimationController.forward();
  }

  @override
  void dispose() {
    _countAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyGoal = prefs.getDouble('monthly_goal') ?? 3000.0;
    });
  }

  double _getFeeMultiplier(Platform platform) {
    switch (platform) {
      case Platform.fiverr:
        return 0.8; // 20% fee
      case Platform.upwork:
        return 0.9; // 10% fee
      case Platform.direct:
        return 1.0; // 0% fee
    }
  }

  double _calculateGrossEarnings() {
    return widget.orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.price);
  }

  double _calculateNetProfit() {
    return widget.orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + (o.price * _getFeeMultiplier(o.platform)));
  }

  double _calculatePendingClearance() {
    return widget.orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.price);
  }

  String _formatCurrency(double amount) {
    final value = _isUsd ? amount : amount * _exchangeRate;
    final String symbol = _isUsd ? '\$' : '৳';
    return '$symbol${NumberFormat('#,###.##').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _countAnimation = Tween<double>(begin: 0, end: _calculateNetProfit()).animate(
              CurvedAnimation(parent: _countAnimationController, curve: Curves.easeOut),
            );
          });
          _countAnimationController.reset();
          _countAnimationController.forward();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 32),
              _buildChartSection(),
              const SizedBox(height: 32),
              _buildPlatformBreakdown(),
              const SizedBox(height: 32),
              _buildOrderStatusBreakdown(),
              const SizedBox(height: 32),
              _buildMonthlyGoal(),
              const SizedBox(height: 32),
              _buildQuickStatsRow(),
              const SizedBox(height: 32),
              _buildTopOrders(),
              const SizedBox(height: 32),
              _buildRecentTransactions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earnings Engine',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '100% Realistic Logic Enabled',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildCurrencyToggle(),
          const SizedBox(width: 12),
          _buildDateRangePill(),
        ],
      ),
    );
  }

  Widget _buildCurrencyToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isUsd = !_isUsd;
          // Trigger animation refresh for the main total
          _countAnimation = Tween<double>(begin: 0, end: _calculateNetProfit()).animate(
            CurvedAnimation(parent: _countAnimationController, curve: Curves.easeOut),
          );
          _countAnimationController.reset();
          _countAnimationController.forward();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isUsd 
              ? [const Color(0xFF3B82F6), const Color(0xFF6366F1)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isUsd ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withAlpha(50),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_isUsd ? Icons.attach_money : Icons.currency_lira, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              _isUsd ? 'USD' : 'BDT',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePill() {
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Row(
          children: [
            Text(
              '$_selectedDateRange ↓',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'This Week', 'This Month', 'Last Month', 'All Time'].map((range) {
          return ListTile(
            title: Text(range, style: const TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _selectedDateRange = range);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCard() {
    final netProfit = _calculateNetProfit();
    final grossEarnings = _calculateGrossEarnings();
    final pendingClearance = _calculatePendingClearance();
    final completedOrders = widget.orders.where((o) => o.status == OrderStatus.completed).length;
    final taxVaultAmount = netProfit * 0.15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withAlpha(150),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(30),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Profit (After Fees)', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
              const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                _formatCurrency(_countAnimation.value),
                style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
              );
            },
          ),
          const SizedBox(height: 16),
          // Tax Vault Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF59E0B).withAlpha(40), const Color(0xFFD97706).withAlpha(20)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withAlpha(30), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B), size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Locked in Tax Vault (15%)',
                        style: GoogleFonts.inter(color: const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(taxVaultAmount),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildHeroStat('Gross Earnings', _formatCurrency(grossEarnings))),
              Container(width: 1, height: 40, color: Colors.white.withAlpha(15)),
              const SizedBox(width: 24),
              Expanded(child: _buildHeroStat('Pending Clearance', _formatCurrency(pendingClearance))),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroStat('Completed', completedOrders.toString(), isSmall: true),
              _buildHeroStat('Avg Project', _formatCurrency(completedOrders > 0 ? netProfit / completedOrders : 0), isSmall: true),
              _buildHeroStat('Success Rate', '100%', isSmall: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, {bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: isSmall ? 16 : 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withAlpha(150),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(10),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Performance', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const Icon(Icons.trending_up, color: Color(0xFF3B82F6), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: BarChart(_buildBarChartData()),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData() {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    final Map<int, double> weeklyNetProfit = {};

    // Get net profit for each of the last 7 days
    for (var order in widget.orders) {
      if (order.status == OrderStatus.completed) {
        final orderDate = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(orderDate).inDays;
        
        if (diff >= 0 && diff < 7) {
          final dayIndex = 6 - diff;
          final net = order.price * _getFeeMultiplier(order.platform);
          weeklyNetProfit[dayIndex] = (weeklyNetProfit[dayIndex] ?? 0) + net;
        }
      }
    }

    final maxVal = _calculateMaxWeekly(weeklyNetProfit);

    for (int i = 0; i < 7; i++) {
      final value = weeklyNetProfit[i] ?? 0.0;
      final displayValue = _isUsd ? value : value * _exchangeRate;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: displayValue,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF3B82F6).withAlpha(150),
                  const Color(0xFF60A5FA),
                  const Color(0xFF93C5FD), // Neon highlight at top
                ],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.2,
                color: const Color(0xFF3B82F6).withAlpha(10),
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxVal > 0 ? maxVal / 4 : 10,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withAlpha(10),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final date = now.subtract(Duration(days: 6 - value.toInt()));
              final isToday = value.toInt() == 6;
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  isToday ? 'TOD' : DateFormat('E').format(date).toUpperCase().substring(0, 1),
                  style: GoogleFonts.inter(
                    color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1E293B),
          tooltipRoundedRadius: 12,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final date = now.subtract(Duration(days: 6 - group.x.toInt()));
            return BarTooltipItem(
              '${DateFormat('EEEE, MMM d').format(date)}\n',
              GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              children: [
                TextSpan(
                  text: _formatCurrency(rod.toY / (_isUsd ? 1 : _exchangeRate)),
                  style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _calculateMaxWeekly(Map<int, double> weeklyData) {
    double maxVal = 100;
    for (var v in weeklyData.values) {
      if (v > maxVal) maxVal = v;
    }
    return _isUsd ? maxVal : maxVal * _exchangeRate;
  }

  Widget _buildPlatformBreakdown() {
    final fiverrOrders = widget.orders.where((o) => o.platform == Platform.fiverr).toList();
    final upworkOrders = widget.orders.where((o) => o.platform == Platform.upwork).toList();
    final directOrders = widget.orders.where((o) => o.platform == Platform.direct).toList();

    final fiverrNet = fiverrOrders.where((o) => o.status == OrderStatus.completed).fold(0.0, (sum, o) => sum + (o.price * _getFeeMultiplier(Platform.fiverr)));
    final upworkNet = upworkOrders.where((o) => o.status == OrderStatus.completed).fold(0.0, (sum, o) => sum + (o.price * _getFeeMultiplier(Platform.upwork)));
    final directNet = directOrders.where((o) => o.status == OrderStatus.completed).fold(0.0, (sum, o) => sum + (o.price * _getFeeMultiplier(Platform.direct)));
    
    final grandTotalNet = fiverrNet + upworkNet + directNet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Platform Net Profit', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6).withAlpha(30)),
              ),
              child: Text(
                'LIVE SYNC',
                style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPlatformCard(
                'Fiverr (20%)', 
                fiverrNet, 
                fiverrOrders.where((o) => o.status == OrderStatus.completed).length, 
                const Color(0xFF1DBF73), 
                grandTotalNet,
                iconText: 'F',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'Upwork (10%)', 
                upworkNet, 
                upworkOrders.where((o) => o.status == OrderStatus.completed).length, 
                const Color(0xFF6FDA44), 
                grandTotalNet,
                iconText: 'U',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPlatformCard(
          'Direct Clients (0%)', 
          directNet, 
          directOrders.where((o) => o.status == OrderStatus.completed).length, 
          const Color(0xFF8B5CF6), 
          grandTotalNet, 
          isFullWidth: true,
          iconText: 'D',
        ),
      ],
    );
  }

  Widget _buildPlatformCard(String label, double earned, int orders, Color color, double grandTotal, {bool isFullWidth = false, String? iconText}) {
    final percent = grandTotal > 0 ? earned / grandTotal : 0.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 20,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withAlpha(150),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withAlpha(30), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (iconText != null) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: color.withAlpha(40), shape: BoxShape.circle),
                            child: Center(child: Text(iconText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                    Text('${(percent * 100).toInt()}%', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(_formatCurrency(earned), style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$orders Projects', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w400)),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withAlpha(150), color],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(100),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusBreakdown() {
    final delivered = _calculatePendingClearance();
    final inProgress = widget.orders.where((o) => o.status == OrderStatus.inProgress).fold(0.0, (sum, o) => sum + o.price);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipeline Value', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildPipelineItem('Delivered', delivered, const Color(0xFF10B981), Icons.outgoing_mail),
            const SizedBox(width: 12),
            _buildPipelineItem('In Progress', inProgress, const Color(0xFF3B82F6), Icons.sync),
          ],
        ),
      ],
    );
  }

  Widget _buildPipelineItem(String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withAlpha(150),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 16),
            Text(_formatCurrency(value), style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGoal() {
    final netProfit = _calculateNetProfit();
    final percent = (netProfit / _monthlyGoal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withAlpha(40), const Color(0xFF6366F1).withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Target', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              Text('${(percent * 100).toInt()}%', style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.white.withAlpha(10),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatCurrency(netProfit), style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Goal: ${_formatCurrency(_monthlyGoal)}', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return const SizedBox.shrink(); // Removing redundant old stats
  }

  Widget _buildTopOrders() {
    final completed = widget.orders.where((o) => o.status == OrderStatus.completed).toList();
    completed.sort((a, b) => b.price.compareTo(a.price));
    final topOrders = completed.take(3).toList();

    if (topOrders.isEmpty) return const SizedBox.shrink();

    return Column(      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('High-Value Projects', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...topOrders.map((o) => _buildTransactionItem(o)),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final completed = widget.orders.where((o) => o.status == OrderStatus.completed).toList();
    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = completed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clearance History', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Text('No cleared transactions yet.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14))
        else
          ...recent.map((o) => _buildTransactionItem(o)),
      ],
    );
  }

  Widget _buildTransactionItem(Order o) {
    final net = o.price * _getFeeMultiplier(o.platform);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: o.platform.bgColor.withAlpha(30), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, color: o.platform.bgColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(DateFormat('MMM d, yyyy').format(o.createdAt), style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(net), style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('Gross: ${_formatCurrency(o.price)}', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
