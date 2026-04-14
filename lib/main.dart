import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orderflow/core/models/order.dart';
import 'package:orderflow/core/models/client_profile.dart';
import 'package:orderflow/core/models/invoice.dart';
import 'package:orderflow/features/orders/orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    // For Desktop/Mobile, use a specific path for robustness
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  }
  
  // Register Adapters - Leaf types first
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(PlatformAdapter());
  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(ClientProfileAdapter());
  Hive.registerAdapter(InvoiceStatusAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  
  // Open Boxes
  await Hive.openBox<Order>('orders');
  await Hive.openBox('settings');
  await Hive.openBox('proposals');
  await Hive.openBox<ClientProfile>('client_profiles');
  await Hive.openBox<Invoice>('invoices');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF030712), // Deeper background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF6366F1),
          surface: Color(0xFF0F172A),
          onSurface: Color(0xFFF9FAFB),
          outline: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFF9FAFB)),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFFF9FAFB)),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFF9FAFB)),
          bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFFF9FAFB)),
          bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8)),
          bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
          labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFFF9FAFB)),
          labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827).withAlpha(150), // Semi-transparent for glassmorphism
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withAlpha(20), width: 1), // Semi-transparent border
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Floating feel
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF030712),
          selectedItemColor: Color(0xFF3B82F6),
          unselectedItemColor: Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
      home: const OrdersScreen(),
    );
  }
}
