import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../proposals/proposal_screen.dart';

enum OrderStatus {
  newOrder('New', Color(0xFF1D4ED8), Color(0xFF93C5FD)),
  inProgress('In Progress', Color(0xFF78350F), Color(0xFFFCD34D)),
  revision('Revision', Color(0xFF431407), Color(0xFFFB923C)),
  delivered('Delivered', Color(0xFF064E3B), Color(0xFF5EEAD4)),
  completed('Completed', Color(0xFF064E3B), Color(0xFF10B981));

  final String label;
  final Color bgColor;
  final Color textColor;
  const OrderStatus(this.label, this.bgColor, this.textColor);
}

enum Platform {
  fiverr('Fiverr', Color(0xFF1DBF73), Color(0xFF064E3B)),
  upwork('Upwork', Color(0xFF6FDA44), Color(0xFF064E3B)),
  direct('Direct', Color(0xFF8B5CF6), Colors.white);

  final String label;
  final Color bgColor;
  final Color textColor;
  const Platform(this.label, this.bgColor, this.textColor);
}

class Order {
  final String id;
  final String title;
  final String clientName;
  final Platform platform;
  final double price;
  final DateTime deadline;
  final OrderStatus status;
  final String notes;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.title,
    required this.clientName,
    required this.platform,
    required this.price,
    required this.deadline,
    required this.status,
    this.notes = '',
    required this.createdAt,
  });

  Order copyWith({
    String? title,
    String? clientName,
    Platform? platform,
    double? price,
    DateTime? deadline,
    OrderStatus? status,
    String? notes,
  }) {
    return Order(
      id: this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      platform: platform ?? this.platform,
      price: price ?? this.price,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  late List<Order> _orders;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'In Progress', 'Revision', 'Delivered', 'Completed'];
  late AnimationController _urgentPulseController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _orders = [
      Order(
        id: '1',
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
        id: '2',
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
        id: '3',
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
        id: '4',
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
        id: '5',
        title: 'Social Media Graphics',
        clientName: 'Chris Brown',
        platform: Platform.upwork,
        price: 300.0,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        status: OrderStatus.completed,
        notes: 'Create 10 Instagram post templates.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Order(
        id: '6',
        title: 'Content Writing',
        clientName: 'Emily Davis',
        platform: Platform.fiverr,
        price: 150.0,
        deadline: DateTime.now().add(const Duration(hours: 18)),
        status: OrderStatus.inProgress,
        notes: 'Write 3 articles about healthy lifestyle.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    _urgentPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urgentPulseController.dispose();
    super.dispose();
  }

  List<Order> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((order) => order.status.label == _selectedFilter).toList();
  }

  void _deleteOrder(String id) {
    setState(() {
      _orders.removeWhere((order) => order.id == id);
    });
  }

  void _completeOrder(String id) {
    setState(() {
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: OrderStatus.completed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bottomNavIndex == 1 ? const ProposalScreen() : CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildStatsGrid()),
          SliverToBoxAdapter(child: _buildFilters()),
          _buildOrderList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
      floatingActionButton: _bottomNavIndex == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
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
      expandedHeight: 200,
      collapsedHeight: 80,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Grid dot pattern background
            Positioned.fill(
              child: CustomPaint(
                painter: GridDotPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF1A2235),
                                child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0A0F1E), width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMiniStat('Earned \$${totalEarnings.toInt()}', const Color(0xFF10B981)),
                      _buildMiniStat('$activeOrdersCount Active', const Color(0xFF3B82F6)),
                      _buildMiniStat('$dueTodayCount Due today', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500, height: 1.2)),
          ],
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
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 80)),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildOrderCard(order),
            );
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
    final deadlineStr = difference.inHours < 24 ? '${difference.inHours}h left' : '${difference.inDays}d left';
    final timeAgo = '2h ago'; // Dummy

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Slidable(
          key: ValueKey(order.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _completeOrder(order.id),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                icon: Icons.check,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showOrderDetails(order),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                _buildStatusIndicator(order.status.textColor, isUrgent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('\$${order.price.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: order.platform.bgColor.withAlpha(40),
                              child: Text(
                                order.clientName[0],
                                style: TextStyle(color: order.platform.textColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildPlatformBadge(order.platform),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.clientName,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Color(0xFF4B5563))),
                            const SizedBox(width: 6),
                            Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildDeadlineChip(deadlineStr, isUrgent ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 8),
                            _buildStatusChip(order.status),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Color(0xFF111827), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 24),
            _buildDetailItem('Title', order.title),
            _buildDetailItem('Client', order.clientName),
            _buildDetailItem('Platform', order.platform.label),
            _buildDetailItem('Price', '\$${order.price}'),
            _buildDetailItem('Notes', order.notes),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddOrderDialog() {
    final titleController = TextEditingController();
    final clientController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    Platform selectedPlatform = Platform.fiverr;
    OrderStatus selectedStatus = OrderStatus.newOrder;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

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
                _buildTextField(titleController, 'Order Title'),
                const SizedBox(height: 16),
                _buildTextField(clientController, 'Client Name'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Platform>(
                        value: selectedPlatform,
                        dropdownColor: const Color(0xFF111827),
                        decoration: _inputDecoration('Platform'),
                        items: Platform.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) => setModalState(() => selectedPlatform = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(priceController, 'Price (\$)', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<OrderStatus>(
                  value: selectedStatus,
                  dropdownColor: const Color(0xFF111827),
                  decoration: _inputDecoration('Status'),
                  items: OrderStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setModalState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                _buildTextField(notesController, 'Notes', maxLines: 3),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Deadline', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.calendar_today_outlined, color: Color(0xFF3B82F6), size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1E2D45))),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty && clientController.text.isNotEmpty) {
                        final newOrder = Order(
                          id: DateTime.now().toString(),
                          title: titleController.text,
                          clientName: clientController.text,
                          platform: selectedPlatform,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          deadline: selectedDate,
                          status: selectedStatus,
                          notes: notesController.text,
                          createdAt: DateTime.now(),
                        );
                        setState(() => _orders.insert(0, newOrder));
                        Navigator.pop(context);
                      }
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
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFF0A0F1E),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2D45))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class GridDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D45).withAlpha(100)
      ..strokeWidth = 1;

    const double spacing = 20;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
