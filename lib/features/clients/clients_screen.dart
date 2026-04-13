import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';

class Client {
  final String name;
  final Platform platform;
  final List<Order> orders;
  String notes;

  Client({
    required this.name,
    required this.platform,
    required this.orders,
    this.notes = '',
  });

  int get totalOrders => orders.length;
  double get totalEarned => orders.fold(0.0, (sum, o) => sum + o.price);
  double get avgOrderValue => totalOrders > 0 ? totalEarned / totalOrders : 0;
  DateTime get lastActive => orders.fold(
      DateTime(2000),
      (latest, o) => o.createdAt.isAfter(latest) ? o.createdAt : latest);

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }
}

class ClientsScreen extends StatefulWidget {
  final List<Order> orders;
  const ClientsScreen({super.key, required this.orders});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with SingleTickerProviderStateMixin {
  late List<Client> _clients;
  late List<Client> _filteredClients;
  late Map<String, List<Order>> _clientOrdersMap;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recent';
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _processClients();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ClientsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders) {
      _processClients();
    }
  }

  void _processClients() {
    _clientOrdersMap = {};
    for (var order in widget.orders) {
      _clientOrdersMap.putIfAbsent(order.clientName, () => []).add(order);
    }

    _clients = _clientOrdersMap.entries.map((entry) {
      return Client(
        name: entry.key,
        platform: entry.value.first.platform,
        orders: entry.value,
      );
    }).toList();

    _sortClients();
    _applySearch();
  }

  void _sortClients() {
    setState(() {
      switch (_sortBy) {
        case 'Most Earned':
          _clients.sort((a, b) => b.totalEarned.compareTo(a.totalEarned));
          break;
        case 'Most Orders':
          _clients.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
          break;
        case 'Recent':
          _clients.sort((a, b) => b.lastActive.compareTo(a.lastActive));
          break;
        case 'Name A-Z':
          _clients.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClients = List.from(_clients);
      } else {
        _filteredClients = _clients
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: _buildAppBar(),
      body: _filteredClients.isEmpty ? _buildEmptyState() : _buildClientsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final double totalEarned = _clients.fold(0, (sum, c) => sum + c.totalEarned);
    final double avgPerClient = _clients.isNotEmpty ? totalEarned / _clients.length : 0;
    
    // Find top platform
    final Map<Platform, int> platformCounts = {};
    for (var client in _clients) {
      platformCounts[client.platform] = (platformCounts[client.platform] ?? 0) + 1;
    }
    final topPlatform = platformCounts.entries.isEmpty 
        ? null 
        : platformCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return PreferredSize(
      preferredSize: Size.fromHeight(_isSearching ? 60 : 120),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching ? _buildSearchHeader() : _buildDefaultHeader(totalEarned, avgPerClient, topPlatform),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return AppBar(
      key: const ValueKey('searchHeader'),
      backgroundColor: const Color(0xFF0A0F1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _applySearch();
          });
        },
      ),
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search clients...',
            hintStyle: const TextStyle(color: Color(0xFF4B5563)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            suffixText: '${_filteredClients.length} results',
            suffixStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
          onChanged: (_) => _applySearch(),
        ),
      ),
    );
  }

  Widget _buildDefaultHeader(double totalEarned, double avgPerClient, Platform? topPlatform) {
    return AppBar(
      key: const ValueKey('defaultHeader'),
      backgroundColor: const Color(0xFF0A0F1E),
      elevation: 0,
      toolbarHeight: 120,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clients',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          Text(
            '${_clients.length} total clients',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatPill('Total earned: \$${totalEarned.toInt()}', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildStatPill('Avg: \$${avgPerClient.toInt()}', const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              if (topPlatform != null)
                _buildStatPill('Top: ${topPlatform.label}', topPlatform.bgColor),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => setState(() => _isSearching = true),
        ),
        _buildSortPill(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSortPill() {
    return GestureDetector(
      onTap: _showSortBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more, color: Colors.white.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Recent'),
            _buildSortOption('Most Earned'),
            _buildSortOption('Most Orders'),
            _buildSortOption('Name A-Z'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value) {
    final bool isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortClients();
          _applySearch();
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF4B5563),
                  width: 2,
                ),
              ),
              child: isSelected 
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Color(0xFF1E2D45)),
          const SizedBox(height: 24),
          Text(
            'No clients yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clients appear automatically when you add orders',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    Color accentColor;
    if (client.totalEarned < 100) {
      accentColor = const Color(0xFF4B5563); // grey
    } else if (client.totalEarned < 500) {
      accentColor = const Color(0xFF3B82F6); // blue
    } else {
      accentColor = const Color(0xFFF59E0B); // gold
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Right accent
          Positioned(
            right: 0,
            top: 15,
            bottom: 15,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showClientDetail(client),
              hoverColor: Colors.white.withOpacity(0.05),
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _buildAvatar(client),
                    const SizedBox(width: 16),
                    Expanded(child: _buildClientInfo(client)),
                    _buildClientStats(client),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFF4B5563).withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Client client) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: client.platform.bgColor.withOpacity(0.5), width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: client.platform.bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            client.initials,
            style: TextStyle(
              color: client.platform.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          client.name,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: client.platform.bgColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.platform.label,
                style: TextStyle(
                  color: client.platform.bgColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${client.totalOrders} orders',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Active ${_getTimeAgo(client.lastActive)}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _buildClientStats(Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '\$${client.totalEarned.toInt()}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} mins ago';
    }
    return 'just now';
  }

  void _showClientDetail(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _ClientDetailSheet(
          client: client, 
          scrollController: controller,
          clientOrdersMap: _clientOrdersMap,
        ),
      ),
    );
  }
}

class _ClientDetailSheet extends StatefulWidget {
  final Client client;
  final ScrollController scrollController;
  final Map<String, List<Order>> clientOrdersMap;
  const _ClientDetailSheet({
    required this.client, 
    required this.scrollController,
    required this.clientOrdersMap,
  });

  @override
  State<_ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<_ClientDetailSheet> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.client.notes);
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Order History'),
                        const SizedBox(height: 16),
                        _buildOrderHistory(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Notes'),
                        const SizedBox(height: 16),
                        _buildNotesSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF4B5563).withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2235), Color(0xFF111827)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.client.platform.bgColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: widget.client.platform.bgColor, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: widget.client.platform.bgColor,
              child: Text(
                widget.client.initials,
                style: TextStyle(
                  color: widget.client.platform.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.client.platform.bgColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.client.platform.label,
                    style: TextStyle(
                      color: widget.client.platform.bgColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final orders = widget.clientOrdersMap[widget.client.name] ?? [];
    final double totalEarned = orders.isEmpty ? 0 : orders.map((o) => o.price).reduce((a, b) => a + b);
    final double avgValue = orders.isEmpty ? 0 : totalEarned / orders.length;

    return Row(
      children: [
        _buildStatCard(
          'Total Orders', 
          orders.length.toString(),
          const Color(0xFF3B82F6),
          Icons.receipt_long,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Total Earned', 
          '\$${totalEarned.toInt()}',
          const Color(0xFF10B981),
          Icons.attach_money,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Avg Value', 
          '\$${avgValue.toInt()}',
          const Color(0xFFF59E0B),
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D45),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildOrderHistory() {
    final orders = widget.clientOrdersMap[widget.client.name] ?? [];
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No orders yet',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D45),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: order.status.bgColor, width: 4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.status.bgColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.label,
                        style: TextStyle(
                          color: order.status.textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.price.toInt()}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(order.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            TextField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add notes about this client...',
                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                filled: true,
                fillColor: const Color(0xFF1A2235),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Text(
                '${_notesController.text.length}/500',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              widget.client.notes = _notesController.text;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes saved!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Notes', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
