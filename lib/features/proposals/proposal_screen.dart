import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ProposalScreen extends StatefulWidget {
  const ProposalScreen({super.key});

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  bool _isObscured = true;
  bool _isKeySaved = false;
  String? _savedApiKey;
  bool _isLoading = false;
  String _selectedTone = 'Professional';
  String? _generatedProposal;
  int _proposalCount = 0;
  List<Map<String, String>> _recentProposals = [];
  final List<String> _tones = ['Professional', 'Friendly', 'Confident', 'Brief'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('anthropic_api_key');
    
    // Check for monthly reset
    final lastMonth = prefs.getInt('proposal_count_month') ?? -1;
    final currentMonth = DateTime.now().month;
    if (lastMonth != currentMonth) {
      await prefs.setInt('proposal_count', 0);
      await prefs.setInt('proposal_count_month', currentMonth);
    }

    final count = prefs.getInt('proposal_count') ?? 0;
    final tone = prefs.getString('proposal_tone') ?? 'Professional';
    final recentJson = prefs.getString('recent_proposals');
    List<Map<String, String>> recent = [];
    if (recentJson != null) {
      final List<dynamic> decoded = jsonDecode(recentJson);
      recent = decoded.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return map.map((key, value) => MapEntry(key, value.toString()));
      }).toList();
    }

    setState(() {
      _savedApiKey = apiKey;
      _isKeySaved = apiKey != null && apiKey.isNotEmpty;
      _proposalCount = count;
      _selectedTone = tone;
      _recentProposals = recent;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anthropic_api_key', _apiKeyController.text);
    setState(() {
      _savedApiKey = _apiKeyController.text;
      _isKeySaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  Future<void> _generateProposal() async {
    if (_jobDescriptionController.text.isEmpty) return;
    
    if (_proposalCount >= 5) {
      return; // UI handles this state
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _savedApiKey!,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-3-sonnet-20240229', // Updated to a real stable model name
          'max_tokens': 1024,
          'system': "You are an expert freelancer proposal writer with 10 years experience on Fiverr and Upwork. Write a short, personalized, human-sounding proposal based on the job description provided. Use a $_selectedTone tone. Be confident, specific, and results-focused. Keep it under 200 words. No generic openers like 'I am writing to apply'. Sound like a real human expert.",
          'messages': [
            {'role': 'user', 'content': _jobDescriptionController.text}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String content = data['content'][0]['text'];
        
        setState(() {
          _generatedProposal = content;
          _proposalCount++;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('proposal_count', _proposalCount);
        
        // Save to recent
        final Map<String, String> newProposal = {
          'text': content,
          'date': DateFormat('MMM d, h:mm a').format(DateTime.now()),
        };
        _recentProposals.insert(0, newProposal);
        if (_recentProposals.length > 3) _recentProposals.removeLast();
        await prefs.setString('recent_proposals', jsonEncode(_recentProposals));

      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid API key. Please check and update.'), backgroundColor: Color(0xFFEF4444)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.'), backgroundColor: Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection.'), backgroundColor: Color(0xFFEF4444)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
    );
  }

  void _showKeyDialog() {
    final controller = TextEditingController(text: _savedApiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        title: const Text('API Key Management', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Anthropic API Key',
            labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('anthropic_api_key');
              setState(() {
                _savedApiKey = null;
                _isKeySaved = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('anthropic_api_key', controller.text);
              setState(() {
                _savedApiKey = controller.text;
                _isKeySaved = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isKeySaved) return _buildSetupView();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('AI Proposals', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: _showKeyDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Key: Active', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_proposalCount >= 5) _buildLimitWarning(),
            _buildInputCard(),
            if (_generatedProposal != null) ...[
              const SizedBox(height: 24),
              _buildOutputCard(),
            ],
            const SizedBox(height: 32),
            _buildRecentProposals(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2235),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E2D45)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 48),
                    const SizedBox(height: 24),
                    Text('Setup AI Proposals', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('You need a free Anthropic API key', style: TextStyle(color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _isObscured,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Paste your API key here',
                        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFF0A0F1E),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF4B5563)),
                          onPressed: () => setState(() => _isObscured = !_isObscured),
                        ),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2D45))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                      ),
                      child: ElevatedButton(
                        onPressed: _saveApiKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('https://console.anthropic.com/')),
                      child: const Text('Get your free key at console.anthropic.com', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF78350F).withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCD34D).withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFFCD34D), size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your key is stored only on your device. We never see or store it on any server.',
                        style: TextStyle(color: Color(0xFFFCD34D), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF78350F).withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D).withAlpha(100)),
      ),
      child: Column(
        children: [
          const Text(
            "You've used your 5 free proposals this month.\nUpgrade to Pro for unlimited proposals.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // Disabled for now
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCD34D).withAlpha(50),
                disabledBackgroundColor: const Color(0xFFFCD34D).withAlpha(30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade to Pro', style: TextStyle(color: Color(0xFFFCD34D))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Description', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextField(
            controller: _jobDescriptionController,
            maxLines: 6,
            minLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Paste the client's job post here...",
              hintStyle: const TextStyle(color: Color(0xFF4B5563)),
              filled: true,
              fillColor: const Color(0xFF0A0F1E),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2D45))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tones.map((tone) {
                final isSelected = _selectedTone == tone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (v) async {
                      setState(() => _selectedTone = tone);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('proposal_tone', tone);
                    },
                    backgroundColor: const Color(0xFF0A0F1E),
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFF1E2D45))),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _isLoading || _proposalCount >= 5 ? null : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
              color: _isLoading || _proposalCount >= 5 ? const Color(0xFF1E2D45) : null,
            ),
            child: ElevatedButton(
              onPressed: _isLoading || _proposalCount >= 5 ? null : _generateProposal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(_isLoading ? 'AI is writing...' : 'Generate Proposal', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Proposal', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.2)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF9CA3AF)),
                onPressed: () => _copyToClipboard(_generatedProposal!),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _generatedProposal!,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0A0F1E), borderRadius: BorderRadius.circular(6)),
                child: Text('${_generatedProposal!.split(' ').length} words', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: _isLoading ? null : _generateProposal,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProposals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Proposals', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 16),
        if (_recentProposals.isEmpty)
          const Text('No proposals yet', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14))
        else
          ..._recentProposals.map((p) => _buildRecentItem(p)),
      ],
    );
  }

  Widget _buildRecentItem(Map<String, String> proposal) {
    final preview = proposal['text']!.length > 60 ? '${proposal['text']!.substring(0, 60)}...' : proposal['text']!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 8),
                Text(proposal['date']!, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF4B5563)),
            onPressed: () => _copyToClipboard(proposal['text']!),
          ),
        ],
      ),
    );
  }
}
