import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/order.dart';
import '../../core/models/client_profile.dart';

class Client {
  final String name;
  final List<Order> orders;
  String notes;

  Client({
    required this.name,
    required this.orders,
    this.notes = '',
  });

  int get totalOrders => orders.length;
  double get totalEarned => orders.fold(0.0, (sum, o) => sum + o.price);
  double get avgOrderValue => totalOrders > 0 ? totalEarned / totalOrders : 0;
  DateTime get lastActive => orders.fold(
      DateTime(2000),
      (latest, o) => o.createdAt.isAfter(latest) ? o.createdAt : latest);

  bool get isVIP => totalEarned > 500;

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

  @override
  void initState() {
    super.initState();
    _processClients();
  }

  @override
  void dispose() {
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

    final box = Hive.box<ClientProfile>('client_profiles');

    _clients = _clientOrdersMap.entries.map((entry) {
      final profile = box.get(entry.key);
      return Client(
        name: entry.key,
        orders: entry.value,
        notes: profile?.notes ?? '',
      );
    }).toList();

    _sortClients();
    _applySearch();
  }

  Future<void> _updateClientNotes(String clientName, String notes) async {
    final box = Hive.box<ClientProfile>('client_profiles');
    final profile = box.get(clientName) ?? ClientProfile(name: clientName);
    profile.notes = notes;
    await box.put(clientName, profile);
    
    // Update local state
    final index = _clients.indexWhere((c) => c.name == clientName);
    if (index != -1) {
      setState(() {
        _clients[index].notes = notes;
      });
    }
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
      backgroundColor: const Color(0xFF030712),
      appBar: _buildAppBar(),
      body: _filteredClients.isEmpty ? _buildEmptyState() : _buildClientsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final double totalEarned = _clients.fold(0, (sum, c) => sum + c.totalEarned);
    final double avgPerClient = _clients.isNotEmpty ? totalEarned / _clients.length : 0;
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 140,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('B2B CRM', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.white, letterSpacing: -1)),
                  Text('${_clients.length} Active Partners', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                ],
              ),
              _buildSortPill(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatPill('Lifetime: \$${totalEarned.toInt()}', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildStatPill('Avg/Client: \$${avgPerClient.toInt()}', const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSortPill() {
    return GestureDetector(
      onTap: _showSortBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_sortBy, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.tune, color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort Partners', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 20),
            ...['Recent', 'Most Earned', 'Most Orders', 'Name A-Z'].map((value) => ListTile(
              title: Text(value, style: TextStyle(color: _sortBy == value ? const Color(0xFF3B82F6) : Colors.white)),
              onTap: () {
                setState(() { _sortBy = value; _sortClients(); });
                Navigator.pop(context);
              },
            )),
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
          Text('No clients yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
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
        return _buildClientCard(client)
            .animate()
            .scale(
              duration: 400.ms,
              delay: (index * 100).ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () => _showClientVault(client),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withAlpha(150),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: client.isVIP
                ? const Color(0xFFFFD700).withAlpha(100)
                : Colors.white.withAlpha(10),
            width: client.isVIP ? 2 : 1,
          ),
          gradient: client.isVIP
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withAlpha(30),
                    const Color(0xFFDAA520).withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: client.isVIP
                  ? const Color(0xFFFFD700).withAlpha(20)
                  : Colors.black.withAlpha(50),
              blurRadius: client.isVIP ? 30 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: client.isVIP
                          ? const Color(0xFFFFD700).withAlpha(150)
                          : Colors.white.withAlpha(40),
                      width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: client.isVIP
                      ? const Color(0xFFFFD700).withAlpha(40)
                      : Colors.white.withAlpha(10),
                  child: Text(client.initials,
                      style: GoogleFonts.inter(
                          color: client.isVIP ? const Color(0xFFFFD700) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(client.name,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        if (client.isVIP) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFFD700).withAlpha(50)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withAlpha(40),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text('VIP',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${client.totalOrders} Projects',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Color(0xFF475569))),
                        const SizedBox(width: 8),
                        Text('Avg: \$${client.avgOrderValue.toInt()}',
                            style: GoogleFonts.inter(
                                color: client.isVIP
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${client.totalEarned.toInt()}',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                  Text('LIFETIME',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF4B5563),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientVault(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF030712).withAlpha(200),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('THE VAULT',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 4)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(client.name,
                                style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                            if (client.isVIP) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.stars_rounded,
                                  color: Color(0xFFFFD700), size: 32),
                            ],
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfitabilityMeter(client),
                        const SizedBox(height: 40),
                        Text('PERSONAL PREFERENCES',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4B5563),
                                letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        _buildNotesField(client),
                        const SizedBox(height: 40),
                        Text('ORDER TIMELINE',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4B5563),
                                letterSpacing: 1.5)),
                        const SizedBox(height: 24),
                        _buildTimeline(client),
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

  Widget _buildProfitabilityMeter(Client client) {
    // Assuming 20% cost of operations for demo
    final netProfit = client.totalEarned * 0.8;
    final percentage = (netProfit / client.totalEarned) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NET PROFITABILITY',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('\$${netProfit.toInt()}',
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${percentage.toInt()}% MARGIN',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.8,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(Client client) {
    return TextField(
      maxLines: 4,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      controller: TextEditingController(text: client.notes),
      onSubmitted: (val) => _updateClientNotes(client.name, val),
      decoration: InputDecoration(
        hintText: 'Add preference notes...',
        hintStyle:
            GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 15),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withAlpha(10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: const Color(0xFFDC2626).withAlpha(50)),
        ),
      ),
    );
  }

  Widget _buildTimeline(Client client) {
    final sortedOrders = List<Order>.from(client.orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: sortedOrders.map((order) {
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: order.status.textColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: order.status.textColor.withAlpha(100),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white.withAlpha(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.title,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMMM d, yyyy').format(order.createdAt),
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                      Text('\$${order.price.toInt()}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
