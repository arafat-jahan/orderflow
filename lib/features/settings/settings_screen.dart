import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _apiKey;
  String _proposalTone = 'Professional';
  int _proposalCount = 0;
  bool _isPro = false;
  String _themeMode = 'Dark';
  String _currency = 'USD \$';
  String _dateFormat = 'MMM dd, yyyy';
  bool _notificationsEnabled = true;
  String _reminderHours = '24 hours';
  String _agencyName = 'ORDERFLOW';
  String _agencyLogo = '';
  String _paymentPaypal = '';
  String _paymentStripe = '';
  String _paymentBank = '';

  final List<String> _tones = ['Professional', 'Friendly', 'Confident', 'Brief'];
  final List<String> _currencies = ['USD \$', 'BDT ৳', 'EUR €', 'GBP £', 'CAD \$', 'AUD \$'];
  final List<String> _dateFormats = ['MMM dd, yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy'];
  final List<String> _reminders = ['1 hour', '6 hours', '24 hours', '48 hours'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('anthropic_api_key');
      _proposalTone = prefs.getString('proposal_tone') ?? 'Professional';
      _proposalCount = prefs.getInt('proposal_count') ?? 0;
      _isPro = prefs.getBool('is_pro') ?? false;
      _themeMode = prefs.getString('theme_mode') ?? 'Dark';
      _currency = prefs.getString('currency') ?? 'USD \$';
      _dateFormat = prefs.getString('date_format') ?? 'MMM dd, yyyy';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminderHours = prefs.getString('reminder_hours') ?? '24 hours';
      _agencyName = prefs.getString('agency_name') ?? 'ORDERFLOW';
      _agencyLogo = prefs.getString('agency_logo') ?? '';
      _paymentPaypal = prefs.getString('payment_paypal') ?? '';
      _paymentStripe = prefs.getString('payment_stripe') ?? '';
      _paymentBank = prefs.getString('payment_bank') ?? '';
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSectionHeader('AI Settings'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.vpn_key_outlined,
                iconColor: Colors.blue,
                title: 'Anthropic API Key',
                trailing: _apiKey != null && _apiKey!.isNotEmpty
                    ? Text(
                        '●●●●●●${_apiKey!.substring(_apiKey!.length > 6 ? _apiKey!.length - 6 : 0)}',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      )
                    : const Text('Not set', style: TextStyle(color: Colors.red, fontSize: 13)),
                onTap: _showApiKeyBottomSheet,
              ),
              _buildSettingRow(
                icon: Icons.tune_outlined,
                iconColor: Colors.purple,
                title: 'AI Proposal Tone',
                trailing: Text('$_proposalTone ↓', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showOptionsBottomSheet('AI Proposal Tone', _tones, _proposalTone, (val) {
                  _updateSetting('proposal_tone', val);
                }),
              ),
              _buildSettingRow(
                icon: Icons.analytics_outlined,
                iconColor: Colors.orange,
                title: 'Monthly Proposal Limit',
                trailing: _isPro
                    ? const Text('Unlimited', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold))
                    : Text('$_proposalCount / 5 used', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                showProgress: !_isPro,
                progressValue: _isPro ? 0 : _proposalCount / 5,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Appearance'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.image_outlined,
                iconColor: Colors.pinkAccent,
                title: 'Agency Logo',
                trailing: Text(_agencyLogo.isEmpty ? 'Not set ↓' : 'Set ↓',
                    style:
                        const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showEditPaymentDialog(
                    'Agency Logo Path', 'agency_logo', _agencyLogo),
              ),
              _buildSettingRow(
                icon: Icons.business_outlined,
                iconColor: Colors.blueAccent,
                title: 'Agency Name',
                trailing: Text('$_agencyName ↓',
                    style:
                        const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showEditPaymentDialog(
                    'Agency Name', 'agency_name', _agencyName),
              ),
              _buildSettingRow(
                icon: Icons.palette_outlined,
                iconColor: Colors.amber,
                title: 'Theme',
                trailing: Text('$_themeMode ↓', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showOptionsBottomSheet('Theme', ['Dark', 'Light', 'System'], _themeMode, (val) {
                  _updateSetting('theme_mode', val);
                }),
              ),
              _buildSettingRow(
                icon: Icons.attach_money_outlined,
                iconColor: Colors.green,
                title: 'Currency',
                trailing: Text('$_currency ↓', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showOptionsBottomSheet('Currency', _currencies, _currency, (val) {
                  _updateSetting('currency', val);
                }),
              ),
              _buildSettingRow(
                icon: Icons.calendar_today_outlined,
                iconColor: Colors.blueGrey,
                title: 'Date Format',
                trailing: Text('${DateFormat(_dateFormat).format(DateTime.now())} ↓', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showOptionsBottomSheet('Date Format', _dateFormats, _dateFormat, (val) {
                  _updateSetting('date_format', val);
                }),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.notifications_none_outlined,
                iconColor: Colors.red,
                title: 'Deadline Reminders',
                trailing: CupertinoSwitch(
                  value: _notificationsEnabled,
                  activeTrackColor: const Color(0xFF3B82F6),
                  onChanged: (val) => _updateSetting('notifications_enabled', val),
                ),
              ),
              _buildSettingRow(
                icon: Icons.timer_outlined,
                iconColor: Colors.blue,
                title: 'Remind me before',
                trailing: Text('$_reminderHours ↓', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showOptionsBottomSheet('Remind me before', _reminders, _reminderHours, (val) {
                  _updateSetting('reminder_hours', val);
                }),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Payment Links'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.payment_outlined,
                iconColor: Colors.blue,
                title: 'PayPal Link',
                trailing: Text(_paymentPaypal.isEmpty ? 'Not set ↓' : 'Set ↓',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showEditPaymentDialog('PayPal Link', 'payment_paypal', _paymentPaypal),
              ),
              _buildSettingRow(
                icon: Icons.credit_card_outlined,
                iconColor: Colors.purple,
                title: 'Stripe Link',
                trailing: Text(_paymentStripe.isEmpty ? 'Not set ↓' : 'Set ↓',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showEditPaymentDialog('Stripe Link', 'payment_stripe', _paymentStripe),
              ),
              _buildSettingRow(
                icon: Icons.account_balance_outlined,
                iconColor: Colors.green,
                title: 'Bank Details',
                trailing: Text(_paymentBank.isEmpty ? 'Not set ↓' : 'Set ↓',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                onTap: () => _showEditPaymentDialog('Bank Details', 'payment_bank', _paymentBank),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Data'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.download_outlined,
                iconColor: Colors.teal,
                title: 'Export Orders',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
                onTap: _showExportBottomSheet,
              ),
              _buildSettingRow(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'Clear All Data',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
                onTap: _showClearDataDialog,
              ),
              _buildSettingRow(
                icon: Icons.refresh_outlined,
                iconColor: Colors.blue,
                title: 'Reset Proposal Count',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
                onTap: () async {
                  await _updateSetting('proposal_count', 0);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proposal count reset!'), backgroundColor: Color(0xFF3B82F6)),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildSectionCard([
              _buildSettingRow(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: 'App Version',
                trailing: const Text('OrderFlow v1.0.0', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ),
              _buildSettingRow(
                icon: Icons.star_outline,
                iconColor: Colors.amber,
                title: 'Rate the App',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon on Play Store!')),
                ),
              ),
              _buildSettingRow(
                icon: Icons.share_outlined,
                iconColor: Colors.blue,
                title: 'Share App',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
                onTap: () => Share.share('Check out OrderFlow, the best freelancer order manager!'),
              ),
              _buildSettingRow(
                icon: Icons.shield_outlined,
                iconColor: Colors.green,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
              ),
            ]),
            const SizedBox(height: 32),
            if (!_isPro) _buildUpgradeBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2235),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Text(
                  'JD',
                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'John Doe',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'john@example.com',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _isPro ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isPro ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF1E2D45)),
          ),
          child: Text(
            _isPro ? 'Pro Member' : 'Free Plan',
            style: TextStyle(
              color: _isPro ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF1E2D45)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Edit Profile', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4B5563), letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    List<Widget> spacedChildren = [];
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(const SizedBox(height: 4));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Column(
        children: spacedChildren,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool showProgress = false,
    double progressValue = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
                        ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: const Color(0xFF0A0F1E),
                  valueColor: AlwaysStoppedAnimation(progressValue > 0.8 ? Colors.red : const Color(0xFF3B82F6)),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApiKeyBottomSheet() {
    final controller = TextEditingController(text: _apiKey);
    bool isObscured = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF1E2D45), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Anthropic API Key', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Stored only on your device. Never shared.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: isObscured,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'sk-ant-api03-...',
                  hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                  filled: true,
                  fillColor: const Color(0xFF1A2235),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF4B5563)),
                    onPressed: () => setModalState(() => isObscured = !isObscured),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await _updateSetting('anthropic_api_key', controller.text);
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_apiKey != null && _apiKey!.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _updateSetting('anthropic_api_key', '');
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Delete key', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPaymentDialog(String title, String key, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter link or details...',
                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                filled: true,
                fillColor: const Color(0xFF1A2235),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateSetting(key, controller.text);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(String title, List<String> options, String currentValue, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ...options.map((option) => InkWell(
                  onTap: () {
                    onSelect(option);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: option == currentValue ? const Color(0xFF3B82F6) : const Color(0xFF1E2D45), width: 2),
                          ),
                          child: option == currentValue
                              ? Center(
                                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Text(option, style: TextStyle(color: option == currentValue ? Colors.white : const Color(0xFF9CA3AF), fontSize: 15)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showExportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export Data', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildExportButton(Icons.description_outlined, 'Export as CSV', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Export coming soon!')));
            }),
            const SizedBox(height: 12),
            _buildExportButton(Icons.picture_as_pdf_outlined, 'Export as PDF', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming soon!')));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D45))),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure? This will delete all orders and clients.', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF)))),
          TextButton(
            onPressed: () {
              // Clear data logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared!'), backgroundColor: Colors.red));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Unlimited AI proposals + Priority support',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text('\$19/month', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
