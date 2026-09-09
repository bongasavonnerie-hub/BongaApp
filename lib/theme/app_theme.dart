import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique Bonga Savonnerie, extraite du logo.
/// Toutes les couleurs de l'app doivent venir d'ici, jamais écrites
/// en dur ailleurs (ex: Color(0xFF1E4632) copié-collé dans un écran).
class AppColors {
  AppColors._(); // empêche d'instancier cette classe par erreur

  // Verts (identité principale du logo)
  static const Color vertSapin = Color(0xFF1E4632);   // contours, boutons
  static const Color vertSauge = Color(0xFFB7D3A3);   // fond du logo, accents doux
  static const Color vertClairBg = Color(0xFFEAF3DE); // fond de cartes "stock liquide"

  // Fond général de l'app
  static const Color creme = Color(0xFFF4F1E4);
  static const Color blanc = Color(0xFFFFFFFF);

  // Texte
  static const Color navy = Color(0xFF1C3A5A);       // titres, "BONGA"
  static const Color taupe = Color(0xFF7A6248);       // sous-titres, "savonnerie"
  static const Color texteSecondaire = Color(0xFF5F5E5A);

  // Accents ponctuels (issus des fleurs du logo)
  static const Color terracotta = Color(0xFFD9714B);
  static const Color bleuFleur = Color(0xFF3E7CA6);

  // États (alertes de stock, badges de statut...)
  static const Color succes = Color(0xFF3B6D11);
  static const Color succesBg = Color(0xFFEAF3DE);
  static const Color alerte = Color(0xFF854F0B);
  static const Color alerteBg = Color(0xFFFAEEDA);
  static const Color danger = Color(0xFFA32D2D);
  static const Color dangerBg = Color(0xFFFCEBEB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.creme,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.vertSapin,
        primary: AppColors.vertSapin,
        secondary: AppColors.terracotta,
        surface: AppColors.blanc,
      ),

      textTheme: TextTheme(
        // Style "BONGA" du logo : serif épais
        headlineMedium: GoogleFonts.fraunces(
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          fontSize: 22,
        ),
        // Style "savonnerie" du logo : serif italique
        titleMedium: GoogleFonts.lora(
          fontStyle: FontStyle.italic,
          color: AppColors.taupe,
          fontSize: 16,
        ),
        // Corps de texte courant, partout ailleurs dans l'app
        bodyLarge: GoogleFonts.inter(color: AppColors.navy, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: AppColors.texteSecondaire, fontSize: 13),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.creme,
        elevation: 0,
        foregroundColor: AppColors.navy,
        titleTextStyle: GoogleFonts.fraunces(
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          fontSize: 20,
        ),
      ),

      // Style par défaut de TOUTES les Card() de l'app (coins arrondis,
      // pas d'ombre dure — cohérent avec le style "organique" du logo)
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.vertSapin.withOpacity(0.08)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vertSapin,
          foregroundColor: AppColors.blanc,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vertSapin.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vertSapin.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vertSapin, width: 1.5),
        ),
      ),
    );
  }
}