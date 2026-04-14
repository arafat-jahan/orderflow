import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/invoice_service.dart';

class ClientPortalScreen extends StatelessWidget {
  final String token;

  const ClientPortalScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Order>('orders').listenable(),
        builder: (context, Box<Order> box, _) {
          final order = box.values.cast<Order?>().firstWhere(
                (o) => o?.shareToken == token,
                orElse: () => null,
              );

          if (order == null) {
            return _buildErrorState(context);
          }

          return _buildPortalContent(context, order);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFF3B82F6), size: 64),
          const SizedBox(height: 24),
          Text('Portal Not Found',
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Text('The link may be expired or incorrect.',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        ],
      ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
    );
  }

  Widget _buildPortalContent(BuildContext context, Order order) {
    final progress = order.progress;
    final progressPercent = (progress * 100).toInt();

    return Stack(
      children: [
        // Background Glows
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withAlpha(30),
            ),
          ).animate().fadeIn(duration: 1000.ms),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withAlpha(20),
            ),
          ).animate().fadeIn(duration: 1200.ms),
        ),

        // Main Content
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(order),
                    const SizedBox(height: 48),
                    _buildProgressSection(progress, progressPercent),
                    const SizedBox(height: 48),
                    _buildMilestonesSection(order),
                    const SizedBox(height: 48),
                    _buildDeliveryVaultSection(context, order),
                    const SizedBox(height: 48),
                    _buildActionsSection(context, order),
                    const SizedBox(height: 60),
                    _buildFooter(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6).withAlpha(40)),
              ),
              child: Text('LIVE PROJECT PORTAL',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B82F6),
                      letterSpacing: 2)),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
        const SizedBox(height: 24),
        Text(order.title,
            style: GoogleFonts.inter(
                fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1))
            .animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: 0.1),
        const SizedBox(height: 12),
        Text('Managed by OrderFlow Agency',
            style: GoogleFonts.inter(
                fontSize: 16, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500))
            .animate()
            .fadeIn(duration: 800.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildProgressSection(double progress, int percent) {
    return Container(
      padding: const EdgeInsets.all(32),
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
              Text('PROJECT PROGRESS',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5)),
              Text('$percent%',
                  style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: 1500.ms,
                curve: Curves.easeOutQuart,
                height: 12,
                width: 300 * progress, // Simplified for layout
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withAlpha(100),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ).animate().shimmer(duration: 2000.ms, delay: 1000.ms),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMilestonesSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MILESTONES',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5)),
        const SizedBox(height: 24),
        ...order.milestones.asMap().entries.map((entry) {
          final idx = entry.key;
          final milestone = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: milestone.isCompleted ? const Color(0xFF10B981).withAlpha(10) : Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: milestone.isCompleted ? const Color(0xFF10B981).withAlpha(20) : Colors.white.withAlpha(5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: milestone.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                      border: Border.all(
                        color: milestone.isCompleted ? const Color(0xFF10B981) : const Color(0xFF475569),
                        width: 2,
                      ),
                    ),
                    child: milestone.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(milestone.title,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: milestone.isCompleted ? FontWeight.w700 : FontWeight.w500,
                          color: milestone.isCompleted ? Colors.white : const Color(0xFF94A3B8))),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (800 + idx * 100).ms).slideX(begin: 0.1);
        }),
      ],
    );
  }

  Widget _buildDeliveryVaultSection(BuildContext context, Order order) {
    if (order.deliveryUrl == null) return const SizedBox.shrink();

    final isLocked = order.isDeliveryLocked;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFFDC2626).withAlpha(10)
            : const Color(0xFF10B981).withAlpha(10),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFDC2626).withAlpha(20)
              : const Color(0xFF10B981).withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: isLocked ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                isLocked ? 'SECURED DELIVERY' : 'DELIVERY UNLOCKED',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isLocked ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                    letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (isLocked) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDC2626).withAlpha(10),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 2000.ms,
                    ),
                const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFDC2626),
                  size: 48,
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shake(
                      hz: 2,
                      offset: const Offset(2, 0),
                      duration: 1000.ms,
                    ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Final delivery file is ready!',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Complete the payment to unlock and download your files.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
            const SizedBox(height: 32),
            _buildActionButton(
              icon: Icons.payments_outlined,
              label: 'Pay & Unlock Delivery',
              color: const Color(0xFF3B82F6),
              onTap: () => _simulatePayment(context, order),
            ),
          ] else ...[
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withAlpha(10),
                  ),
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
              ],
            ),
            const SizedBox(height: 32),
            Text('Your files are ready!',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Payment verified. You can now download your final delivery.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
            const SizedBox(height: 32),
            _buildActionButton(
              icon: Icons.download_for_offline_outlined,
              label: 'Download Final Delivery',
              color: const Color(0xFF10B981),
              onTap: () async {
                final url = Uri.parse(order.deliveryUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Future<void> _simulatePayment(BuildContext context, Order order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF3B82F6)),
              const SizedBox(height: 24),
              Text('Securing Payment...',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      // Update Order in Hive
      final box = Hive.box<Order>('orders');
      final updatedOrder = order.copyWith(isDeliveryLocked: false);
      await box.put(order.id, updatedOrder);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! Delivery Unlocked.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Widget _buildActionsSection(BuildContext context, Order order) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.description_outlined,
          label: 'Download Latest Invoice',
          color: const Color(0xFF3B82F6),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            final currency = prefs.getString('currency') ?? 'USD \$';
            final agencyName = prefs.getString('agency_name') ?? 'ORDERFLOW';
            final logoPath = prefs.getString('agency_logo');
            final paypal = prefs.getString('payment_paypal') ?? '';
            final stripe = prefs.getString('payment_stripe') ?? '';
            final bank = prefs.getString('payment_bank') ?? '';

            await InvoiceService.generateInvoice(
              order: order,
              currency: currency,
              agencyName: agencyName,
              logoPath: logoPath,
              paypalLink: paypal,
              stripeLink: stripe,
              bankDetails: bank,
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat with Specialist',
          color: const Color(0xFF10B981),
          onTap: () async {
            final url = Uri.parse("https://wa.me/"); // Simplified for demo
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    ).animate().fadeIn(duration: 800.ms, delay: 1200.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFF1E293B)),
        const SizedBox(height: 24),
        Text('Secure Project Portal by OrderFlow',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        Text('© ${DateTime.now().year} All Rights Reserved',
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF334155))),
      ],
    ).animate().fadeIn(duration: 1000.ms, delay: 1500.ms);
  }
}
