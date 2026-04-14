import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/order.dart';
import '../../core/models/invoice.dart';
import '../../core/services/invoice_service.dart';
import '../proposals/proposal_screen.dart';
import '../portal/client_portal_screen.dart';
import '../clients/clients_screen.dart';
import '../earnings/earnings_screen.dart';
import '../settings/settings_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  late List<Order> _orders = [];
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'In Progress', 'Revision', 'Delivered', 'Completed'];
  late AnimationController _urgentPulseController;
  int _bottomNavIndex = 0;

  // Controllers for the add order dialog
  final _titleCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Platform _selectedPlatform = Platform.fiverr;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    _urgentPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _urgentPulseController.repeat(reverse: true);
    _initOrders();
  }

  Future<void> _initOrders() async {
    final saved = await _loadOrders();
    if (saved.isEmpty) {
      final dummy = _getDummyOrders();
      setState(() => _orders = dummy);
      await _saveOrders();
    } else {
      setState(() => _orders = saved);
    }
  }

  List<Order> _getDummyOrders() {
    return [
      Order(
        id: 'seed_1',
        title: 'Mobile App UI Design',
        clientName: 'John Doe',
        platform: Platform.fiverr,
        price: 250.0,
        deadline: DateTime.now().add(const Duration(hours: 12)),
        status: OrderStatus.newOrder,
        notes: 'Design a clean and modern UI for a food delivery app.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Order(
        id: 'seed_2',
        title: 'Website Development',
        clientName: 'Jane Smith',
        platform: Platform.upwork,
        price: 1500.0,
        deadline: DateTime.now().add(const Duration(days: 5)),
        status: OrderStatus.inProgress,
        notes: 'Build a responsive website for a local bakery.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Order(
        id: 'seed_3',
        title: 'Logo Animation',
        clientName: 'Alex Johnson',
        platform: Platform.fiverr,
        price: 100.0,
        deadline: DateTime.now().add(const Duration(hours: 48)),
        status: OrderStatus.revision,
        notes: 'Animate the provided logo for a YouTube intro.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Order(
        id: 'seed_4',
        title: 'SEO Audit',
        clientName: 'Sarah Miller',
        platform: Platform.direct,
        price: 450.0,
        deadline: DateTime.now().add(const Duration(days: 2)),
        status: OrderStatus.delivered,
        notes: 'Perform a full SEO audit for a blog.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Order(
        id: 'seed_5',
        title: 'Social Media Graphics',
        clientName: 'Chris Brown',
        platform: Platform.upwork,
        price: 300.0,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        status: OrderStatus.completed,
        notes: 'Create 10 Instagram post templates.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('orderflow_orders', jsonStr);
  }

  Future<List<Order>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('orderflow_orders');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _urgentPulseController.dispose();
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<Order> get _filteredOrders {
    final filtered = _selectedFilter == 'All' 
        ? _orders 
        : _orders.where((order) => order.status.label == _selectedFilter).toList();
    // Sort by createdAt descending
    final sorted = List<Order>.from(filtered);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  void _deleteOrder(Order order) async {
    setState(() => _orders.removeWhere((o) => o.id == order.id));
    await _saveOrders();
  }

  void _completeOrder(Order order) async {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      setState(() {
        _orders[index].status = OrderStatus.completed;
      });
      await _saveOrders();
    }
  }

  Widget _getBody() {
    switch (_bottomNavIndex) {
      case 0:
        return CustomScrollView(
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(child: _buildStatsGrid()),
            SliverToBoxAdapter(child: _buildFilters()),
            _buildOrderList(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        );
      case 1:
        return const ProposalScreen();
      case 2:
        return ClientsScreen(orders: _orders);
      case 3:
        return EarningsScreen(orders: _orders);
      case 4:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMeshGradient(),
          _getBody(),
        ],
      ),
      floatingActionButton: _bottomNavIndex == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMeshGradient() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF030712),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withAlpha(40),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(100, 100), end: const Offset(100, 100)).move(
                    begin: const Offset(-50, -50),
                    end: const Offset(50, 50),
                    duration: 10.seconds,
                    curve: Curves.easeInOut,
                  ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withAlpha(30),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(120, 120), end: const Offset(120, 120)).move(
                    begin: const Offset(50, 50),
                    end: const Offset(-50, -50),
                    duration: 12.seconds,
                    curve: Curves.easeInOut,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddOrderDialog(),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add, size: 24),
        label: Text('New Order', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E2D45), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        items: [
          _buildNavItem(Icons.assignment_outlined, Icons.assignment, 'Orders', 0),
          _buildNavItem(Icons.description_outlined, Icons.description, 'Proposals', 1),
          _buildNavItem(Icons.people_outline, Icons.people, 'Clients', 2),
          _buildNavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Earnings', 3),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _bottomNavIndex == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(isSelected ? activeIcon : icon, size: 24),
      ),
      label: label,
    );
  }

  Widget _buildSliverHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final activeOrdersCount = _orders.where((o) => o.status != OrderStatus.completed).length;
    final totalEarnings = _orders
        .where((o) => o.status == OrderStatus.completed && o.deadline.month == now.month)
        .fold(0.0, (sum, o) => sum + o.price);
    final dueTodayCount = _orders.where((o) => o.deadline.day == now.day && o.deadline.month == now.month).length;

    return SliverAppBar(
      expandedHeight: 240,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: const Color(0xFF030712).withAlpha(100),
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
                            const SizedBox(height: 4),
                            Text(dateStr, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400))
                                .animate()
                                .fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderIcon(Icons.notifications_none_outlined),
                          const SizedBox(width: 12),
                          _buildProfileAvatar(),
                        ],
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMiniStat('Earned \$${totalEarnings.toInt()}', const Color(0xFF10B981)),
                      _buildMiniStat('$activeOrdersCount Active', const Color(0xFF3B82F6)),
                      _buildMiniStat('$dueTodayCount Due today', const Color(0xFFEF4444)),
                    ],
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
      ),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFF1E293B),
        child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildMiniStat(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFF9FAFB))),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final activeOrders = _orders.where((o) => o.status != OrderStatus.completed).length;
    final totalEarnings = _orders
        .where((o) => o.status == OrderStatus.completed && o.deadline.month == DateTime.now().month)
        .fold(0.0, (sum, o) => sum + o.price);
    final dueToday = _orders.where((o) => o.deadline.day == DateTime.now().day).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildStatCard('Active Orders', activeOrders.toString(), const Color(0xFF3B82F6), Icons.assignment_outlined),
            const SizedBox(width: 16),
            _buildStatCard('This Month', '\$${totalEarnings.toInt()}', const Color(0xFF10B981), Icons.account_balance_wallet_outlined),
            const SizedBox(width: 16),
            _buildStatCard('Due Today', dueToday.toString(), const Color(0xFFEF4444), Icons.timer_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(30),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 16),
                Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
                const SizedBox(height: 6),
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1A2235),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E2D45)),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF3B82F6).withAlpha(80), blurRadius: 10)] : [],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList() {
    final orders = _filteredOrders;
    if (orders.isEmpty) return SliverFillRemaining(child: _buildEmptyState());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = orders[index];
            return _buildOrderCard(order)
                .animate(delay: (index * 100).ms)
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
          },
          childCount: orders.length,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final now = DateTime.now();
    final difference = order.deadline.difference(now);
    final isUrgent = difference.inHours < 24 && difference.inHours > 0;
    final deadlineStr = difference.isNegative ? 'Overdue' : (difference.inHours < 24 ? '${difference.inHours}h left' : '${difference.inDays}d left');
    final ValueNotifier<bool> isHovered = ValueNotifier(false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovered,
        builder: (context, hovered, child) {
          return FocusableActionDetector(
            onShowHoverHighlight: (hover) => isHovered.value = hover,
            child: AnimatedScale(
              scale: hovered ? 1.02 : 1.0,
              duration: 200.ms,
              curve: Curves.easeOutBack,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
                      ),
                      child: Slidable(
                        key: ValueKey(order.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _completeOrder(order),
                              backgroundColor: const Color(0xFF10B981).withAlpha(200),
                              foregroundColor: Colors.white,
                              icon: Icons.check,
                            ),
                          ],
                        ),
                        startActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _deleteOrder(order),
                              backgroundColor: const Color(0xFFEF4444).withAlpha(200),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showOrderDetails(order);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                            children: [
                              _buildStatusIndicator(order.status.textColor, isUrgent),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order.title,
                                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _buildProgressCircle(order.progress),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: order.platform.bgColor.withAlpha(40),
                                            child: Text(
                                              order.clientName.isNotEmpty ? order.clientName[0] : '?',
                                              style: TextStyle(color: order.platform.textColor, fontSize: 10, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _buildPlatformBadge(order.platform),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              order.clientName,
                                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('\$${order.price.toInt()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6))),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          _buildDeadlineChip(deadlineStr, isUrgent ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
                                          const SizedBox(width: 10),
                                          _buildStatusChip(order.status),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              _sharePortalLink(order);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withAlpha(20),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF6366F1).withAlpha(40)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.share_outlined, size: 12, color: Color(0xFF6366F1)),
                                                  const SizedBox(width: 6),
                                                  Text('PORTAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF6366F1), letterSpacing: 0.5)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text('${(order.progress * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, bool isUrgent) {
    if (isUrgent) {
      return AnimatedBuilder(
        animation: _urgentPulseController,
        builder: (context, child) {
          return Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withAlpha((_urgentPulseController.value * 150).toInt()),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      );
    }
    return Container(
      width: 4, 
      height: 100, 
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(Platform p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: p.bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(p.label, style: TextStyle(color: p.textColor, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDeadlineChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF0A0F1E), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(50))),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(s.label, style: TextStyle(color: s.textColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildProgressCircle(double progress) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF3B82F6).withAlpha(30),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          Center(
            child: Icon(
              progress == 1.0 ? Icons.check : Icons.trending_up,
              size: 14,
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: const Color(0xFF1E2D45)),
          const SizedBox(height: 24),
          const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Your new orders will appear here', style: TextStyle(color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    double uploadProgress = 0;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Workflow Engine',
                              style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          _buildProgressCircle(order.progress),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.title,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 32),
                      Text('MANUAL MILESTONES',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4B5563),
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      ...order.milestones.asMap().entries.map((entry) {
                        final milestone = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: milestone.isCompleted
                                ? const Color(0xFF3B82F6).withAlpha(10)
                                : Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: milestone.isCompleted
                                    ? const Color(0xFF3B82F6).withAlpha(30)
                                    : Colors.white.withAlpha(10)),
                          ),
                          child: CheckboxListTile(
                            value: milestone.isCompleted,
                            onChanged: (val) async {
                              setModalState(() => milestone.isCompleted = val!);
                              setState(() {}); // Update main screen
                              await _saveOrders();
                            },
                            title: Text(milestone.title,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: milestone.isCompleted
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                            activeColor: const Color(0xFF3B82F6),
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      Text('FINAL DELIVERY',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4B5563),
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: order.deliveryUrl != null
                              ? const Color(0xFF10B981).withAlpha(10)
                              : const Color(0xFF3B82F6).withAlpha(5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: order.deliveryUrl != null
                                  ? const Color(0xFF10B981).withAlpha(20)
                                  : const Color(0xFF3B82F6).withAlpha(10)),
                        ),
                        child: Column(
                          children: [
                            if (isUploading) ...[
                              CircularProgressIndicator(
                                value: uploadProgress,
                                backgroundColor: Colors.white.withAlpha(10),
                                color: const Color(0xFF3B82F6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${(uploadProgress * 100).toInt()}% Uploading...',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ] else ...[
                              Icon(
                                order.deliveryUrl != null
                                    ? Icons.verified_user_outlined
                                    : Icons.cloud_upload_outlined,
                                color: order.deliveryUrl != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6),
                                size: 32,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                order.deliveryUrl != null
                                    ? 'File Securely Stored'
                                    : 'No delivery file uploaded',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.deliveryUrl != null
                                    ? 'Client Portal is now locked for payment'
                                    : 'Upload the final file for client to unlock',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () => _handleFileUpload(order, (p) {
                                          setModalState(() {
                                            uploadProgress = p;
                                            isUploading = p < 1.0;
                                          });
                                        }),
                                icon: Icon(order.deliveryUrl != null
                                    ? Icons.check_circle_outline
                                    : Icons.upload_file),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: order.deliveryUrl != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                label: Text(
                                    order.deliveryUrl != null
                                        ? 'File Securely Stored'
                                        : 'Upload Final File',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _sendUpdateToClient(order),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send Update to Client',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleGenerateInvoice(order),
                          icon:
                              const Icon(Icons.description_outlined, size: 18),
                          label: const Text('Generate & Preview Invoice',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close Engine',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendUpdateToClient(Order order) {
    final completed = order.milestones
        .where((m) => m.isCompleted)
        .map((m) => m.title)
        .join(', ');
    final progressStr = '${(order.progress * 100).toInt()}%';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate =
        DateTime(order.deadline.year, order.deadline.month, order.deadline.day);

    String deadlineStatus;
    if (deadlineDate.isAtSameMomentAs(today)) {
      deadlineStatus = 'Due Today';
    } else if (deadlineDate.isBefore(today)) {
      deadlineStatus = 'Delayed';
    } else {
      deadlineStatus = 'On time';
    }

    final message = "Hello! Here is a status update for ${order.title}.\n\n"
        "Progress: $progressStr\n"
        "Tasks completed: ${completed.isEmpty ? 'None yet' : completed}\n"
        "Estimated delivery: $deadlineStatus.";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withAlpha(180),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Choose Platform',
                  style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MESSAGE PREVIEW',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Text(message,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.white, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp Web',
                      color: const Color(0xFF10B981),
                      onTap: () async {
                        final url = Uri.parse(
                            "https://wa.me/?text=${Uri.encodeComponent(message)}");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShareButton(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      color: const Color(0xFF3B82F6),
                      onTap: () async {
                        final url = Uri.parse(
                            "mailto:?subject=Status Update: ${order.title}&body=${Uri.encodeComponent(message)}");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildShareButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy to Clipboard',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(20),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withAlpha(50)),
        ),
        elevation: 0,
      ),
    );
  }

  Future<void> _handleGenerateInvoice(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString('currency') ?? 'USD \$';
    final agencyName = prefs.getString('agency_name') ?? 'ORDERFLOW';
    final logoPath = prefs.getString('agency_logo');
    final paypal = prefs.getString('payment_paypal') ?? '';
    final stripe = prefs.getString('payment_stripe') ?? '';
    final bank = prefs.getString('payment_bank') ?? '';

    // Generate PDF
    await InvoiceService.generateInvoice(
      order: order,
      currency: currency,
      agencyName: agencyName,
      logoPath: logoPath,
      paypalLink: paypal,
      stripeLink: stripe,
      bankDetails: bank,
    );

    // Save to Invoice Tracker Hive Box
    final invoiceBox = Hive.box<Invoice>('invoices');
    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: order.id,
      invoiceNumber:
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      amount: order.price,
      status: InvoiceStatus.sent,
    );

    await invoiceBox.put(order.id, invoice);

    // Update order status if not already invoiced
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      setState(() {
        // Here we could add a flag to Order model like isInvoiced
        // For now, let's keep it tracked in the invoices box
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated and tracked!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _sharePortalLink(Order order) {
    final url = "https://orderflow.io/portal/${order.shareToken}";
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Portal link copied to clipboard!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  Future<void> _handleFileUpload(
      Order order, Function(double) onProgress) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName =
          '${order.id}_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

      try {
        // Start simulated progress since Supabase Storage doesn't provide upload progress in the simple upload method
        double progress = 0;
        final timer =
            Stream.periodic(const Duration(milliseconds: 100), (i) => i)
                .take(20)
                .listen((event) {
          progress += 0.05;
          if (progress <= 0.9) onProgress(progress);
        });

        // Upload to Supabase Storage
        await Supabase.instance.client.storage
            .from('deliveries')
            .upload(fileName, file);

        timer.cancel();
        onProgress(1.0);

        final String publicUrl = Supabase.instance.client.storage
            .from('deliveries')
            .getPublicUrl(fileName);

        // Update order in Hive
        final updatedOrder = order.copyWith(
          deliveryUrl: publicUrl,
          isDeliveryLocked: true,
        );

        final box = Hive.box<Order>('orders');
        await box.put(order.id, updatedOrder);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery file uploaded and secured!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          // Don't pop automatically to show success state
        }
      } catch (e) {
        onProgress(0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddOrderDialog() {
    _titleCtrl.clear();
    _clientCtrl.clear();
    _priceCtrl.clear();
    _notesCtrl.clear();
    _selectedPlatform = Platform.fiverr;
    _selectedDeadline = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
            border: Border.all(color: const Color(0xFF1E2D45))
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Order', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 24),
                _buildTextField(_titleCtrl, 'Order Title'),
                const SizedBox(height: 16),
                _buildTextField(_clientCtrl, 'Client Name'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Platform>(
                        initialValue: _selectedPlatform,
                        dropdownColor: const Color(0xFF111827),
                        decoration: _inputDecoration('Platform'),
                        items: Platform.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) => setModalState(() => _selectedPlatform = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_priceCtrl, 'Price (\$)', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_notesCtrl, 'Notes', maxLines: 3),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Deadline', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDeadline), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.calendar_today_outlined, color: Color(0xFF3B82F6), size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1E2D45))),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, 
                      initialDate: _selectedDeadline, 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    );
                    if (picked != null) setModalState(() => _selectedDeadline = picked);
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_titleCtrl.text.trim().isEmpty || _clientCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title and client name required!')));
                        return;
                      }
                      final newOrder = Order(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleCtrl.text.trim(),
                        clientName: _clientCtrl.text.trim(),
                        platform: _selectedPlatform,
                        price: double.tryParse(_priceCtrl.text) ?? 0.0,
                        deadline: _selectedDeadline,
                        status: OrderStatus.newOrder,
                        notes: _notesCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      
                      setState(() => _orders.add(newOrder));
                      await _saveOrders();
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Create Order', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFF030712),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E293B))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
