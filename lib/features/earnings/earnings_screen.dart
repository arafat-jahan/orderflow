import 'package:flutter/material.dart';
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
  String _chartPeriod = '30D';
  double _monthlyGoal = 3000.0;
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
    _countAnimation = Tween<double>(begin: 0, end: _calculateTotalEarned()).animate(
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

  Future<void> _saveGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_goal', goal);
  }

  double _calculateTotalEarned() {
    return widget.orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.price);
  }

  double _calculatePending() {
    return widget.orders
        .where((o) => o.status != OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _countAnimation = Tween<double>(begin: 0, end: _calculateTotalEarned()).animate(
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
      backgroundColor: const Color(0xFF0A0F1E),
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
                  'Earnings',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your financial overview',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          _buildDateRangePill(),
        ],
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
    final totalEarned = _calculateTotalEarned();
    final completedOrders = widget.orders.where((o) => o.status == OrderStatus.completed).length;
    final avgValue = completedOrders > 0 ? totalEarned / completedOrders : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2D45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earned', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                '\$${NumberFormat('#,###').format(_countAnimation.value.toInt())}',
                style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text('+12% vs last month', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E2D45)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroStat('Completed', completedOrders.toString()),
              _buildHeroStat('Avg Value', '\$${avgValue.toInt()}'),
              _buildHeroStat('Best Month', 'Oct'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Revenue Over Time', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            _buildChartPeriodTabs(),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(_buildChartData()),
        ),
      ],
    );
  }

  Widget _buildChartPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ['7D', '30D', '90D'].map((p) {
          final isSelected = _chartPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _chartPeriod = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  LineChartData _buildChartData() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final Map<int, double> dailyEarnings = {};

    // Group earnings by day for the last 30 days
    for (var order in widget.orders) {
      if (order.status == OrderStatus.completed) {
        final diff = now.difference(order.createdAt).inDays;
        if (diff >= 0 && diff < 30) {
          final dayIndex = 29 - diff;
          dailyEarnings[dayIndex] = (dailyEarnings[dayIndex] ?? 0) + order.price;
        }
      }
    }

    // Create spots from daily earnings
    double runningTotal = 0;
    for (int i = 0; i < 30; i++) {
      runningTotal += dailyEarnings[i] ?? 0;
      // Map 30 days to 10 points for smoother chart or more granularity
      if (i % 3 == 0) {
        spots.add(FlSpot((i / 3).toDouble(), runningTotal));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF1E2D45), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: Color(0xFF4B5563), fontSize: 10);
              final index = value.toInt();
              if (index < 0 || index > 9) return const Text('');
              
              // Map index back to date
              final dayOffset = index * 3;
              final date = now.subtract(Duration(days: 29 - dayOffset));
              
              // Only show every 3rd label
              if (index % 3 == 0 || index == 9) {
                return Text(DateFormat('MMM d').format(date), style: style);
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('');
              return Text('\$${value.toInt()}', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10));
            },
            reservedSize: 35,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
          isCurved: true,
          color: const Color(0xFF3B82F6),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF3B82F6).withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1A2235),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final dayOffset = spot.x.toInt() * 3;
              final date = now.subtract(Duration(days: 29 - dayOffset));
              return LineTooltipItem(
                '${DateFormat('MMM d').format(date)}\n\$${spot.y.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildPlatformBreakdown() {
    final fiverrOrders = widget.orders.where((o) => o.platform == Platform.fiverr).toList();
    final upworkOrders = widget.orders.where((o) => o.platform == Platform.upwork).toList();
    final directOrders = widget.orders.where((o) => o.platform == Platform.direct).toList();

    final fiverrEarned = fiverrOrders.fold(0.0, (sum, o) => sum + o.price);
    final upworkEarned = upworkOrders.fold(0.0, (sum, o) => sum + o.price);
    final directEarned = directOrders.fold(0.0, (sum, o) => sum + o.price);
    
    final grandTotal = fiverrEarned + upworkEarned + directEarned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Platform Split', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPlatformCard(
                'Fiverr', 
                fiverrEarned, 
                fiverrOrders.length, 
                const Color(0xFF1DBF73), 
                grandTotal,
                iconText: 'F',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlatformCard(
                'Upwork', 
                upworkEarned, 
                upworkOrders.length, 
                const Color(0xFF6FDA44), 
                grandTotal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPlatformCard(
          'Direct Clients', 
          directEarned, 
          directOrders.length, 
          const Color(0xFF8B5CF6), 
          grandTotal, 
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildPlatformCard(String label, double earned, int orders, Color color, double grandTotal, {bool isFullWidth = false, String? iconText}) {
    final percent = grandTotal > 0 ? earned / grandTotal : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: color, width: 3),
          left: const BorderSide(color: Color(0xFF1E2D45)),
          right: const BorderSide(color: Color(0xFF1E2D45)),
          bottom: const BorderSide(color: Color(0xFF1E2D45)),
        ),
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
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Center(child: Text(iconText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('${(percent * 100).round()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('\$${earned.toInt()}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('$orders orders', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF1E2D45), borderRadius: BorderRadius.circular(3)),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Orders by Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...OrderStatus.values.map((status) {
          final count = widget.orders.where((o) => o.status == status).length;
          final amount = widget.orders.where((o) => o.status == status).fold(0.0, (sum, o) => sum + o.price);
          final percent = widget.orders.isNotEmpty ? count / widget.orders.length : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: status.bgColor, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(status.label, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('$count orders', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                    const SizedBox(width: 12),
                    Text('\$${amount.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: percent, backgroundColor: const Color(0xFF1E2D45), valueColor: AlwaysStoppedAnimation(status.bgColor), minHeight: 6),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthlyGoal() {
    final currentEarnings = _calculateTotalEarned();
    final percent = (currentEarnings / _monthlyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF1E2D45))),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Goal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.flag_outlined, color: Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: GoalProgressPainter(percent: percent),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${currentEarnings.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('/ \$${_monthlyGoal.toInt()}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('${(percent * 100).toInt()}% achieved', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: const Color(0xFF1E2D45),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF3B82F6).withOpacity(0.1),
            ),
            child: Slider(
              value: _monthlyGoal,
              min: 500,
              max: 10000,
              divisions: 19,
              onChanged: (value) {
                setState(() => _monthlyGoal = value);
                _saveGoal(value);
              },
            ),
          ),
          const Text('Slide to set your monthly goal', style: TextStyle(color: Color(0xFF4B5563), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final highestOrder = widget.orders.fold(0.0, (max, o) => o.price > max ? o.price : max);
    final totalClients = widget.orders.map((o) => o.clientName).toSet().length;
    final ordersThisMonth = widget.orders.where((o) => o.createdAt.month == DateTime.now().month).length;
    final completionRate = widget.orders.isNotEmpty 
        ? (widget.orders.where((o) => o.status == OrderStatus.completed).length / widget.orders.length * 100).toInt() 
        : 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickStatPill('Highest Order', '\$${highestOrder.toInt()}', const Color(0xFFF59E0B)),
          _buildQuickStatPill('Total Clients', totalClients.toString(), const Color(0xFF3B82F6)),
          _buildQuickStatPill('Orders Month', ordersThisMonth.toString(), const Color(0xFF10B981)),
          _buildQuickStatPill('Completion', '$completionRate%', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildQuickStatPill(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTopOrders() {
    final topOrders = List<Order>.from(widget.orders)..sort((a, b) => b.price.compareTo(a.price));
    final displayOrders = topOrders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Orders', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...displayOrders.asMap().entries.map((entry) {
          final index = entry.key;
          final order = entry.value;
          final medals = [Icons.emoji_events, Icons.emoji_events, Icons.emoji_events];
          final medalColors = [const Color(0xFFF59E0B), const Color(0xFF94A3B8), const Color(0xFFB45309)];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D45))),
            child: Row(
              children: [
                Icon(medals[index], color: medalColors[index], size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(order.clientName, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                ),
                Text('\$${order.price.toInt()}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final completedOrders = widget.orders.where((o) => o.status == OrderStatus.completed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayTransactions = completedOrders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...displayTransactions.map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: order.platform.bgColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.payment, color: order.platform.bgColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(order.clientName, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('+\$${order.price.toInt()}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('MMM d').format(order.createdAt), style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text('View all', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class GoalProgressPainter extends CustomPainter {
  final double percent;
  GoalProgressPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1E2D45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -1.5708, // -90 degrees
      6.28319 * percent,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
