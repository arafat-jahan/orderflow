import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orderflow/features/orders/orders_screen.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF111827),
          onSurface: Color(0xFFF9FAFB),
          outline: Color(0xFF1E2D45),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFF9FAFB)),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFF9FAFB)),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFF9FAFB)),
          titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFF9FAFB)),
          bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFFF9FAFB)),
          bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFF9CA3AF)),
          bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, color: const Color(0xFF4B5563)),
          labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFFF9FAFB)),
          labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF)),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF4B5563)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2235),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E2D45), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1E),
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF111827),
          selectedItemColor: Color(0xFF3B82F6),
          unselectedItemColor: Color(0xFF4B5563),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
      home: const OrdersScreen(),
    );
  }
}
